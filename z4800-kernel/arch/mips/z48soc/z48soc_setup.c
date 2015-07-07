/*
 * Copyright (C) 2005 MIPS Technologies, Inc.  All rights reserved.
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
#include <linux/string.h>
#include <linux/kernel.h>
#include <linux/io.h>

#include <asm/cpu.h>
#include <asm/bootinfo.h>
#include <asm/mips-boards/generic.h>
#include <asm/mips-boards/prom.h>
#include <asm/time.h>

unsigned int _isbonito;

const char *get_system_type(void)
{
	return "Z4800 SOC";
}

void __init plat_mem_setup(void)
{
	set_io_port_base(KSEG1);

	pr_info("Linux started...\n");
}

extern struct plat_smp_ops z48soc_smp_ops;

void __init prom_init(void)
{
	set_io_port_base(KSEG1);

	pr_info("\nLINUX started...\n");
	prom_init_cmdline();
	prom_meminit();

#ifdef CONFIG_SMP
	register_smp_ops(&z48soc_smp_ops);
#endif
}
