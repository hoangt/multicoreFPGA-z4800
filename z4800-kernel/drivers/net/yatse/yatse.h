#ifndef _YATSE_H_
#define _YATSE_H_

#include <linux/delay.h>
#include <linux/pm.h>
#include <linux/platform_device.h>
#include <linux/kernel.h>
#include <linux/interrupt.h>
#include <linux/netdevice.h>
#include <linux/etherdevice.h>
#include <linux/skbuff.h>
#include <linux/slab.h>
#include <linux/dma-mapping.h>
#include <linux/dmapool.h>
#include <linux/ioport.h>
#include <linux/interrupt.h>
#include <linux/spinlock.h>
#include <linux/mii.h>
#include <linux/phy.h>
#include <linux/ethtool.h>

#define YATSE_RESOURCE_MAC "yatse_mac"
#define YATSE_RESOURCE_DMA_CSR "yatse_dma_csr"
#define YATSE_RESOURCE_RX_RING "yatse_rx_ring"
#define YATSE_RESOURCE_RX_IRQ "yatse_rx_irq"
#define YATSE_RESOURCE_TX_RING "yatse_tx_ring"
#define YATSE_RESOURCE_TX_IRQ "yatse_tx_irq"
#define YATSE_RESOURCE_PHY_IRQ "yatse_phy_irq"

#define YATSE_BIT(n) (1 << (n))
#define YATSE_BITS(h, l) ((YATSE_BIT(h) - 1) & ~(YATSE_BIT(l) - 1))

#include "yatse_dma.h"

#define YATSE_MAC_CMDCFG_TX_ENA									YATSE_BIT(0)
#define YATSE_MAC_CMDCFG_RX_ENA									YATSE_BIT(1)
#define YATSE_MAC_CMDCFG_XON_GEN									YATSE_BIT(2)
#define YATSE_MAC_CMDCFG_ETH_SPEED								YATSE_BIT(3)
#define YATSE_MAC_CMDCFG_PROMIS_EN								YATSE_BIT(4)
#define YATSE_MAC_CMDCFG_PAD_EN									YATSE_BIT(5)
#define YATSE_MAC_CMDCFG_CRC_FWD									YATSE_BIT(6)
#define YATSE_MAC_CMDCFG_PAUSE_FWD								YATSE_BIT(7)
#define YATSE_MAC_CMDCFG_PAUSE_IGNORE							YATSE_BIT(8)
#define YATSE_MAC_CMDCFG_TX_ADDR_INS							YATSE_BIT(9)
#define YATSE_MAC_CMDCFG_HD_ENA									YATSE_BIT(10)
#define YATSE_MAC_CMDCFG_EXCESS_COL								YATSE_BIT(11)
#define YATSE_MAC_CMDCFG_LATE_COL								YATSE_BIT(12)
#define YATSE_MAC_CMDCFG_SW_RESET								YATSE_BIT(13)
#define YATSE_MAC_CMDCFG_MHASH_SEL								YATSE_BIT(14)
#define YATSE_MAC_CMDCFG_LOOP_ENA								YATSE_BIT(15)
#define YATSE_MAC_CMDCFG_TX_ADDR_SEL							YATSE_BITS(18, 16)
#define YATSE_MAC_CMDCFG_MAGIC_ENA								YATSE_BIT(19)
#define YATSE_MAC_CMDCFG_SLEEP									YATSE_BIT(20)
#define YATSE_MAC_CMDCFG_WAKEUP									YATSE_BIT(21)
#define YATSE_MAC_CMDCFG_XOFF_GEN								YATSE_BIT(22)
#define YATSE_MAC_CMDCFG_CNTL_FRM_ENA							YATSE_BIT(23)
#define YATSE_MAC_CMDCFG_NO_LGTH_CHECK							YATSE_BIT(24)
#define YATSE_MAC_CMDCFG_ENA_10									YATSE_BIT(25)
#define YATSE_MAC_CMDCFG_RX_ERR_DISC							YATSE_BIT(26)
#define YATSE_MAC_CMDCFG_DISABLE_RD_TIMEOUT					YATSE_BIT(27)
#define YATSE_MAC_CMDCFG_CNT_RESET								YATSE_BIT(31)

#define YATSE_MAC_TXCMDSTAT_OMIT_CRC							YATSE_BIT(17)
#define YATSE_MAC_TXCMDSTAT_TX_SHIFT16							YATSE_BIT(18)

