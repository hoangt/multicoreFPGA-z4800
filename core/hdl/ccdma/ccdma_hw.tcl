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

set_module_property NAME ccdma
set_module_property VERSION 1.0
set_module_property INTERNAL false
set_module_property GROUP ""
set_module_property DISPLAY_NAME "Z4800 Cache-Coherent DMA Bridge"
set_module_property TOP_LEVEL_HDL_FILE ccdma.vhd
set_module_property TOP_LEVEL_HDL_MODULE ccdma
set_module_property INSTANTIATE_IN_SYSTEM_MODULE true
set_module_property EDITABLE false
set_module_property ANALYZE_HDL true

add_file ../z4800/z48common.vhd {SYNTHESIS SIMULATION}
add_file ccdma.vhd {SYNTHESIS SIMULATION}

add_parameter WIDTH NATURAL 32 ""
add_parameter ADDR_WIDTH NATURAL 30 ""
add_parameter BLOCK_BITS NATURAL 4 ""
add_parameter MAX_READS NATURAL 16 ""

add_interface clock clock end
set_interface_property clock ENABLED true
add_interface_port clock rst reset Input 1
add_interface_port clock clock clk Input 1

add_interface snoop conduit end
set_interface_property snoop ENABLED true
add_interface_port snoop s_bus_reqn export Output 1
add_interface_port snoop s_bus_gntn export Input 1
add_interface_port snoop s_bus_r_addr_oe export Output 1
add_interface_port snoop s_bus_r_addr_out export Output 32
add_interface_port snoop s_bus_r_addr export Input 32
add_interface_port snoop s_bus_r_sharen_oe export Output 1
add_interface_port snoop s_bus_r_sharen export Input 1
add_interface_port snoop s_bus_r_excln_oe export Output 1
add_interface_port snoop s_bus_r_excln export Input 1
add_interface_port snoop s_bus_a_waitn_oe export Output 1
add_interface_port snoop s_bus_a_waitn export Input 1
add_interface_port snoop s_bus_a_ackn_oe export Output 1
add_interface_port snoop s_bus_a_ackn export Input 1
add_interface_port snoop s_bus_a_sharen_oe export Output 1
add_interface_port snoop s_bus_a_sharen export Input 1
add_interface_port snoop s_bus_a_excln_oe export Output 1
add_interface_port snoop s_bus_a_excln export Input 1

add_interface master avalon start
set_interface_property master associatedClock clock
set_interface_property master ASSOCIATED_CLOCK clock
set_interface_property master ENABLED true
add_interface_port master m_addr address Output 32
add_interface_port master m_rd read Output 1
add_interface_port master m_wr write Output 1
add_interface_port master m_halt waitrequest Input 1
add_interface_port master m_in readdata Input WIDTH
add_interface_port master m_out writedata Output WIDTH
add_interface_port master m_be byteenable Output WIDTH/8
add_interface_port master m_valid readdatavalid Input 1

add_interface slave avalon end
set_interface_property slave addressAlignment DYNAMIC
set_interface_property slave associatedClock clock
set_interface_property slave readLatency 0
set_interface_property slave readWaitStates 0
set_interface_property slave readWaitTime 0
set_interface_property slave setupTime 0
set_interface_property slave timingUnits Cycles
set_interface_property slave writeWaitTime 0
set_interface_property slave ASSOCIATED_CLOCK clock
set_interface_property slave ENABLED true
add_interface_port slave s_addr address Input ADDR_WIDTH
add_interface_port slave s_rd read Input 1
add_interface_port slave s_wr write Input 1
add_interface_port slave s_halt waitrequest Output 1
add_interface_port slave s_in writedata Input WIDTH
add_interface_port slave s_out readdata Output WIDTH
add_interface_port slave s_be byteenable Input WIDTH/8
add_interface_port slave s_valid readdatavalid Output 1

proc elaborate {} {
   set_interface_property slave maximumPendingReadTransactions "[ get_parameter MAX_READS ]"
}

set_module_property ELABORATION_CALLBACK elaborate
