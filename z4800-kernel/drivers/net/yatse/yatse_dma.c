#include <linux/delay.h>

#include "yatse.h"

static int yatse_dma_reset(struct yatse_dma *dma){
	int tries;

	assert_spin_locked(&dma->rx_lock);
	assert_spin_locked(&dma->tx_lock);
	
	writel(YATSE_CSR_RCONTROL_RXRST, &dma->csr->rcontrol);
	writel(YATSE_CSR_TCONTROL_TXRST, &dma->csr->tcontrol);
	tries = 100;
	while((readl(&dma->csr->rcontrol) & YATSE_CSR_RCONTROL_RXRST) || (readl(&dma->csr->tcontrol) & YATSE_CSR_TCONTROL_TXRST)){
		ndelay(100);
		if(--tries == 0){
			printk(KERN_ERR "yatse_dma_reset: reset failed\n");
			return -EAGAIN;
		}
	}

	return 0;
}

void yatse_dma_stop(struct yatse_dma *dma){
	assert_spin_locked(&dma->rx_lock);
	assert_spin_locked(&dma->tx_lock);

	yatse_dma_reset(dma);
}

int yatse_dma_init(struct net_device *ndev){
	struct yatse_private *priv = netdev_priv(ndev);
	struct yatse_dma *dma = &priv->dma;
	int ret = 0;
	int i;

	assert_spin_locked(&dma->rx_lock);
	assert_spin_locked(&dma->tx_lock);

	dma->rx_skbs = NULL;
	dma->rx_skb_phys = NULL;
	dma->tx_skbs = NULL;
	dma->tx_skb_phys = NULL;

	ret = yatse_dma_reset(dma);
	if(ret) goto out;

	dma->rx_buf_len = priv->config->rx_align + NET_IP_ALIGN + ETH_HLEN + priv->config->max_mtu;
	dma->rx_align = priv->config->rx_align;
	BUG_ON(dma->rx_ring_length & dma->rx_ring_mask);

	BUG_ON(dma->tx_ring_length & dma->tx_ring_mask);
	dma->tx_insert = 0;
	dma->tx_remove = 0;

	dma->rx_skbs = kzalloc(sizeof(*dma->rx_skbs) * dma->rx_ring_length, GFP_KERNEL);
	if(!dma->rx_skbs){
		ret = -ENOMEM;
		goto out;
	}
	dma->rx_skb_phys = kzalloc(sizeof(*dma->rx_skb_phys) * dma->rx_ring_length, GFP_KERNEL);
	if(!dma->rx_skb_phys){
		ret = -ENOMEM;
		goto out;
	}
	for(i = 0;i < dma->rx_ring_length;i++){
		dma->rx_pos = i;
		dma->rx_skbs[i] = yatse_rx_alloc_skb(ndev);
		if(!dma->rx_skbs[i]){
			ret = -ENOMEM;
			goto out;
		}

		dma->rx_skb_phys[i] = dma_map_single(&ndev->dev, dma->rx_skbs[i]->data - NET_IP_ALIGN, NET_IP_ALIGN + ETH_HLEN + priv->mtu, DMA_FROM_DEVICE);
		BUG_ON(dma_mapping_error(&ndev->dev, dma->rx_skb_phys[i]));

		yatse_rx_insert_skb(ndev, dma, dma->rx_skb_phys[i]);
	}
	dma->rx_pos = 0;

	dma->tx_skbs = kzalloc(sizeof(*dma->tx_skbs) * dma->tx_ring_length, GFP_KERNEL);
	if(!dma->tx_skbs){
		ret = -ENOMEM;
		goto out;
	}
	dma->tx_skb_phys = kzalloc(sizeof(*dma->tx_skb_phys) * dma->tx_ring_length, GFP_KERNEL);
	if(!dma->tx_skb_phys){
		ret = -ENOMEM;
		goto out;
	}
	for(i = 0;i < dma->tx_ring_length;i++){
		writeb(0, &dma->tx[i].status);
	}

	writel(YATSE_CSR_RCONTROL_RXENA | YATSE_CSR_RCONTROL_RXIE, &dma->csr->rcontrol);
	writel(YATSE_CSR_TCONTROL_TXENA | YATSE_CSR_TCONTROL_TXIE, &dma->csr->tcontrol);

	printk(KERN_INFO "yatse: DMA up\n");

	return 0;

out:
	yatse_dma_free(ndev);
	return ret;
}

void yatse_dma_free(struct net_device *ndev){
	struct yatse_private *priv = netdev_priv(ndev);
	struct yatse_dma *dma = &priv->dma;
	int i;

	assert_spin_locked(&dma->rx_lock);
	assert_spin_locked(&dma->tx_lock);

	if(dma->rx_skbs){
		for(i = 0;i < dma->rx_ring_length;i++){
			if(dma->rx_skbs[i]){
				dma_unmap_single(&ndev->dev, dma->rx_skb_phys[i], dma->rx_buf_len, DMA_FROM_DEVICE);
				dev_kfree_skb(dma->rx_skbs[i]);
			}
		}
		kfree(dma->rx_skb_phys);
		kfree(dma->rx_skbs);
	}

	if(dma->tx_skbs){
		for(i = 0;i < dma->tx_ring_length;i++){
			if(dma->tx_skbs[i]){
				dma_unmap_single(&ndev->dev, dma->tx_skb_phys[i], dma->tx_skbs[i]->len + NET_IP_ALIGN, DMA_TO_DEVICE);
				dev_kfree_skb(dma->tx_skbs[i]);
			}
		}
		kfree(dma->tx_skb_phys);
		kfree(dma->tx_skbs);
	}
}
