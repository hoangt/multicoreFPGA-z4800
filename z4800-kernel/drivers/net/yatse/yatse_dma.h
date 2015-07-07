#ifndef _YATSE_DMA_H_
#define _YATSE_DMA_H_

#include "yatse.h"

typedef struct __yatse_dma_desc {
	uint32_t				addr;
	uint16_t				len;
	uint8_t				error;
	uint8_t				status;
} __attribute__ ((packed)) yatse_dma_desc;

#define YATSE_DESC_STATUS_HW								YATSE_BIT(0)

typedef struct __yatse_dma_csr {
	uint32_t				rcontrol;
	uint32_t				tcontrol;
	uint32_t				rx;
	uint32_t				tx;
} __attribute__ ((packed)) yatse_dma_csr;

#define YATSE_CSR_RCONTROL_RXRST							YATSE_BIT(0)
#define YATSE_CSR_RCONTROL_RXENA							YATSE_BIT(1)
#define YATSE_CSR_RCONTROL_RXIE							YATSE_BIT(2)
#define YATSE_CSR_RCONTROL_RXIS							YATSE_BIT(3)
#define YATSE_CSR_RCONTROL_PHYIE							YATSE_BIT(30)
#define YATSE_CSR_RCONTROL_PHYIS							YATSE_BIT(31)

#define YATSE_CSR_TCONTROL_TXRST							YATSE_BIT(0)
#define YATSE_CSR_TCONTROL_TXENA							YATSE_BIT(1)
#define YATSE_CSR_TCONTROL_TXIE							YATSE_BIT(2)
#define YATSE_CSR_TCONTROL_TXIS							YATSE_BIT(3)


struct yatse_dma {
	yatse_dma_csr __iomem *csr;

	yatse_dma_desc __iomem *rx;
	int rx_irq;
	spinlock_t rx_lock;
	struct sk_buff **rx_skbs;
	dma_addr_t *rx_skb_phys;
	int rx_buf_len;
	int rx_align;
	int rx_ring_length, rx_ring_mask;
	int rx_pos;

	yatse_dma_desc __iomem *tx;
	int tx_irq;
	spinlock_t tx_lock;
	struct sk_buff **tx_skbs;
	dma_addr_t *tx_skb_phys;
	int tx_ring_length, tx_ring_mask;
	int tx_insert, tx_remove;
	int tx_queued;
};

#define YATSE_RING_NEXT(cur, mask) (((cur) + 1) & (mask))

void yatse_dma_stop(struct yatse_dma *dma);
int yatse_dma_init(struct net_device *ndev);
void yatse_dma_free(struct net_device *ndev);

#endif
