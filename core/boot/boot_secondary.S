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
#define ssnop sll $0, $0, 1
	.set noreorder
        .set push
        .set noat
	.text
        .globl  _start
.org 0x000
_start:
	mtc0	$zero, CP0_CAUSE
	li	$t0, 0x00400801	/* enable IRQ3 (mailbox) */
	mtc0	$t0, CP0_STATUS
	
wait:
	b	wait
	nop

got_ipi:
	la	$a0, boot_args
	li	$t0, 0xa0000000
	or	$a0, $a0, $t0	/* use uncached loads */
	lw	$t0, 0($a0)
	beqz	$t0, hang
	sll	$t0, $t0, 4

	li	$t1, 0xbfe00000	/* mailbox base */
	addu	$t1, $t1, $t0
	lw	$zero, 4($t1)	/* clear mailbox flags */
	ssnop
	ssnop

	mtc0	$zero, CP0_CAUSE /* clear IRQs */
	mfc0	$t0, CP0_STATUS
	ori	$t0, $t0, 0x1
	xori	$t0, $t0, 0x1
	mtc0	$t0, CP0_STATUS /* disable IRQs */

	lw	$t1, 4($a0)	/* kernel entry point */
	lw	$sp, 8($a0)	/* initial $sp */
	lw	$gp, 12($a0)	/* initial $gp */
	lw	$a1, 16($a0)	/* initial $a1 */

	mtc0	$t1, CP0_EPC
	ssnop
	ssnop
	eret

hang:
	b	hang
	nop


.org 0x200
tlbrefill:
	b	_start
	nop

.org 0x380
evect:
	b	got_ipi
	nop

.org 0x3c0
boot_args:
	.word	0, 0, 0, 0, 0

	.set pop