#define YATSE_MAC_RXCMDSTAT_RX_SHIFT16							YATSE_BIT(25)

typedef volatile struct {
  unsigned int            megacore_revision;              /* Bits 15:0: MegaCore function revision (0x0800). Bit 31:16: Customer specific revision*/
  unsigned int            scratch_pad;                    /*Provides a memory location for user applications to test the device memory operation.*/
  unsigned int            command_config;                 /*The host processor uses this register to control and configure the MAC block.*/
  unsigned int            mac_addr_0;                     /*32-bit primary MAC address word 0 bits 0 to 31 of the primary MAC address.*/
  unsigned int            mac_addr_1;                     /*32-bit primary MAC address word 1 bits 32 to 47 of the primary MAC address.*/
  unsigned int            max_frame_length;               /*14-bit maximum frame length. The MAC receive logic*/
  unsigned int            pause_quanta;                   /*The pause quanta is used in each pause frame sent to a remote Ethernet device, in increments of 512 Ethernet bit times.*/
  unsigned int            rx_sel_empty_threshold;         /*12-bit receive FIFO section-empty threshold.*/
  unsigned int            rx_sel_full_threshold;          /*12-bit receive FIFO section-full threshold*/
  unsigned int            tx_sel_empty_threshold;         /*12-bit transmit FIFO section-empty threshold.*/
  unsigned int            tx_sel_full_threshold;          /*12-bit transmit FIFO section-full threshold.*/
  unsigned int            rx_almost_empty_threshold;      /*12-bit receive FIFO almost-empty threshold*/
  unsigned int            rx_almost_full_threshold;       /*12-bit receive FIFO almost-full threshold.*/
  unsigned int            tx_almost_empty_threshold;      /*12-bit transmit FIFO almost-empty threshold*/
  unsigned int            tx_almost_full_threshold;       /*12-bit transmit FIFO almost-full threshold*/
  unsigned int            mdio_phy0_addr;                 /*MDIO address of PHY Device 0. Bits 0 to 4 hold a 5-bit PHY address.*/
  unsigned int            mdio_phy1_addr;                 /*MDIO address of PHY Device 1. Bits 0 to 4 hold a 5-bit PHY address.*/
  /* only if 100/1000 BaseX PCS, reserved otherwise*/
  unsigned int            reservedx44[5];

  unsigned int            reg_read_access_status;         /*This register is used to check the correct completion of register read access*/
  unsigned int            min_tx_ipg_length;              /*Minimum IPG between consecutive transmit frame in terms of bytes */

 /* IEEE 802.3 oEntity Managed Object Support */
  unsigned int            aMACID_1;                       /*The MAC addresses*/
  unsigned int            aMACID_2;
  unsigned int            aFramesTransmittedOK;           /*Number of frames transmitted without error including pause frames.*/
  unsigned int            aFramesReceivedOK;              /*Number of frames received without error including pause frames.*/
  unsigned int            aFramesCheckSequenceErrors;     /*Number of frames received with a CRC error.*/
  unsigned int            aAlignmentErrors;               /*Frame received with an alignment error.*/
  unsigned int            aOctetsTransmittedOK;           /*Sum of payload and padding octets of frames transmitted without error.*/
  unsigned int            aOctetsReceivedOK;              /*Sum of payload and padding octets of frames received without error.*/

  /* IEEE 802.3 oPausedEntity Managed Object Support */
  unsigned int            aTxPAUSEMACCtrlFrames;          /*Number of transmitted pause frames.*/
  unsigned int            aRxPAUSEMACCtrlFrames;          /*Number of Received pause frames.*/

 /* IETF MIB (MIB-II) Object Support */
  unsigned int            ifInErrors;                     /*Number of frames received with error*/
  unsigned int            ifOutErrors;                    /*Number of frames transmitted with error*/
  unsigned int            ifInUcastPkts;                  /*Number of valid received unicast frames.*/
  unsigned int            ifInMulticastPkts;              /*Number of valid received multicasts frames (without pause).*/
  unsigned int            ifInBroadcastPkts;              /*Number of valid received broadcast frames.*/
  unsigned int            ifOutDiscards;
  unsigned int            ifOutUcastPkts;                                        
  unsigned int            ifOutMulticastPkts;
  unsigned int            ifOutBroadcastPkts;

  /* IETF RMON MIB Object Support */
  unsigned int            etherStatsDropEvent;           /*Counts the number of dropped packets due to internal errors of the MAC client.*/
  unsigned int            etherStatsOctets;              /*Total number of bytes received. Good and bad frames.*/
  unsigned int            etherStatsPkts;                /*Total number of packets received. Counts good and bad packets.*/
  unsigned int            etherStatsUndersizePkts;       /*Number of packets received with less than 64 bytes.*/
  unsigned int            etherStatsOversizePkts;        /*Number of each well-formed packet that exceeds the valid maximum programmed frame length*/
  unsigned int            etherStatsPkts64Octets;        /*Number of received packet with 64 bytes*/
  unsigned int            etherStatsPkts65to127Octets;   /*Frames (good and bad) with 65 to 127 bytes*/
  unsigned int            etherStatsPkts128to255Octets;  /*Frames (good and bad) with 128 to 255 bytes*/
  unsigned int            etherStatsPkts256to511Octets;  /*Frames (good and bad) with 256 to 511 bytes*/
  unsigned int            etherStatsPkts512to1023Octets; /*Frames (good and bad) with 512 to 1023 bytes*/
  unsigned int            etherStatsPkts1024to1518Octets;/*Frames (good and bad) with 1024 to 1518 bytes*/

  unsigned int            etherStatsPkts1519toXOctets;   /*Any frame length from 1519 to the maximum length configured in the frm_length register, if it is greater than 1518.*/
  unsigned int            etherStatsJabbers;             /*Too long frames with CRC error.*/
  unsigned int            etherStatsFragments;           /*Too short frames with CRC error.*/

  unsigned int            reservedxE4;

  /*FIFO control register.*/
  unsigned int            tx_cmd_stat;
  unsigned int            rx_cmd_stat;

  unsigned int            ipaccTxConf;                    // TX configuration
  unsigned int            ipaccRxConf;                    // RX configuration
  unsigned int            ipaccRxStat;                    // IP status
  unsigned int            ipaccRxStatSum;                 // current frame's IP payload sum result

  /*Multicast address resolution table, mapped in the controller address space.*/
  unsigned int            hash_table[64];

  /*Registers 0 to 31 within PHY device 0/1 connected to the MDIO PHY management interface.*/
  unsigned int            mdio_phy0;
  unsigned int            mdio_phy1;

  /*4 Supplemental MAC Addresses*/
  unsigned int            supp_mac_addr_0_0;
  unsigned int            supp_mac_addr_0_1;
  unsigned int            supp_mac_addr_1_0;
  unsigned int            supp_mac_addr_1_1;
  unsigned int            supp_mac_addr_2_0;
  unsigned int            supp_mac_addr_2_1;
  unsigned int            supp_mac_addr_3_0;
  unsigned int            supp_mac_addr_3_1;

  unsigned int            reservedx320[56];
} yatse_mac_regs;

