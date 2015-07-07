/*
 * Copyright (C) ST-Ericsson SA 2010
 *
 * License terms: GNU General Public License (GPL) version 2
 */

#include <linux/kernel.h>
#include <linux/init.h>
#include <linux/gpio.h>

#include <asm/mach-types.h>
#include <plat/pincfg.h>
#include <mach/hardware.h>

#include "pins-db8500.h"

static pin_cfg_t mop500_pins_common[] = {
	/* I2C */
	GPIO147_I2C0_SCL,
	GPIO148_I2C0_SDA,
	GPIO16_I2C1_SCL,
	GPIO17_I2C1_SDA,
	GPIO10_I2C2_SDA,
	GPIO11_I2C2_SCL,
	GPIO229_I2C3_SDA,
	GPIO230_I2C3_SCL,

	/* MSP0 */
	GPIO12_MSP0_TXD,
	GPIO13_MSP0_TFS,
	GPIO14_MSP0_TCK,
	GPIO15_MSP0_RXD,

	/* MSP2: HDMI */
	GPIO193_MSP2_TXD,
	GPIO194_MSP2_TCK,
	GPIO195_MSP2_TFS,
	GPIO196_MSP2_RXD | PIN_OUTPUT_LOW,

	/* Touch screen INTERFACE */
	GPIO84_GPIO	| PIN_INPUT_PULLUP, /* TOUCH_INT1 */

	/* STMPE1601/tc35893 keypad  IRQ */
	GPIO218_GPIO	| PIN_INPUT_PULLUP,

	/* MMC0 (MicroSD card) */
	GPIO18_MC0_CMDDIR	| PIN_OUTPUT_HIGH,
	GPIO19_MC0_DAT0DIR	| PIN_OUTPUT_HIGH,
	GPIO20_MC0_DAT2DIR	| PIN_OUTPUT_HIGH,

	GPIO22_MC0_FBCLK	| PIN_INPUT_NOPULL,
	GPIO23_MC0_CLK		| PIN_OUTPUT_LOW,
	GPIO24_MC0_CMD		| PIN_INPUT_PULLUP,
	GPIO25_MC0_DAT0		| PIN_INPUT_PULLUP,
	GPIO26_MC0_DAT1		| PIN_INPUT_PULLUP,
	GPIO27_MC0_DAT2		| PIN_INPUT_PULLUP,
	GPIO28_MC0_DAT3		| PIN_INPUT_PULLUP,

	/* SDI1 (SDIO) */
	GPIO208_MC1_CLK		| PIN_OUTPUT_LOW,
	GPIO209_MC1_FBCLK	| PIN_INPUT_NOPULL,
	GPIO210_MC1_CMD		| PIN_INPUT_PULLUP,
	GPIO211_MC1_DAT0	| PIN_INPUT_PULLUP,
	GPIO212_MC1_DAT1	| PIN_INPUT_PULLUP,
	GPIO213_MC1_DAT2	| PIN_INPUT_PULLUP,
	GPIO214_MC1_DAT3	| PIN_INPUT_PULLUP,

	/* MMC2 (On-board DATA INTERFACE eMMC) */
	GPIO128_MC2_CLK		| PIN_OUTPUT_LOW,
	GPIO129_MC2_CMD		| PIN_INPUT_PULLUP,
	GPIO130_MC2_FBCLK	| PIN_INPUT_NOPULL,
	GPIO131_MC2_DAT0	| PIN_INPUT_PULLUP,
	GPIO132_MC2_DAT1	| PIN_INPUT_PULLUP,
	GPIO133_MC2_DAT2	| PIN_INPUT_PULLUP,
	GPIO134_MC2_DAT3	| PIN_INPUT_PULLUP,
	GPIO135_MC2_DAT4	| PIN_INPUT_PULLUP,
	GPIO136_MC2_DAT5	| PIN_INPUT_PULLUP,
	GPIO137_MC2_DAT6	| PIN_INPUT_PULLUP,
	GPIO138_MC2_DAT7	| PIN_INPUT_PULLUP,

	/* MMC4 (On-board STORAGE INTERFACE eMMC) */
	GPIO197_MC4_DAT3	| PIN_INPUT_PULLUP,
	GPIO198_MC4_DAT2	| PIN_INPUT_PULLUP,
	GPIO199_MC4_DAT1	| PIN_INPUT_PULLUP,
	GPIO200_MC4_DAT0	| PIN_INPUT_PULLUP,
	GPIO201_MC4_CMD		| PIN_INPUT_PULLUP,
	GPIO202_MC4_FBCLK	| PIN_INPUT_NOPULL,
	GPIO203_MC4_CLK		| PIN_OUTPUT_LOW,
	GPIO204_MC4_DAT7	| PIN_INPUT_PULLUP,
	GPIO205_MC4_DAT6	| PIN_INPUT_PULLUP,
	GPIO206_MC4_DAT5	| PIN_INPUT_PULLUP,
	GPIO207_MC4_DAT4	| PIN_INPUT_PULLUP,

	/* SKE keypad */
	GPIO153_KP_I7,
	GPIO154_KP_I6,
	GPIO155_KP_I5,
	GPIO156_KP_I4,
	GPIO157_KP_O7,
	GPIO158_KP_O6,
	GPIO159_KP_O5,
	GPIO160_KP_O4,
	GPIO161_KP_I3,
	GPIO162_KP_I2,
	GPIO163_KP_I1,
	GPIO164_KP_I0,
	GPIO165_KP_O3,
	GPIO166_KP_O2,
	GPIO167_KP_O1,
	GPIO168_KP_O0,

	/* UART */
	/* uart-0 pins gpio configuration should be
	 * kept intact to prevent glitch in tx line
	 * when tty dev is opened. Later these pins
	 * are configured to uart mop500_pins_uart0
	 *
	 * It will be replaced with uart configuration
	 * once the issue is solved.
	 */
	GPIO0_GPIO	| PIN_INPUT_PULLUP,
	GPIO1_GPIO	| PIN_OUTPUT_HIGH,
	GPIO2_GPIO	| PIN_INPUT_PULLUP,
	GPIO3_GPIO	| PIN_OUTPUT_HIGH,

	GPIO29_U2_RXD	| PIN_INPUT_PULLUP,
	GPIO30_U2_TXD	| PIN_OUTPUT_HIGH,
	GPIO31_U2_CTSn	| PIN_INPUT_PULLUP,
	GPIO32_U2_RTSn	| PIN_OUTPUT_HIGH,

	/* Display & HDMI HW sync */
	GPIO68_LCD_VSI0	| PIN_INPUT_PULLUP,
	GPIO69_LCD_VSI1	| PIN_INPUT_PULLUP,
};

