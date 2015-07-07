#include <linux/init.h>
#include <linux/module.h>
MODULE_LICENSE("GPL");

#include <linux/delay.h>

#include <linux/pm.h>
#include <linux/platform_device.h>

#include <linux/mii.h>

#include <linux/netdevice.h>
#include <linux/etherdevice.h>
#include <linux/skbuff.h>
#include <linux/ioport.h>
#include <linux/interrupt.h>

#include <asm/cacheflush.h>

#include "yatse.h"

static void yatse_adjust_link(struct net_device *ndev){
	struct yatse_private *priv = netdev_priv(ndev);
	unsigned long flags;
	bool link_changed;

	spin_lock_irqsave(&priv->mac_lock, flags);
	link_changed = (priv->link != priv->phydev->link);
	if((priv->link = priv->phydev->link)){
		if(link_changed || (priv->duplex != priv->phydev->duplex) || (priv->speed != priv->phydev->speed)){
			printk(KERN_INFO "yatse: link up");
			if((priv->duplex = priv->phydev->duplex)){
				priv->mac->command_config &= ~YATSE_MAC_CMDCFG_HD_ENA;
				printk(", full-duplex");
			}
			else{
				priv->mac->command_config |= YATSE_MAC_CMDCFG_HD_ENA;
				printk(", half-duplex");
			}
			switch((priv->speed = priv->phydev->speed)){
				case 1000:
					priv->mac->command_config = (priv->mac->command_config & ~YATSE_MAC_CMDCFG_ENA_10) | YATSE_MAC_CMDCFG_ETH_SPEED;
					printk(", 1Gbps");
					break;
				case 100:
					priv->mac->command_config &= ~(YATSE_MAC_CMDCFG_ENA_10 | YATSE_MAC_CMDCFG_ETH_SPEED);
					printk(", 100Mbps");
					break;
				case 10:
					priv->mac->command_config = (priv->mac->command_config & ~YATSE_MAC_CMDCFG_ETH_SPEED) | YATSE_MAC_CMDCFG_ENA_10;
					printk(", 10Mbps");
					break;
				default:
					printk(", unknown speed");
					break;
			}
			printk(".\n");
			netif_carrier_on(ndev);
		}
	}
	else{
		if(link_changed){
			printk(KERN_INFO "yatse: link down.\n");
			netif_carrier_off(ndev);
		}
	}

	//phy_print_status(priv->phydev);

#if 0
	printk(KERN_INFO "aFramesTransmittedOK=%08x\n", priv->mac->aFramesTransmittedOK);
	printk(KERN_INFO "aFramesReceivedOK=%08x\n", priv->mac->aFramesReceivedOK);
	printk(KERN_INFO "aFramesCheckSequenceErrors=%08x\n", priv->mac->aFramesCheckSequenceErrors);
	printk(KERN_INFO "aAlignmentErrors=%08x\n", priv->mac->aAlignmentErrors);
	printk(KERN_INFO "aOctetsTransmittedOK=%08x\n", priv->mac->aOctetsTransmittedOK);
	printk(KERN_INFO "aOctetsReceivedOK=%08x\n", priv->mac->aOctetsReceivedOK);
	printk(KERN_INFO "ifInErrors=%08x\n", priv->mac->ifInErrors);
	printk(KERN_INFO "ifOutErrors=%08x\n", priv->mac->ifOutErrors);
	printk(KERN_INFO "etherStatsDropEvent=%08x\n", priv->mac->etherStatsDropEvent);
	printk(KERN_INFO "etherStatsOctets=%08x\n", priv->mac->etherStatsOctets);
	printk(KERN_INFO "etherStatsPkts=%08x\n", priv->mac->etherStatsPkts);
	printk(KERN_INFO "etherStatsUndersizePkts=%08x\n", priv->mac->etherStatsUndersizePkts);
	printk(KERN_INFO "etherStatsOversizePkts=%08x\n", priv->mac->etherStatsOversizePkts);
	printk(KERN_INFO "etherStatsJabbers=%08x\n", priv->mac->etherStatsJabbers);
	printk(KERN_INFO "etherStatsFragments=%08x\n", priv->mac->etherStatsFragments);
	printk(KERN_INFO "command_config=%08x\n", priv->mac->command_config);
#endif
	spin_unlock_irqrestore(&priv->mac_lock, flags);
}

