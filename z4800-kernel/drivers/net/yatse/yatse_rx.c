#include "yatse.h"

#if 0
void yatse_dump_skb(struct sk_buff *skb){
	int i;
	printk(KERN_INFO "yatse: SKB dump, length=%d\n", skb->len);
	printk(KERN_INFO);
	for(i = 0;i < skb->len;i++){
		printk("%02x ", skb->data[i]);
	}
	printk("\n");
}
#endif

struct sk_buff *yatse_rx_alloc_skb(struct net_device *ndev){
	struct yatse_private *priv = netdev_priv(ndev);
	struct yatse_dma *dma = &priv->dma;
	struct sk_buff *skb;
	unsigned long offset;

	skb = netdev_alloc_skb(ndev, dma->rx_buf_len);
	if(!skb) return NULL;

	if(dma->rx_align == 0) offset = 0;
	else{
		offset = (unsigned long)skb->tail;
		offset += ((unsigned long)dma->rx_align - 1UL);
		offset &= ~((unsigned long)dma->rx_align - 1UL);
		offset -= (unsigned long)skb->tail;
	}

	//printk(KERN_INFO "yatse_rx_alloc_skb: old skb->data=%p\n", skb->data);
	skb_reserve(skb, NET_IP_ALIGN + offset);
	//printk(KERN_INFO "yatse_rx_alloc_skb: new skb->data=%p\n", skb->data);
	return skb;
}

irqreturn_t yatse_rx_isr(int irq, void *dev_id, struct pt_regs *pt_regs){
	struct net_device *ndev = dev_id;
	struct yatse_private *priv = netdev_priv(ndev);
	struct yatse_dma *dma = &priv->dma;
	unsigned long flags;
	bool got_irq;

	//printk(KERN_INFO "yatse_rx_isr: RX IRQ\n");

	if(unlikely(!netif_running(ndev))){
		printk(KERN_ERR "yatse_rx_isr: late interrupt\n");
	}

	spin_lock_irqsave(&dma->rx_lock, flags);
	got_irq = !!(readl(&dma->csr->rcontrol) & YATSE_CSR_RCONTROL_RXIS);
	if(got_irq && napi_schedule_prep(&priv->napi)){
		writel(readl(&dma->csr->rcontrol) & ~YATSE_CSR_RCONTROL_RXIE, &dma->csr->rcontrol);
		__napi_schedule(&priv->napi);
	}
	spin_unlock_irqrestore(&dma->rx_lock, flags);

	return got_irq ? IRQ_HANDLED : IRQ_NONE;
}

void yatse_rx_insert_skb(struct net_device *ndev, struct yatse_dma *dma, dma_addr_t phys){
	struct yatse_private *priv = netdev_priv(ndev);
	yatse_dma_desc *desc = &dma->rx[dma->rx_pos];

	writel(phys, &desc->addr);
	writew(NET_IP_ALIGN + ETH_HLEN + priv->mtu, &desc->len);
	writeb(0, &desc->error);
	writeb(YATSE_DESC_STATUS_HW, &desc->status);
}

int yatse_rx_poll(struct napi_struct *napi, int budget){
	struct yatse_private *priv = container_of(napi, struct yatse_private, napi);
	struct net_device *ndev = priv->ndev;
	unsigned long flags;
	struct yatse_dma *dma = &priv->dma;
	struct sk_buff *old_skb, *new_skb;
	dma_addr_t old_phys, new_phys;
	yatse_dma_desc *desc;
	int received = 0;
	int len;
	char error;

	BUG_ON(budget <= 0);

	//printk(KERN_INFO "yatse_rx_poll: started\n");

	spin_lock_irqsave(&dma->rx_lock, flags);
	while(budget > 0){
		desc = &dma->rx[dma->rx_pos];
		//printk(KERN_INFO "yatse_rx_poll(): rx_pos %d, &status=%p, status=%02x\n", dma->rx_pos, &desc->status, readb(&desc->status));
		if(readb(&desc->status) & YATSE_DESC_STATUS_HW){
			__napi_complete(napi);
			writel(readl(&dma->csr->rcontrol) | YATSE_CSR_RCONTROL_RXIE, &dma->csr->rcontrol);
			break;
		}

		writel(0, &dma->csr->rx); /* ack RX interrupt */
		
		old_skb = dma->rx_skbs[dma->rx_pos];
		old_phys = dma->rx_skb_phys[dma->rx_pos];

		if((error = readb(&desc->error))){
			printk(KERN_ERR "yatse_rx_poll(): error %02x on packet %d\n", error, dma->rx_pos);
			yatse_rx_insert_skb(ndev, dma, old_phys);
			dma->rx_pos = YATSE_RING_NEXT(dma->rx_pos, dma->rx_ring_mask);
			continue;
		}

		len = readw(&desc->len) - NET_IP_ALIGN;
		if(len > (ETH_HLEN + priv->mtu)){
			printk(KERN_ERR "yatse_rx_poll: DMA overrun, %d bytes\n", len);
			yatse_rx_insert_skb(ndev, dma, old_phys);
			dma->rx_pos = YATSE_RING_NEXT(dma->rx_pos, dma->rx_ring_mask);
			continue;
		}

		new_skb = yatse_rx_alloc_skb(ndev);
		if(!new_skb){
			printk(KERN_ERR "yatse_rx_poll: skb allocation failed, recycling skb\n");
			yatse_rx_insert_skb(ndev, dma, old_phys);
			dma->rx_pos = YATSE_RING_NEXT(dma->rx_pos, dma->rx_ring_mask);
			continue;
		}
		new_phys = dma_map_single(&ndev->dev, new_skb->data - NET_IP_ALIGN, NET_IP_ALIGN + ETH_HLEN + priv->mtu, DMA_FROM_DEVICE);
		BUG_ON(dma_mapping_error(&ndev->dev, new_phys));

		/* push a new skb to hardware */
		yatse_rx_insert_skb(ndev, dma, new_phys);
		dma->rx_skbs[dma->rx_pos] = new_skb;
		dma->rx_skb_phys[dma->rx_pos] = new_phys;
		dma->rx_pos = YATSE_RING_NEXT(dma->rx_pos, dma->rx_ring_mask);
		spin_unlock_irqrestore(&dma->rx_lock, flags);

		/* grab received skb */
		//printk(KERN_INFO "yatse_rx_poll: packet of length %d\n", len);
		dma_sync_single_for_cpu(&ndev->dev, old_phys, len, DMA_FROM_DEVICE);
		dma_unmap_single(&ndev->dev, old_phys, dma->rx_buf_len, DMA_FROM_DEVICE);
		skb_put(old_skb, len);
		old_skb->protocol = eth_type_trans(old_skb, ndev);
		//yatse_dump_skb(old_skb);
		netif_receive_skb(old_skb);
		budget--;
		received++;
		spin_lock_irqsave(&dma->rx_lock, flags);
	}
	spin_unlock_irqrestore(&dma->rx_lock, flags);

	//printk(KERN_INFO "yatse_rx_poll: ended, %d received, %d budget\n", received, budget);
	return received;
}
