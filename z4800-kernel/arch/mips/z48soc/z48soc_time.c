#include <linux/types.h>
#include <linux/init.h>
#include <linux/kernel_stat.h>
#include <linux/sched.h>
#include <linux/spinlock.h>
#include <linux/interrupt.h>
#include <linux/mc146818rtc.h>
#include <linux/smp.h>
#include <linux/timex.h>

#include <asm/hardirq.h>
#include <asm/div64.h>
#include <asm/cpu.h>
#include <asm/time.h>
#include <asm/irq.h>
#include <asm/mc146818-time.h>
#include <asm/msc01_ic.h>

#include <asm/mips-boards/generic.h>
#include <asm/mips-boards/prom.h>
#include <asm/mips-boards/simint.h>

extern long z48soc_cpu_clock_freq_khz;

unsigned long cpu_khz;

static unsigned int __init estimate_cpu_frequency(void)
{
	unsigned int count;

	count = z48soc_cpu_clock_freq_khz * 1000;

	mips_hpt_frequency = count;

	count += 5000;    /* round */
	count -= count%10000;

	return count;
}

static int mips_cpu_timer_irq;

unsigned __cpuinit get_c0_compare_int(void)
{
	mips_cpu_timer_irq = MIPS_CPU_IRQ_BASE + cp0_compare_irq;

	return mips_cpu_timer_irq;
}

void __init plat_time_init(void)
{
	unsigned int est_freq;

	est_freq = estimate_cpu_frequency();

	printk(KERN_INFO "CPU frequency %d.%02d MHz\n", est_freq / 1000000,
			(est_freq % 1000000) * 100 / 1000000);

	cpu_khz = est_freq / 1000;
}
