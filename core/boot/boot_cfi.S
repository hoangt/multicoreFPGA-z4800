/*
Copyright (C) 2012 Will Simoneau <simoneau@ele.uri.edu>

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License,
version 2, as published by the Free Software Foundation.
Other versions of the license may NOT be used without
the written consent of the copyright holder(s).

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
*/

#include "mipsregs.h"

#define CFI_BASE 0x1c000000
#define CP0_CONFIG $16

	.set noreorder
        .set push
        .set noat
	.text
        .globl  _start
_start:
	li	$k0, CFI_BASE | 0x80000000
	lw	$t1, 0($k0)	/* e_ident EI_MAG */
	li	$t2, 0x464c457f
	bne	$t1, $t2, halt
	nop
	lhu	$t1, 4($k0)	/* e_ident EI_CLASS & EI_DATA */
	li	$t2, 0x00000101
	bne	$t1, $t2, halt
	nop
	lw	$s0, 0x18($k0)	/* e_entry */
	lw	$s1, 0x1c($k0)	/* e_phoff */
	lhu	$s2, 0x2a($k0)	/* e_phentsize */
	lhu	$s3, 0x2c($k0)	/* e_phnum */
	addu	$s1, $k0, $s1	/* addr of first ph */
ph_loop:
	move	$a0, $s1
	bal	try_load_ph
	nop
	addiu	$s3, $s3, -1
	bnez	$s3, ph_loop
	addu	$s1, $s1, $s2
go:
	jr	$s0
	nop

halt:
	b	halt
	b	halt

try_load_ph:
	lw	$t0, 0($a0)	/* p_type */
	lw	$t1, 4($a0)	/* p_offset */
	li	$t2, 1		/* PT_LOAD */
	bne	$t0, $t2, skip_ph
	lw	$t2, 8($a0)	/* p_vaddr */
	lw	$t3, 16($a0)	/* p_filesz */
	lw	$t4, 20($a0)	/* p_memsz */
	addu	$t5, $k0, $t1	/* start of data */
load_ph:
	beqz	$t3, load_ph_done
	lb	$t6, 0($t5)
	addiu	$t2, $t2, 1
	addiu	$t3, $t3, -1
	addiu	$t5, $t5, 1
	b	load_ph
	sb	$t6, -1($t2)
load_ph_done:
	subu	$t4, $t4, $t3
zero_ph:
	beqz	$t4, zero_ph_done
	sb	$zero, 0($t2)
	addiu	$t2, $t2, 1
	b	zero_ph
	addiu	$t4, $t4, -1
zero_ph_done:
flush_dcache:
	lw	$t2, 8($a0)	/* p_vaddr */
	lw	$t4, 20($a0)	/* p_memsz */
	mfc0	$t0, CP0_CONFIG
	andi	$t0, $t0, 0x1f	/* DCACHE_BLOCKBITS */
	li	$t1, 4
	sllv	$t1, $t1, $t0	/* Dcache line size in bytes */
flush_dcache_loop:
	cache	0x19, 0($t2)	/* hit writeback D */
	subu	$t4, $t4, $t1
	bgtz	$t4, flush_dcache_loop
	addu	$t2, $t2, $t1
	sync
inv_icache:
	lw	$t2, 8($a0)	/* p_vaddr */
	lw	$t4, 20($a0)	/* p_memsz */
	mfc0	$t0, CP0_CONFIG
	srl	$t0, $t0, 13
	andi	$t0, $t0, 0x1f	/* ICACHE_BLOCKBITS */
	li	$t1, 8
	sllv	$t1, $t1, $t0	/* Icache line size in bytes */
inv_icache_loop:
	cache	0x10, 0($t2)	/* hit invalidate I */
	subu	$t4, $t4, $t1
	bgtz	$t4, inv_icache_loop
	addu	$t2, $t2, $t1
skip_ph:
	jr	$ra
	nop

        .set pop
