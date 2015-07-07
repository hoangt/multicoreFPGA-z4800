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

set_module_property DESCRIPTION ""
set_module_property NAME isp1362_hc
set_module_property VERSION 1.0
set_module_property INTERNAL false
set_module_property GROUP ""
set_module_property DISPLAY_NAME "ISP1362 USB Host"
set_module_property TOP_LEVEL_HDL_FILE isp1362_hc.vhd
set_module_property TOP_LEVEL_HDL_MODULE isp1362_hc
set_module_property INSTANTIATE_IN_SYSTEM_MODULE true
set_module_property EDITABLE false
set_module_property ANALYZE_HDL true

add_file isp1362_hc.vhd {SYNTHESIS SIMULATION}

add_interface slave avalon end
set_interface_property slave addressAlignment DYNAMIC
set_interface_property slave associatedClock clock
set_interface_property slave burstOnBurstBoundariesOnly false
set_interface_property slave explicitAddressSpan 0
set_interface_property slave isMemoryDevice false
set_interface_property slave isNonVolatileStorage false
set_interface_property slave linewrapBursts false
set_interface_property slave maximumPendingReadTransactions 0
set_interface_property slave printableDevice false
set_interface_property slave readLatency 1
set_interface_property slave timingUnits Nanoseconds
set_interface_property slave setupTime 160
set_interface_property slave holdTime 160
set_interface_property slave readWaitTime 50
set_interface_property slave readWaitStates 70
set_interface_property slave writeWaitTime 50
set_interface_property slave writeWaitStates 70
set_interface_property slave ASSOCIATED_CLOCK clock
set_interface_property slave ENABLED true
add_interface_port slave s_wr write Input 1
add_interface_port slave s_in writedata Input 32
add_interface_port slave s_out readdata Output 32
add_interface_port slave s_addr address Input 2
add_interface_port slave s_rd read Input 1
add_interface_port slave s_cs chipselect Input 1

add_interface clock clock end
set_interface_property clock ENABLED true
add_interface_port clock clk clk Input 1
add_interface_port clock rst reset Input 1

add_interface export conduit end
set_interface_property export ENABLED true
add_interface_port export pin_addr export Output 2
add_interface_port export pin_data export Bidir 16
add_interface_port export pin_cs_n export Output 1
add_interface_port export pin_rd_n export Output 1
add_interface_port export pin_wr_n export Output 1
add_interface_port export pin_rst_n export Output 1
add_interface_port export pin_int0 export Input 1

add_interface interrupt_sender interrupt end
set_interface_property interrupt_sender associatedAddressablePoint slave
set_interface_property interrupt_sender ASSOCIATED_CLOCK clock
set_interface_property interrupt_sender ENABLED true
add_interface_port interrupt_sender s_int irq Output 1
