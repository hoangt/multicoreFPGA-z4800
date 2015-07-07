#include "yatse.h"
#ifdef CONFIG_MACH_Z48SOC
#include <asm/irq_cpu.h>
#endif

irqreturn_t yatse_tx_isr(int irq, void *dev_id, struct pt_regs *pt_regs){
	struct net_device *ndev = dev_id;
	struct yatse_private *priv = netdev_priv(ndev);
	struct yatse_dma *dma = &priv->dma;
	unsigned long flags;
	bool got_irq;

	//printk(KERN_INFO "yatse_tx_isr: TX IRQ\n");

	if(unlikely(!netif_running(ndev))){
		printk(KERN_ERR "yatse_tx_isr: late interrupt\n");
	}

	spin_lock_irqsave(&dma->tx_lock, flags);
	got_irq = !!(readl(&dma->csr->tcontrol) & YATSE_CSR_TCONTROL_TXIS);
	if(got_irq){
		writel(readl(&dma->csr->tcontrol) & ~YATSE_CSR_TCONTROL_TXIE, &dma->csr->tcontrol);
	}
	spin_unlock_irqrestore(&dma->tx_lock, flags);

	if(got_irq) tasklet_schedule(&priv->tx_tasklet);

	return got_irq ? IRQ_HANDLED : IRQ_NONE;
}

void yatse_tx_complete(unsigned long ndevl){
	struct net_device *ndev = (struct net_device *)ndevl;
	struct yatse_private *priv = netdev_priv(ndev);
	struct yatse_dma *dma = &priv->dma;
	struct sk_buff *skb;
	dma_addr_t phys;
	unsigned long flags;
	int completed = 0;
	yatse_dma_desc *desc;

	BUG_ON(dma->tx_queued < 0);

	spin_lock_irqsave(&dma->tx_lock, flags);

	while(dma->tx_queued > 0){
		desc = &dma->tx[dma->tx_remove];
		if(readb(&desc->status) & YATSE_DESC_STATUS_HW) break;

		writel(0, &dma->csr->tx); /* ack TX interrupt */

		skb = dma->tx_skbs[dma->tx_remove];
		phys = dma->tx_skb_phys[dma->tx_remove];

		dma->tx_remove = YATSE_RING_NEXT(dma->tx_remove, dma->tx_ring_mask);
		dma->tx_queued--;
		completed++;

		spin_unlock_irqrestore(&dma->tx_lock, flags);

		dma_unmap_single(&ndev->dev, phys, skb->len, DMA_TO_DEVICE);
		dev_kfree_skb(skb);

		spin_lock_irqsave(&dma->tx_lock, flags);
	}

	writel(readl(&dma->csr->tcontrol) | YATSE_CSR_TCONTROL_TXIE, &dma->csr->tcontrol);
	spin_unlock_irqrestore(&dma->tx_lock, flags);

	netif_wake_queue(ndev);
	//printk(KERN_INFO "yatse_tx_complete(): %d packets\n", completed);
}

static dma_addr_t yatse_tx_sync_skb(struct net_device *ndev, struct yatse_dma *dma, struct sk_buff *skb){
	dma_addr_t phys;

	phys = dma_map_single(&ndev->dev, skb->data, skb->len, DMA_TO_DEVICE);
	BUG_ON(dma_mapping_error(&ndev->dev, phys));
	dma_sync_single_for_device(&ndev->dev, phys, skb->len, DMA_TO_DEVICE);

	return phys;
}

int yatse_start_xmit(struct sk_buff *skb, struct net_device *ndev){
	struct yatse_private *priv = netdev_priv(ndev);
	struct yatse_dma *dma = &priv->dma;
	unsigned long flags;
	dma_addr_t phys;
	yatse_dma_desc *desc;

	phys = yatse_tx_sync_skb(ndev, dma, skb);

	spin_lock_irqsave(&dma->tx_lock, flags);
	//printk(KERN_INFO "yatse_start_xmit: tx_queued=%d, tx_insert=%d, tx_remove=%d\n", dma->tx_queued, dma->tx_insert, dma->tx_remove);
	BUG_ON(dma->tx_queued < 0);
	BUG_ON(dma->tx_queued > dma->tx_ring_length);
	desc = &dma->tx[dma->tx_insert];
	if(readb(&desc->status) & YATSE_DESC_STATUS_HW){
		printk(KERN_INFO "yatse_start_xmit: TX descriptor busy\n");
		netif_stop_queue(ndev);
		spin_unlock_irqrestore(&dma->tx_lock, flags);
		return NETDEV_TX_BUSY;
	}
	if(dma->tx_queued == dma->tx_ring_length){
		printk(KERN_INFO "yatse_start_xmit: TX ring full\n");
		netif_stop_queue(ndev);
		spin_unlock_irqrestore(&dma->tx_lock, flags);
		return NETDEV_TX_BUSY;
	}
	dma->tx_skbs[dma->tx_insert] = skb;
	dma->tx_skb_phys[dma->tx_insert] = phys;

	//printk(KERN_INFO "yatse_start_xmit: phys=%08x len=%04x\n", phys, skb->len);
	//yatse_dump_skb(skb);
	
	writel(phys, &desc->addr);
	writew(skb->len, &desc->len);
	writeb(YATSE_DESC_STATUS_HW, &desc->status);

	dma->tx_insert = YATSE_RING_NEXT(dma->tx_insert, dma->tx_ring_mask);
	if(++dma->tx_queued == dma->tx_ring_length) netif_stop_queue(ndev);
	ndev->trans_start = jiffies;
	spin_unlock_irqrestore(&dma->tx_lock, flags);


	//printk(KERN_INFO "yatse_start_xmit: DMA running\n");

	return NETDEV_TX_OK;
}

void yatse_tx_timeout(struct net_device *ndev){
	struct yatse_private *priv = netdev_priv(ndev);
	unsigned long flags;
	struct yatse_dma *dma = &priv->dma;

	spin_lock_irqsave(&dma->tx_lock, flags);

	printk(KERN_INFO "yatse_tx_timeout: tx_queued=%d tx_insert=%d tx_remove=%d\n", dma->tx_queued, dma->tx_insert, dma->tx_remove);
	printk(KERN_INFO "yatse_tx_timeout: rcontrol=%08x tcontrol=%08x\n", dma->csr->rcontrol, dma->csr->tcontrol);

	/* HAAAAAAAAAAAAAAX! */
#ifdef CONFIG_MACH_Z48SOC
	printk(KERN_INFO "cpu=%d c0_cause=%08x c0_status=%08x\n", smp_processor_id(), read_c0_cause(), read_c0_status());
#endif

	spin_unlock_irqrestore(&dma->tx_lock, flags);

	tasklet_schedule(&priv->tx_tasklet);
}
