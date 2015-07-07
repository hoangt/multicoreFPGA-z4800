#include <linux/init.h>
#include <linux/sched.h>
#include <linux/delay.h>
#include <linux/interrupt.h>
#include <linux/smp.h>
#include <linux/kernel_stat.h>

#include <asm/mmu_context.h>
#include <asm/io.h>

#define IOADDR(x) ((void __iomem *)(KSEG1 | (x)))

#define MAILBOX_BASE 0x1fe00000
#define MAILBOX_CPU_SHIFT 4
#define MAILBOX_REG_ACLR_OFFSET 4
#define MAILBOX_SETREG_OFFSET 0
#define MAILBOX_CLRREG_OFFSET 4

#define MAILBOX_REG(cpu) IOADDR(MAILBOX_BASE + (cpu << MAILBOX_CPU_SHIFT))
#define MAILBOX_REG_ACLR(cpu) IOADDR(MAILBOX_BASE + (cpu << MAILBOX_CPU_SHIFT) + MAILBOX_REG_ACLR_OFFSET)
#define MAILBOX_SET(cpu) IOADDR(MAILBOX_BASE + (cpu << MAILBOX_CPU_SHIFT) + MAILBOX_SETREG_OFFSET)
#define MAILBOX_CLR(cpu) IOADDR(MAILBOX_BASE + (cpu << MAILBOX_CPU_SHIFT) + MAILBOX_CLRREG_OFFSET)

#define BOOTROM_BASE IOADDR(0x1ff00000)

static void z48soc_send_ipi_single(int cpu, unsigned int action)
{
	writel(action, MAILBOX_SET(cpu));
}

static inline void z48soc_send_ipi_mask(const struct cpumask *mask,
					unsigned int action)
{
	unsigned int i;

	for_each_cpu(i, mask)
		z48soc_send_ipi_single(i, action);
}

/*
 * Code to run on secondary just after probing the CPU
 */
static void __cpuinit z48soc_init_secondary(void)
{
	/* Set interrupt mask, but don't enable */
	change_c0_status(ST0_IM, STATUSF_IP7 | STATUSF_IP4 | STATUSF_IP3);
}

/*
 * Do any tidying up before marking online and running the idle
 * loop
 */
static void __cpuinit z48soc_smp_finish(void)
{
	local_irq_enable();
}

/*
 * Final cleanup after all secondaries booted
 */
static void z48soc_cpus_done(void)
{
}

/*
 * Setup the PC, SP, and GP of a secondary processor and start it
 * running!
 */
static void __cpuinit z48soc_boot_secondary(int cpu, struct task_struct *idle)
{
	unsigned long addr = (unsigned long)&smp_bootstrap;
	unsigned long sp = (unsigned long)__KSTK_TOS(idle);
	unsigned long gp = (unsigned long)task_thread_info(idle);
	unsigned long a1 = 0;

	writel(cpu, BOOTROM_BASE + 0x3c0);
	writel(addr, BOOTROM_BASE + 0x3c4);
	writel(sp, BOOTROM_BASE + 0x3c8);
	writel(gp, BOOTROM_BASE + 0x3cc);
	writel(a1, BOOTROM_BASE + 0x3d0);
	(void)readl(BOOTROM_BASE + 0x3d0);
	writel(0xffffffff, MAILBOX_SET(cpu));

	printk("Boot IPI sent to CPU%i\n", cpu);
}

static void __init z48soc_smp_setup(void)
{
	int i;

	cpus_clear(cpu_possible_map);

	for (i = 0; i < NR_CPUS; i++) {
		cpu_set(i, cpu_possible_map);
		cpu_set(i, cpu_present_map);
		__cpu_number_map[i] = i;
		__cpu_logical_map[i] = i;
	}

	printk(KERN_INFO "Z48SOC: %d CPUs\n", i);
}

static void __init z48soc_prepare_cpus(unsigned int max_cpus)
{
}

struct plat_smp_ops z48soc_smp_ops = {
	.send_ipi_single	= z48soc_send_ipi_single,
	.send_ipi_mask		= z48soc_send_ipi_mask,
	.init_secondary		= z48soc_init_secondary,
	.smp_finish		= z48soc_smp_finish,
	.cpus_done		= z48soc_cpus_done,
	.boot_secondary		= z48soc_boot_secondary,
	.smp_setup		= z48soc_smp_setup,
	.prepare_cpus		= z48soc_prepare_cpus,
};

irqreturn_t z48soc_mailbox_interrupt(int irq, void *dev_id)
{
	int cpu = smp_processor_id();
	unsigned int action;

	kstat_incr_irqs_this_cpu(irq, irq_to_desc(irq));
	action = readl(MAILBOX_REG_ACLR(cpu));

	if (action & SMP_CALL_FUNCTION)
		smp_call_function_interrupt();
	
	if (action & SMP_RESCHEDULE_YOURSELF)
		scheduler_ipi();

	return IRQ_HANDLED;
}