static int yatse_init_phy(struct net_device *ndev){
	struct yatse_private *priv = netdev_priv(ndev);
	char phy_id[MII_BUS_ID_SIZE];
	char mii_id[MII_BUS_ID_SIZE];

	snprintf(mii_id, MII_BUS_ID_SIZE, "%x", priv->config->mii_id);
	snprintf(phy_id, MII_BUS_ID_SIZE, PHY_ID_FMT, mii_id, priv->phy_addr);

	priv->phydev = phy_connect(ndev, phy_id, &yatse_adjust_link, 0, priv->config->interface);
	if(IS_ERR(priv->phydev)){
		printk(KERN_ERR "%s:%d: phy_connect() failed\n", __FILE__, __LINE__);
		return PTR_ERR(priv->phydev);
	}

	priv->phydev->supported &= priv->config->supported_modes;
	priv->phydev->advertising = priv->phydev->supported;

	return 0;
}

static int yatse_init_mac(struct net_device *ndev){
	struct yatse_private *priv = netdev_priv(ndev);
	int i;

	printk(KERN_INFO "yatse: resetting MAC...\n");

	printk(KERN_INFO "yatse: priv->mac is %p, &priv->mac->command_config is %p\n", priv->mac, &priv->mac->command_config);

	priv->mac->command_config = YATSE_MAC_CMDCFG_SW_RESET;

	i = 0;
	while(i < 10000){
		ndelay(1000);
		if(!(priv->mac->command_config & YATSE_MAC_CMDCFG_SW_RESET)) break;
		i++;
	}
	if(i == 10000){
		printk(KERN_ERR "%s:%d: software reset failed\n", __FILE__, __LINE__);
		printk(KERN_ERR "%s:%d: command_config is %08x\n", __FILE__, __LINE__, priv->mac->command_config);
		printk(KERN_ERR "%s:%d: *** check that your RX/TX clocks are toggling! ***\n", __FILE__, __LINE__);
		return -EAGAIN;
	}

	printk(KERN_INFO "yatse: MAC reset, %d tries\n", i);

	priv->mac->max_frame_length = priv->mtu + ETH_HLEN + 4;
	printk(KERN_INFO "yatse: HW max_frame_length = %d\n", priv->mac->max_frame_length);
	priv->mac->rx_almost_empty_threshold = 8;
	priv->mac->rx_almost_full_threshold = 8;
	priv->mac->tx_almost_empty_threshold = 8;
	priv->mac->tx_almost_full_threshold = 3;
	priv->mac->rx_sel_empty_threshold = priv->config->fifo_depth - 16;
	priv->mac->rx_sel_full_threshold = 0; /* RX store-and-forward */
	priv->mac->tx_sel_empty_threshold = priv->config->fifo_depth - 16;
	priv->mac->tx_sel_full_threshold = 0; /* TX store-and-forward */
	priv->mac->min_tx_ipg_length = 12;

	if(priv->mac->tx_sel_full_threshold != 0){
		printk(KERN_ERR "yatse: MAC does not support TX store-and-forward\n");
		return -EIO;
	}

	priv->mac->rx_cmd_stat = 0;
	priv->mac->tx_cmd_stat = 0;

	switch(NET_IP_ALIGN){
		case 0:
			priv->mac->rx_cmd_stat &= YATSE_MAC_RXCMDSTAT_RX_SHIFT16;
			//priv->mac->tx_cmd_stat &= YATSE_MAC_TXCMDSTAT_TX_SHIFT16;
			break;
		case 2:
			priv->mac->rx_cmd_stat |= YATSE_MAC_RXCMDSTAT_RX_SHIFT16;
			//priv->mac->tx_cmd_stat |= YATSE_MAC_TXCMDSTAT_TX_SHIFT16;
			if(!(priv->mac->rx_cmd_stat & YATSE_MAC_RXCMDSTAT_RX_SHIFT16)){
				printk(KERN_ERR "yatse: MAC does not support rx_shift16\n");
				return -EIO;
			}
			/*
			if(!(priv->mac->tx_cmd_stat & YATSE_MAC_TXCMDSTAT_TX_SHIFT16)){
				printk(KERN_ERR "yatse: MAC does not support tx_shift16\n");
				return -EIO;
			}
			*/
			break;
		default:
			printk(KERN_ERR "yatse: cannot support NET_IP_ALIGN=%d\n", NET_IP_ALIGN);
			return -EIO;
	}

	printk(KERN_INFO "yatse: rx_cmd_stat = %08x, tx_cmd_stat = %08x\n", priv->mac->rx_cmd_stat, priv->mac->tx_cmd_stat);

	priv->mac->pause_quanta = 10; // FIXME

	// FIXME
	priv->mac->mac_addr_0 =
		(priv->config->ethaddr[3] << 24) |
		(priv->config->ethaddr[2] << 16) |
		(priv->config->ethaddr[1] <<  8) |
		(priv->config->ethaddr[0] <<  0);
	priv->mac->mac_addr_1 =
		(priv->config->ethaddr[5] <<  8) |
		(priv->config->ethaddr[4] <<  0);

	priv->mac->supp_mac_addr_0_0 = priv->mac->mac_addr_0;
	priv->mac->supp_mac_addr_0_1 = priv->mac->mac_addr_1;
	priv->mac->supp_mac_addr_1_0 = priv->mac->mac_addr_0;
	priv->mac->supp_mac_addr_1_1 = priv->mac->mac_addr_1;
	priv->mac->supp_mac_addr_2_0 = priv->mac->mac_addr_0;
	priv->mac->supp_mac_addr_2_1 = priv->mac->mac_addr_1;
	priv->mac->supp_mac_addr_3_0 = priv->mac->mac_addr_0;
	priv->mac->supp_mac_addr_3_1 = priv->mac->mac_addr_1;

	priv->mac->command_config =
		YATSE_MAC_CMDCFG_TX_ENA |
		YATSE_MAC_CMDCFG_RX_ENA |
		YATSE_MAC_CMDCFG_PROMIS_EN | // FIXME
		YATSE_MAC_CMDCFG_PAD_EN |
		YATSE_MAC_CMDCFG_RX_ERR_DISC;

	printk(KERN_INFO "yatse: MAC configured. command_config=%08x\n", priv->mac->command_config);

	return 0;
}

