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
	.set noreorder
        .set push
        .set noat
	.text
        .globl  _start
_start:
	li	$t0, 0x80002400
	jr	$t0
	nop
	.set pop