struct yatse_config{
	int mii_id;
	char ethaddr[6];
	phy_interface_t interface;
	unsigned int supported_modes;
	int max_mtu;
	int fifo_depth;
	int rx_align;
};

struct yatse_private{
   yatse_mac_regs *mac;
   spinlock_t mac_lock;
   int mtu;
	int link;
	int duplex;
	int speed;

   struct yatse_dma dma;

   struct napi_struct napi;
	struct tasklet_struct tx_tasklet;
   struct yatse_config *config;

   int phy_addr;
	int phy_irq;
   struct phy_device *phydev;
	struct net_device *ndev;
};

struct yatse_mdio_priv{
   yatse_mac_regs *mac;
   spinlock_t lock;
   int irqs[32];
};

//void yatse_dump_skb(struct sk_buff *skb);

struct sk_buff *yatse_rx_alloc_skb(struct net_device *ndev);
irqreturn_t yatse_rx_isr(int irq, void *dev_id, struct pt_regs *regs);
int yatse_rx_poll(struct napi_struct *napi, int budget);
void yatse_rx_insert_skb(struct net_device *ndev, struct yatse_dma *dma, dma_addr_t phys);

void yatse_tx_complete(unsigned long ndevl);
irqreturn_t yatse_tx_isr(int irq, void *dev_id, struct pt_regs *regs);
int yatse_start_xmit(struct sk_buff *skb, struct net_device *ndev);
void yatse_tx_timeout(struct net_device *ndev);

#endif