static int yatse_open(struct net_device *ndev){
	struct yatse_private *priv = netdev_priv(ndev);
	int ret;
	unsigned long flags;

	printk(KERN_INFO "yatse: opening\n");

	priv->link = 0;

#if 0
	ret = dma_set_mask(&ndev->dev, 0xffffffffULL); /* 32-bit DMA addresses */
	if(ret) goto out;
#endif

	spin_lock_irqsave(&priv->dma.rx_lock, flags);
	spin_lock(&priv->dma.tx_lock);
	ret = yatse_dma_init(ndev);
	spin_unlock(&priv->dma.tx_lock);
	spin_unlock_irqrestore(&priv->dma.rx_lock, flags);
	if(ret) goto out;

	tasklet_init(&priv->tx_tasklet, yatse_tx_complete, (unsigned long)ndev);

	ret = yatse_init_phy(ndev);
	if(ret) goto out;

	ret = yatse_init_mac(ndev);
	if(ret) goto out;


	napi_enable(&priv->napi);

	phy_start(priv->phydev);
	if(priv->phy_irq != PHY_POLL) phy_start_interrupts(priv->phydev);
	netif_start_queue(ndev);

	printk(KERN_INFO "yatse: open done, interface up\n");

out:
	return ret;
}

static int yatse_stop(struct net_device *ndev){
	struct yatse_private *priv = netdev_priv(ndev);
	unsigned long flags;

	napi_disable(&priv->napi);

	printk(KERN_INFO "yatse: shutdown\n");
	spin_lock_irqsave(&priv->mac_lock, flags);
	priv->link = 0;
	if(priv->phy_irq != PHY_POLL) phy_stop_interrupts(priv->phydev);
	phy_disconnect(priv->phydev);
	spin_unlock_irqrestore(&priv->mac_lock, flags);

	disable_irq(priv->dma.rx_irq);
	disable_irq(priv->dma.tx_irq);

	netif_stop_queue(ndev);

	spin_lock_irqsave(&priv->dma.rx_lock, flags);
	spin_lock(&priv->dma.tx_lock);
	yatse_dma_stop(&priv->dma);
	spin_unlock(&priv->dma.tx_lock);
	spin_unlock_irqrestore(&priv->dma.rx_lock, flags);
	tasklet_kill(&priv->tx_tasklet);

	napi_disable(&priv->napi);

	printk(KERN_INFO "yatse: shutdown complete\n");
	
	return 0;
}