static pin_cfg_t mop500_pins_default[] = {
	/* SSP0 */
	GPIO143_SSP0_CLK,
	GPIO144_SSP0_FRM,
	GPIO145_SSP0_RXD | PIN_PULL_DOWN,
	GPIO146_SSP0_TXD,


	GPIO217_GPIO	| PIN_INPUT_PULLUP, /* TC35892 IRQ */

	/* SDI0 (MicroSD card) */
	GPIO21_MC0_DAT31DIR	| PIN_OUTPUT_HIGH,

	/* UART */
	GPIO4_U1_RXD	| PIN_INPUT_PULLUP,
	GPIO5_U1_TXD	| PIN_OUTPUT_HIGH,
	GPIO6_U1_CTSn	| PIN_INPUT_PULLUP,
	GPIO7_U1_RTSn	| PIN_OUTPUT_HIGH,
};

static pin_cfg_t mop500_pins_hrefv60[] = {
	/* WLAN */
	GPIO4_GPIO		| PIN_INPUT_PULLUP,/* WLAN_IRQ */
	GPIO85_GPIO		| PIN_OUTPUT_LOW,/* WLAN_ENA */

	/* XENON Flashgun INTERFACE */
	GPIO6_IP_GPIO0	| PIN_INPUT_PULLUP,/* XENON_FLASH_ID */
	GPIO7_IP_GPIO1	| PIN_INPUT_PULLUP,/* XENON_READY */
	GPIO170_GPIO	| PIN_OUTPUT_LOW, /* XENON_CHARGE */

	/* Assistant LED INTERFACE */
	GPIO21_GPIO | PIN_OUTPUT_LOW,  /* XENON_EN1 */
	GPIO64_IP_GPIO4 | PIN_OUTPUT_LOW,  /* XENON_EN2 */

	/* Magnetometer */
	GPIO31_GPIO | PIN_INPUT_PULLUP,  /* magnetometer_INT */
	GPIO32_GPIO | PIN_INPUT_PULLDOWN, /* Magnetometer DRDY */

	/* Display Interface */
	GPIO65_GPIO		| PIN_OUTPUT_LOW, /* DISP1 RST */
	GPIO66_GPIO		| PIN_OUTPUT_LOW, /* DISP2 RST */

	/* Touch screen INTERFACE */
	GPIO143_GPIO	| PIN_OUTPUT_LOW,/*TOUCH_RST1 */

	/* Touch screen INTERFACE 2 */
	GPIO67_GPIO	| PIN_INPUT_PULLUP, /* TOUCH_INT2 */
	GPIO146_GPIO	| PIN_OUTPUT_LOW,/*TOUCH_RST2 */

	/* ETM_PTM_TRACE INTERFACE */
	GPIO70_GPIO	| PIN_OUTPUT_LOW,/* ETM_PTM_DATA23 */
	GPIO71_GPIO	| PIN_OUTPUT_LOW,/* ETM_PTM_DATA22 */
	GPIO72_GPIO	| PIN_OUTPUT_LOW,/* ETM_PTM_DATA21 */
	GPIO73_GPIO	| PIN_OUTPUT_LOW,/* ETM_PTM_DATA20 */
	GPIO74_GPIO	| PIN_OUTPUT_LOW,/* ETM_PTM_DATA19 */

	/* NAHJ INTERFACE */
	GPIO76_GPIO	| PIN_OUTPUT_LOW,/* NAHJ_CTRL */
	GPIO216_GPIO	| PIN_OUTPUT_HIGH,/* NAHJ_CTRL_INV */

	/* NFC INTERFACE */
	GPIO77_GPIO	| PIN_OUTPUT_LOW, /* NFC_ENA */
	GPIO144_GPIO	| PIN_INPUT_PULLDOWN, /* NFC_IRQ */
	GPIO142_GPIO	| PIN_OUTPUT_LOW, /* NFC_RESET */

	/* Keyboard MATRIX INTERFACE */
	GPIO90_MC5_CMD	| PIN_OUTPUT_LOW, /* KP_O_1 */
	GPIO87_MC5_DAT1	| PIN_OUTPUT_LOW, /* KP_O_2 */
	GPIO86_MC5_DAT0	| PIN_OUTPUT_LOW, /* KP_O_3 */
	GPIO96_KP_O6	| PIN_OUTPUT_LOW, /* KP_O_6 */
	GPIO94_KP_O7	| PIN_OUTPUT_LOW, /* KP_O_7 */
	GPIO93_MC5_DAT4	| PIN_INPUT_PULLUP, /* KP_I_0 */
	GPIO89_MC5_DAT3	| PIN_INPUT_PULLUP, /* KP_I_2 */
	GPIO88_MC5_DAT2	| PIN_INPUT_PULLUP, /* KP_I_3 */
	GPIO91_GPIO	| PIN_INPUT_PULLUP, /* FORCE_SENSING_INT */
	GPIO92_GPIO	| PIN_OUTPUT_LOW, /* FORCE_SENSING_RST */
	GPIO97_GPIO	| PIN_OUTPUT_LOW, /* FORCE_SENSING_WU */

	/* DiPro Sensor Interface */
	GPIO139_GPIO	| PIN_INPUT_PULLUP, /* DIPRO_INT */

	/* HAL SWITCH INTERFACE */
	GPIO145_GPIO	| PIN_INPUT_PULLDOWN,/* HAL_SW */

	/* Audio Amplifier Interface */
	GPIO149_GPIO	| PIN_OUTPUT_LOW, /* VAUDIO_HF_EN */

	/* GBF INTERFACE */
	GPIO171_GPIO	| PIN_OUTPUT_LOW, /* GBF_ENA_RESET */

	/* MSP : HDTV INTERFACE */
	GPIO192_GPIO	| PIN_INPUT_PULLDOWN,

	/* ACCELEROMETER_INTERFACE */
	GPIO82_GPIO		| PIN_INPUT_PULLUP, /* ACC_INT1 */
	GPIO83_GPIO		| PIN_INPUT_PULLUP, /* ACC_INT2 */

	/* Proximity Sensor */
	GPIO217_GPIO		| PIN_INPUT_PULLUP,


};

