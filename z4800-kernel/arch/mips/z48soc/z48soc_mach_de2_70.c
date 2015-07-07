#include <linux/init.h>
#include <linux/kernel.h>
#include <linux/platform_device.h>
#include <linux/interrupt.h>
#include <linux/mtd/physmap.h>
#include <linux/spi/spi.h>
#include <linux/spi/mmc_spi.h>
#include <linux/mmc/host.h>

const size_t z48soc_ram_size_mb = 64;
const long z48soc_cpu_clock_freq_khz = 25000;

#define UART_BASE 0x1fd00040
#define UART_IRQ 34

//#define JTAG_UART_BASE 0x1fd00030
//#define JTAG_UART_IRQ 32

#define DM9000_BASE 0x1fd00080
#define DM9000_IRQ 33

#define ISP1362_BASE 0x1fd000a0
#define ISP1362_IRQ 36

#define ALTERA_PS2K_BASE 0x1fd00020
#define ALTERA_PS2K_IRQ 35
#define ALTERA_PS2M_BASE 0x1fd00028
#define ALTERA_PS2M_IRQ 39

//#define SPI_BASE 0x1fd000c0
//#define SPI_IRQ 38

#define CFI_BASE 0x1c000000
#define CFI_WIDTH 2
#define CFI_SIZE (8 * 1024 * 1024)

#ifdef JTAG_UART_BASE
#include <linux/altera_jtaguart.h>
static struct altera_jtaguart_platform_uart jtaguart_platform[] = {
	{
		.mapbase = JTAG_UART_BASE,
		.irq = JTAG_UART_IRQ,
	},
	{},
};
static struct platform_device jtaguart = {
	.name = "altera_jtaguart",
	.id = 0,
	.dev.platform_data = jtaguart_platform,
};
#endif

#ifdef UART_BASE
#include <linux/altera_uart.h>
static struct altera_uart_platform_uart uart_platform[] = {
	{
		.mapbase = UART_BASE,
		.irq = UART_IRQ,
	},
	{},
};
static struct platform_device uart = {
	.name = "altera_uart",
	.id = 0,
	.dev.platform_data = uart_platform,
};
#endif

#ifdef DM9000_BASE
#include <linux/dm9000.h>
static struct resource dm9k_resource[] = {
	[0] = {
		.start = DM9000_BASE,
		.end   = DM9000_BASE + 3,
		.flags = IORESOURCE_MEM,
	},
	[1] = {
		.start = DM9000_BASE + 4,
		.end   = DM9000_BASE + 4 + 3,
		.flags = IORESOURCE_MEM,
	},
	[2] = {
		.start = DM9000_IRQ,
		.end   = DM9000_IRQ,
		.flags = IORESOURCE_IRQ | IRQF_TRIGGER_HIGH,
	},

};
static struct dm9000_plat_data dm9k_platdata = {
	.flags      = DM9000_PLATF_16BITONLY,
#ifdef DM9000_MAC
   .dev_addr   = DM9000_MAC
#endif
};
static struct platform_device dm9k_device = {
	.name    = "dm9000",
	.id      = 0,
	.num_resources = ARRAY_SIZE(dm9k_resource),
	.resource   = dm9k_resource,
	.dev     = {
		.platform_data = &dm9k_platdata,
	}
};
#endif

#ifdef ISP1362_BASE
#include <linux/usb/isp1362.h>
static struct resource isp1362_resource[] = {
   [0] = {
      .start = ISP1362_BASE,
      .end = ISP1362_BASE + 3,
      .flags = IORESOURCE_MEM,
   },
   [1] = {
      .start = ISP1362_BASE + 4,
      .end = ISP1362_BASE + 4 + 3,
      .flags = IORESOURCE_MEM,
   },
   [2] = {
      .start = ISP1362_IRQ,
      .end = ISP1362_IRQ,
      .flags = IORESOURCE_IRQ | IRQF_TRIGGER_HIGH,
   },
};
static struct isp1362_platform_data isp1362_platdata = {
     // Enable internal resistors on downstream ports
   .sel15Kres  = 1,
     // Clock cannot be stopped
   .clknotstop = 0,
     // On-chip overcurrent protection
   .oc_enable  = 1,
     // INT output polarity
   .int_act_high  = 0,
     // INT edge or level triggered
   .int_edge_triggered  = 0,
     // WAKEUP pin connected
   .remote_wakeup_connected   = 0,
     // Switch or not to switch (keep always powered)
   .no_power_switching  = 1,
     // Ganged port power switching (0) or individual port power switching (1)
   .power_switching_mode   = 0,
};
static struct platform_device isp1362_hcd = {
   .name = "isp1362-hcd",
   .id = -1,
   .dev = {
      .platform_data = &isp1362_platdata,
   },
   .num_resources = ARRAY_SIZE(isp1362_resource),
   .resource = isp1362_resource,
};
#endif