#ifdef CONFIG_NET_POLL_CONTROLLER
static void yatse_poll(struct net_device *ndev){
	struct yatse_private *priv = netdev_priv(ndev);

	disable_irq(priv->dma.rx_irq);
	yatse_rx_isr(priv->dma.rx_irq, ndev, NULL);
	enable_irq(priv->dma.rx_irq);

	disable_irq(priv->dma.tx_irq);
	yatse_tx_isr(priv->dma.tx_irq, ndev, NULL);
	enable_irq(priv->dma.tx_irq);
}
#endif

static const struct net_device_ops yatse_netdev_ops = {
	.ndo_open = yatse_open,
	.ndo_stop = yatse_stop,
	.ndo_start_xmit = yatse_start_xmit,
	.ndo_tx_timeout = yatse_tx_timeout,
#ifdef CONFIG_NET_POLL_CONTROLLER
	.ndo_poll_controller = yatse_poll,
#endif
};

static int yatse_mdio_read(struct mii_bus *mii, int mii_id, int regnum){
	struct yatse_mdio_priv *priv = mii->priv;
	int ret;
	unsigned long flags;

	volatile unsigned int *reg = (&priv->mac->mdio_phy0) + regnum;

	spin_lock_irqsave(&priv->lock, flags);
	writel(mii_id, &priv->mac->mdio_phy0_addr);
	ret = readl(reg) & 0xffff;
	spin_unlock_irqrestore(&priv->lock, flags);

	return ret;
}

static int yatse_mdio_write(struct mii_bus *mii, int mii_id, int regnum, u16 value){
	struct yatse_mdio_priv *priv = mii->priv;
	unsigned long flags;

	volatile unsigned int *reg = (&priv->mac->mdio_phy0) + regnum;

	spin_lock_irqsave(&priv->lock, flags);
	writel(mii_id, &priv->mac->mdio_phy0_addr);
	writel(value, reg);
	spin_unlock_irqrestore(&priv->lock, flags);

	return 0;
}

static int yatse_detect_phys(struct yatse_private *priv, struct mii_bus *mdio){
	int i;
	int ret;
	u32 phy_id;

	priv->phy_addr = -1;
	
	for(i = 31;i >= 0;i--){
		ret = get_phy_id(mdio, i, &phy_id);
		if(ret) return ret;
		if(((phy_id >> 16) & 0xffff) != (phy_id & 0xffff)){
			printk(KERN_INFO "yatse: found PHY id=%x at addr %x\n", phy_id, i);
			priv->phy_addr = i;
		}
	}

	return ret;
}

static int yatse_mdio_register(struct yatse_private *priv){
	struct mii_bus *mdio;
	struct yatse_mdio_priv *mdio_priv;
	int ret;
	int i;

	mdio = mdiobus_alloc();
	if(!mdio) return -ENOMEM;

	mdio->name = "yatse MII bus";
	mdio->read = &yatse_mdio_read;
	mdio->write = &yatse_mdio_write;
	snprintf(mdio->id, MII_BUS_ID_SIZE, "%u", priv->config->mii_id);


	mdio->priv = kmalloc(sizeof(*mdio_priv), GFP_KERNEL);
	if(!mdio->priv) return -ENOMEM;

	mdio_priv = mdio->priv;
	mdio_priv->mac = priv->mac;
	spin_lock_init(&mdio_priv->lock);

	for(i = 0;i < 32;i++){
		mdio_priv->irqs[i] = priv->phy_irq;
	}
	mdio->irq = (void *)&mdio_priv->irqs;

	ret = mdiobus_register(mdio);
	if(ret){
		printk(KERN_ERR "%s:%d: mdiobus_register() failed\n", __FILE__, __LINE__);
		mdiobus_free(mdio);
		return ret;
	}

	return yatse_detect_phys(priv, mdio);
}