static pin_cfg_t snowball_pins[] = {
	/* SSP0, to AB8500 */
	GPIO143_SSP0_CLK,
	GPIO144_SSP0_FRM,
	GPIO145_SSP0_RXD	| PIN_PULL_DOWN,
	GPIO146_SSP0_TXD,

	/* MMC0: MicroSD card */
	GPIO21_MC0_DAT31DIR     | PIN_OUTPUT_HIGH,

	/* MMC2: LAN */
	GPIO86_SM_ADQ0,
	GPIO87_SM_ADQ1,
	GPIO88_SM_ADQ2,
	GPIO89_SM_ADQ3,
	GPIO90_SM_ADQ4,
	GPIO91_SM_ADQ5,
	GPIO92_SM_ADQ6,
	GPIO93_SM_ADQ7,

	GPIO94_SM_ADVn,
	GPIO95_SM_CS0n,
	GPIO96_SM_OEn,
	GPIO97_SM_WEn,

	GPIO128_SM_CKO,
	GPIO130_SM_FBCLK,
	GPIO131_SM_ADQ8,
	GPIO132_SM_ADQ9,
	GPIO133_SM_ADQ10,
	GPIO134_SM_ADQ11,
	GPIO135_SM_ADQ12,
	GPIO136_SM_ADQ13,
	GPIO137_SM_ADQ14,
	GPIO138_SM_ADQ15,

	/* RSTn_LAN */
	GPIO141_GPIO		| PIN_OUTPUT_HIGH,
};

void __init mop500_pins_init(void)
{
	nmk_config_pins(mop500_pins_common,
				ARRAY_SIZE(mop500_pins_common));
	if (machine_is_hrefv60())
		nmk_config_pins(mop500_pins_hrefv60,
				ARRAY_SIZE(mop500_pins_hrefv60));
	else if (machine_is_snowball())
		nmk_config_pins(snowball_pins,
				ARRAY_SIZE(snowball_pins));
	else
		nmk_config_pins(mop500_pins_default,
				ARRAY_SIZE(mop500_pins_default));
}