#ifdef ALTERA_PS2K_BASE
static struct resource ps2k_resource[] = {
	[0] = {
		.start = ALTERA_PS2K_BASE,
		.end   = ALTERA_PS2K_BASE + 7,
		.flags = IORESOURCE_MEM,
	},
	[1] = {
		.start = ALTERA_PS2K_IRQ,
		.end   = ALTERA_PS2K_IRQ,
		.flags = IORESOURCE_IRQ | IRQF_TRIGGER_HIGH,
	},
};
static struct platform_device ps2k_device = {
	.name    = "altera_ps2",
	.id      = 0,
	.num_resources = ARRAY_SIZE(ps2k_resource),
	.resource   = ps2k_resource,
};
#endif
#ifdef ALTERA_PS2M_BASE
static struct resource ps2m_resource[] = {
	[0] = {
		.start = ALTERA_PS2M_BASE,
		.end   = ALTERA_PS2M_BASE + 7,
		.flags = IORESOURCE_MEM,
	},
	[1] = {
		.start = ALTERA_PS2M_IRQ,
		.end   = ALTERA_PS2M_IRQ,
		.flags = IORESOURCE_IRQ | IRQF_TRIGGER_HIGH,
	},
};
static struct platform_device ps2m_device = {
	.name    = "altera_ps2",
	.id      = 1,
	.num_resources = ARRAY_SIZE(ps2m_resource),
	.resource   = ps2m_resource,
};
#endif

#ifdef SPI_BASE
static struct resource altspi_resource[] = {
	[0] = {
		.start = SPI_BASE,
		.end   = SPI_BASE + 0x3f,
		.flags = IORESOURCE_MEM,
	},
	[1] = {
		.start = SPI_IRQ,
		.end	 = SPI_IRQ,
		.flags = IORESOURCE_IRQ | IRQF_TRIGGER_HIGH,
	},
};
static struct platform_device altspi_device = {
	.name    = "altspi",
	.id      = 0,
	.num_resources = ARRAY_SIZE(altspi_resource),
	.resource   = altspi_resource,
};
static struct spi_board_info spi_bus[] = {
   {
      .modalias      = "mmc_spi",
      .max_speed_hz  = 25000000,
      .bus_num       = 0,
      .chip_select   = 0,
   },
};
#endif

#ifdef CFI_BASE
static struct resource cfi_resource = {
   .start   = CFI_BASE,
   .end     = CFI_BASE + CFI_SIZE - 1,
   .flags   = IORESOURCE_MEM,
};
static struct physmap_flash_data cfi_data = {
   .width   = CFI_WIDTH,
};
static struct platform_device cfi_device = {
   .name          = "physmap-flash",
   .id            = -1,
   .dev           = {
      .platform_data = &cfi_data,
   },
   .num_resources = 1,
   .resource      = &cfi_resource,
};
#endif

#define REGISTER_DEVICE(x) \
   do { \
      err = platform_device_register(&x); \
      if(err){ \
         printk(KERN_ERR "%s: registration failed (%d)\n", x.name, err); \
      } \
   } while(0)


static int __init z48soc_devinit(void){
	int err;

#ifdef JTAG_UART_BASE
   REGISTER_DEVICE(jtaguart);
#endif
#ifdef UART_BASE
   REGISTER_DEVICE(uart);
#endif
#ifdef ALTERA_PS2K_BASE
   REGISTER_DEVICE(ps2k_device);
#endif
#ifdef ALTERA_PS2M_BASE
   REGISTER_DEVICE(ps2m_device);
#endif
#ifdef DM9000_BASE
   REGISTER_DEVICE(dm9k_device);
#endif
#ifdef ISP1362_BASE
   REGISTER_DEVICE(isp1362_hcd);
#endif
#ifdef SPI_BASE
   spi_register_board_info(spi_bus, ARRAY_SIZE(spi_bus));
   REGISTER_DEVICE(altspi_device);
#endif
#ifdef CFI_BASE
   REGISTER_DEVICE(cfi_device);
#endif
#ifdef ETH0_MAC
   REGISTER_DEVICE(eth0_device);
#endif
	return 0;
}

device_initcall(z48soc_devinit);

#include "z48soc_early_printk.h"