static void *yatse_iomap(struct platform_device *pdev, char *res_name, resource_size_t length){
	struct resource *res;
	void *ret;
	
	res = platform_get_resource_byname(pdev, IORESOURCE_MEM, res_name);
	if(!res){
		printk(KERN_ERR "%s:%d: platform_get_resource_byname() failed\n", __FILE__, __LINE__);
		return NULL;
	}

	if(!request_mem_region(res->start, length ? length : resource_size(res), "yatse")){
		printk(KERN_ERR "%s:%d: request_mem_region failed\n", __FILE__, __LINE__);
		return NULL;
	}

	ret = ioremap_nocache(res->start, length ? length : resource_size(res));
	if(!ret){
		printk(KERN_ERR "%s:%d: ioremap_nocache() failed\n", __FILE__, __LINE__);
		return NULL;
	}

	return ret;
}

static int yatse_get_irq(struct platform_device *pdev, char *res_name){
	struct resource *res;

   res = platform_get_resource_byname(pdev, IORESOURCE_IRQ, res_name);
   if(!res){
      printk(KERN_ERR "%s:%d: platform_get_resource_byname() failed\n", __FILE__, __LINE__);
      return -1;
   }

   return res->start;
}

static int yatse_probe(struct platform_device *pdev){
	struct net_device *ndev;
	struct yatse_private *priv;
	int ret;
	int i;

	printk(KERN_INFO "yatse_probe() start\n");

	ndev = alloc_etherdev(sizeof(*priv));
	if(!ndev){
		printk(KERN_ERR "%s:%d: alloc_etherdev() failed\n", __FILE__, __LINE__);
		return -ENODEV;
	}
	priv = netdev_priv(ndev);
	priv->ndev = ndev;
	SET_NETDEV_DEV(ndev, &pdev->dev);
	platform_set_drvdata(pdev, ndev);

	spin_lock_init(&priv->mac_lock);
	spin_lock_init(&priv->dma.rx_lock);
	spin_lock_init(&priv->dma.tx_lock);

	priv->config = (struct yatse_config *)pdev->dev.platform_data;
	priv->phy_irq = PHY_POLL;
	priv->mtu = priv->config->max_mtu;
	for(i = 0;i < 6;i++) ndev->dev_addr[i] = priv->config->ethaddr[i];

	if(!(priv->mac = (yatse_mac_regs *)yatse_iomap(pdev, YATSE_RESOURCE_MAC, 0))) return -ENODEV;
	if(!(priv->dma.csr = yatse_iomap(pdev, YATSE_RESOURCE_DMA_CSR, 0))) return -ENODEV;

	priv->dma.rx_ring_length = readl(&priv->dma.csr->rx);
	priv->dma.rx_ring_mask = priv->dma.rx_ring_length - 1;
	if((priv->dma.rx_ring_length <= 0) || (priv->dma.rx_ring_length & priv->dma.rx_ring_mask)){
		printk(KERN_ERR "yatse_probe: bogus HW RX ring size %08x\n", priv->dma.rx_ring_length);
		return -EIO;
	}
	priv->dma.tx_ring_length = readl(&priv->dma.csr->tx);
	priv->dma.tx_ring_mask = priv->dma.tx_ring_length - 1;
	if((priv->dma.tx_ring_length <= 0) || (priv->dma.tx_ring_length & priv->dma.tx_ring_mask)){
		printk(KERN_ERR "yatse_probe: bogus HW TX ring size %08x\n", priv->dma.tx_ring_length);
		return -EIO;
	}

	if(!(priv->dma.rx = yatse_iomap(pdev, YATSE_RESOURCE_RX_RING, priv->dma.rx_ring_length * sizeof(yatse_dma_desc)))) return -ENODEV;
	if(!(priv->dma.tx = yatse_iomap(pdev, YATSE_RESOURCE_TX_RING, priv->dma.tx_ring_length * sizeof(yatse_dma_desc)))) return -ENODEV;


	priv->dma.rx_irq = yatse_get_irq(pdev, YATSE_RESOURCE_RX_IRQ);
	if(priv->dma.rx_irq == -1) return -ENODEV;
	ret = request_irq(priv->dma.rx_irq, (void *)yatse_rx_isr, 0, "yatse-RX", ndev);
	if(ret){
		printk(KERN_ERR "%s:%d: request_irq() failed\n", __FILE__, __LINE__);
		return -EAGAIN;
	}

	priv->dma.tx_irq = yatse_get_irq(pdev, YATSE_RESOURCE_TX_IRQ);
	if(priv->dma.tx_irq == -1) return -ENODEV;
	ret = request_irq(priv->dma.tx_irq, (void *)yatse_tx_isr, 0, "yatse-TX", ndev);
	if(ret){
		printk(KERN_ERR "%s:%d: request_irq() failed\n", __FILE__, __LINE__);
		return -EAGAIN;
	}

	priv->phy_irq = yatse_get_irq(pdev, YATSE_RESOURCE_PHY_IRQ);

	printk(KERN_INFO "yatse: device probed; mac=%p, phy_irq=%d, dma.csr=%p, dma.rx=%p, dma.tx=%p, dma.rx_irq=%d, dma.tx_irq=%d, mtu=%d, rx_ring_length=%d, tx_ring_length=%d, fifo=%d\n", priv->mac, priv->phy_irq, priv->dma.csr, priv->dma.rx, priv->dma.tx, priv->dma.rx_irq, priv->dma.tx_irq, priv->mtu, priv->dma.rx_ring_length, priv->dma.tx_ring_length, priv->config->fifo_depth);

	ret = yatse_mdio_register(priv);
	if(ret){
		printk(KERN_ERR "%s:%d: yatse_mdio_register() failed\n", __FILE__, __LINE__);
		return -ENODEV;
	}

	ndev->netdev_ops = &yatse_netdev_ops;
	ndev->watchdog_timeo = msecs_to_jiffies(5000);
	netif_napi_add(ndev, &priv->napi, yatse_rx_poll, 64);

	ret = register_netdev(ndev);
	if(ret){
		printk(KERN_ERR "%s:%d: register_netdev() failed\n", __FILE__, __LINE__);
		return -ENODEV;
	}

	printk(KERN_INFO "yatse_probe() end\n");
	return 0;
}

