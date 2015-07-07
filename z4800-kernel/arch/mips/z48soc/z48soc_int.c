/*
 * Copyright (C) 1999, 2005 MIPS Technologies, Inc.  All rights reserved.
 *
 *  This program is free software; you can distribute it and/or modify it
 *  under the terms of the GNU General Public License (Version 2) as
 *  published by the Free Software Foundation.
 *
 *  This program is distributed in the hope it will be useful, but WITHOUT
 *  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 *  FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
 *  for more details.
 *
 *  You should have received a copy of the GNU General Public License along
 *  with this program; if not, write to the Free Software Foundation, Inc.,
 *  59 Temple Place - Suite 330, Boston MA 02111-1307, USA.
 *
 */
#include <linux/init.h>
#include <linux/sched.h>
#include <linux/slab.h>
#include <linux/interrupt.h>
#include <linux/kernel_stat.h>
#include <asm/mips-boards/simint.h>
#include <asm/irq_cpu.h>

#define CASCADE_IRQ 4
#define CASCADE_IRQ_BASE 32
#define CASCADE_IRQ_COUNT 32

/* ugly but will have to do for now */
static __iomem int *irq_slave = (__iomem int *)0xbfff0000;
static int cascade_mask = 0;

static DEFINE_RAW_SPINLOCK(z48_cascade_lock);

static inline int irq_ffs(unsigned int pending)
{
	pending &= 0xff00;
	if(pending & 0x0100) return 0;
	if(pending & 0x0200) return 1;
	if(pending & 0x0400) return 2;
	if(pending & 0x0800) return 3;
	if(pending & 0x1000) return 4;
	if(pending & 0x2000) return 5;
	if(pending & 0x4000) return 6;
	if(pending & 0x8000) return 7;
	return -1;
}

asmlinkage void plat_irq_dispatch(void)
{
#if MIPS_CPU_IRQ_BASE != 0
#error MIPS_CPU_IRQ_BASE broken
#endif
	unsigned int pending = read_c0_cause() & read_c0_status() & ST0_IM;
	int cascade;
	int irq;
	int i;
	int cpu;

	irq = irq_ffs(pending);
	if(irq == CASCADE_IRQ){
		cpu = raw_smp_processor_id();
		cascade = readl(&irq_slave[cpu]);
		for(i = 0;i < CASCADE_IRQ_COUNT;i++){
			if(cascade & (1 << i)){
				do_IRQ(CASCADE_IRQ_BASE + i);
			}
		}
	}
	else if(irq >= 0) do_IRQ(MIPS_CPU_IRQ_BASE + irq);
	else spurious_interrupt();
}

static void enable_cascade_irq(struct irq_data *d)
{
	unsigned long flags;
	BUG_ON(d->irq < CASCADE_IRQ_BASE);

	raw_spin_lock_irqsave(&z48_cascade_lock, flags);
	cascade_mask |= 1 << (d->irq - CASCADE_IRQ_BASE);
	writel(cascade_mask, irq_slave);
	(void)readl(irq_slave);

	if(unlikely(!(read_c0_status() & STATUSF_IP4))){
		printk(KERN_ERR "enable_cascade_irq: IP4 disabled!\n");
		BUG();
	}
	raw_spin_unlock_irqrestore(&z48_cascade_lock, flags);
}

static void disable_cascade_irq(struct irq_data *d)
{
	unsigned long flags;
	BUG_ON(d->irq < CASCADE_IRQ_BASE);

	raw_spin_lock_irqsave(&z48_cascade_lock, flags);
	cascade_mask &= ~(1 << (d->irq - CASCADE_IRQ_BASE));
	writel(cascade_mask, irq_slave);
	(void)readl(irq_slave);

	if(unlikely(!(read_c0_status() & STATUSF_IP4))){
		printk(KERN_ERR "disable_cascade_irq: IP4 disabled!\n");
		BUG();
	}
	raw_spin_unlock_irqrestore(&z48_cascade_lock, flags);
}

static struct irq_chip z48_cascade_irq_type = {
   .name				= "Z4800 cascade",
   .irq_mask		= disable_cascade_irq,
   .irq_unmask		= enable_cascade_irq,
};

static struct irqaction cascade_irqaction = {
   .handler    = no_action,
   .name       = "cascade",
};

#ifdef CONFIG_SMP
irqreturn_t z48soc_mailbox_interrupt(int irq, void *dev_id);
static struct irqaction mailbox_irqaction = {
	.handler    = z48soc_mailbox_interrupt,
	.flags      = IRQF_PERCPU,
	.name       = "mailbox",
};
#endif

void __init arch_init_irq(void)
{
   int i;

   /* reset cascade iqa registers */
	writel(cascade_mask, irq_slave);
	if(unlikely(readl(irq_slave) != 0)) BUG();

   /* set up cop0 IRQ stuff first */
	mips_cpu_irq_init();

   /* wire up individual cascade IRQ handlers */
   for(i = 0;i < CASCADE_IRQ_COUNT;i++){
      irq_set_chip_and_handler(CASCADE_IRQ_BASE + i, &z48_cascade_irq_type, handle_level_irq);
   }

   /* enable top level iqa interrupt in cop0 */
	setup_irq(CASCADE_IRQ, &cascade_irqaction);

#ifdef CONFIG_SMP
	setup_irq(3, &mailbox_irqaction);
#endif
}
