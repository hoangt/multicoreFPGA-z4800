#Copyright (C) 2012 Will Simoneau <simoneau@ele.uri.edu>
#
#This program is free software; you can redistribute it and/or
#modify it under the terms of the GNU General Public License,
#version 2, as published by the Free Software Foundation.
#Other versions of the license may NOT be used without
#the written consent of the copyright holder(s).
#
#This program is distributed in the hope that it will be useful,
#but WITHOUT ANY WARRANTY; without even the implied warranty of
#MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#GNU General Public License for more details.
#
#You should have received a copy of the GNU General Public License
#along with this program; if not, write to the Free Software
#Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

package require -exact sopc 9.1

set_module_property NAME zirqrouter
set_module_property VERSION 1.0
set_module_property INTERNAL false
set_module_property GROUP ""
set_module_property DISPLAY_NAME "Z4800 IRQ Router"
set_module_property TOP_LEVEL_HDL_FILE zirqrouter.vhd
set_module_property TOP_LEVEL_HDL_MODULE zirqrouter
set_module_property INSTANTIATE_IN_SYSTEM_MODULE true
set_module_property EDITABLE false
set_module_property ANALYZE_HDL true

add_file z48common.vhd {SYNTHESIS SIMULATION}
add_file zirqrouter.vhd {SYNTHESIS SIMULATION}

add_parameter NCPUS NATURAL 1 ""

add_interface clock clock end
set_interface_property clock ENABLED true
add_interface_port clock reset reset Input 1
add_interface_port clock clock clk Input 1

add_interface slave avalon end
set_interface_property slave associatedClock clock
set_interface_property slave ASSOCIATED_CLOCK clock
set_interface_property slave addressAlignment DYNAMIC
set_interface_property slave readLatency 1
set_interface_property slave readWaitStates 0
set_interface_property slave readWaitTime 0
set_interface_property slave setupTime 0
set_interface_property slave timingUnits Cycles
set_interface_property slave writeWaitTime 0
set_interface_property slave ENABLED true
add_interface_port slave s_addr address Input
add_interface_port slave s_rd read Input 1
add_interface_port slave s_wr write Input 1
add_interface_port slave s_in writedata Input 32
add_interface_port slave s_out readdata Output 32

add_interface dummy_master avalon start
set_interface_property dummy_master associatedClock clock
set_interface_property dummy_master ASSOCIATED_CLOCK clock
set_interface_property dummy_master ENABLED true
add_interface_port dummy_master m_addr address Output 32
add_interface_port dummy_master m_rd read Output 1
add_interface_port dummy_master m_in readdata Input 32
add_interface_port dummy_master m_halt waitrequest Input 1

add_interface irqs_in interrupt start
set_interface_property irqs_in associatedAddressablePoint dummy_master
set_interface_property irqs_in irqScheme INDIVIDUAL_REQUESTS
set_interface_property irqs_in associatedClock clock
set_interface_property irqs_in ASSOCIATED_CLOCK clock
add_interface_port irqs_in irqs_in irq Input 32

add_interface irqs_out conduit end
set_interface_property irqs_out ENABLED true
add_interface_port irqs_out irqs_out export Output 32