static void __devexit yatse_iounmap(struct platform_device *pdev, char *res_name){
	struct resource *res;
	
	res = platform_get_resource_byname(pdev, IORESOURCE_MEM, res_name);
	if(!res){
		printk(KERN_ERR "%s:%d: platform_get_resource_byname() failed\n", __FILE__, __LINE__);
		return;
	}

	iounmap((void *)res->start);
	release_mem_region(res->start, resource_size(res));
}

static int __devexit yatse_remove(struct platform_device *pdev){
	struct net_device *ndev = platform_get_drvdata(pdev);
	struct yatse_private *priv = netdev_priv(ndev);

	free_irq(priv->dma.rx_irq, (void *)ndev);
	free_irq(priv->dma.tx_irq, (void *)ndev);

	yatse_iounmap(pdev, YATSE_RESOURCE_MAC);
	yatse_iounmap(pdev, YATSE_RESOURCE_DMA_CSR);
	yatse_iounmap(pdev, YATSE_RESOURCE_RX_RING);
	yatse_iounmap(pdev, YATSE_RESOURCE_TX_RING);

	platform_set_drvdata(pdev, NULL);
	unregister_netdev(ndev);
	free_netdev(ndev);

	return 0;
}

static struct platform_driver yatse_driver = {
	.driver = {
		.name = "yatse",
		.owner = THIS_MODULE,
	},
	.probe = yatse_probe,
	.remove = yatse_remove,
	.suspend = NULL,
	.resume = NULL,
};

static int __init yatse_init(void){
	return platform_driver_register(&yatse_driver);
}

static void __exit yatse_exit(void){
	platform_driver_unregister(&yatse_driver);
}

module_init(yatse_init);
module_exit(yatse_exit);
