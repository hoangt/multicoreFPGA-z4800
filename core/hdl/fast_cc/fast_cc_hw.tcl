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

# +-----------------------------------
# | request TCL package from ACDS 9.1
# | 
package require -exact sopc 9.1
# | 
# +-----------------------------------

# +-----------------------------------
# | module fast_cc
# | 
set_module_property NAME fast_cc
set_module_property VERSION 1.0
set_module_property INTERNAL false
set_module_property GROUP ""
set_module_property DISPLAY_NAME "Avalon-MM Fast Clock Crossing Bridge"
set_module_property TOP_LEVEL_HDL_FILE fast_cc.vhd
set_module_property TOP_LEVEL_HDL_MODULE fast_cc
set_module_property INSTANTIATE_IN_SYSTEM_MODULE true
set_module_property EDITABLE true
set_module_property ANALYZE_HDL TRUE
# | 
# +-----------------------------------

# +-----------------------------------
# | files
# | 
add_file fast_cc.vhd {SYNTHESIS SIMULATION}
# | 
# +-----------------------------------

# +-----------------------------------
# | parameters
# | 
add_parameter ADDRBITS NATURAL 16
set_parameter_property ADDRBITS DEFAULT_VALUE 16
set_parameter_property ADDRBITS DISPLAY_NAME ADDRBITS
set_parameter_property ADDRBITS UNITS None
set_parameter_property ADDRBITS DISPLAY_HINT ""
set_parameter_property ADDRBITS AFFECTS_GENERATION false
set_parameter_property ADDRBITS HDL_PARAMETER true
add_parameter WIDTH NATURAL 32
set_parameter_property WIDTH DEFAULT_VALUE 32
set_parameter_property WIDTH DISPLAY_NAME WIDTH
set_parameter_property WIDTH UNITS None
set_parameter_property WIDTH DISPLAY_HINT ""
set_parameter_property WIDTH AFFECTS_GENERATION false
set_parameter_property WIDTH HDL_PARAMETER true
add_parameter SMFIFO_DEPTH NATURAL 8
set_parameter_property SMFIFO_DEPTH DEFAULT_VALUE 8
set_parameter_property SMFIFO_DEPTH DISPLAY_NAME SMFIFO_DEPTH
set_parameter_property SMFIFO_DEPTH UNITS None
set_parameter_property SMFIFO_DEPTH DISPLAY_HINT ""
set_parameter_property SMFIFO_DEPTH AFFECTS_GENERATION false
set_parameter_property SMFIFO_DEPTH HDL_PARAMETER true
add_parameter MSFIFO_DEPTH NATURAL 16
set_parameter_property MSFIFO_DEPTH DEFAULT_VALUE 16
set_parameter_property MSFIFO_DEPTH DISPLAY_NAME MSFIFO_DEPTH
set_parameter_property MSFIFO_DEPTH UNITS None
set_parameter_property MSFIFO_DEPTH DISPLAY_HINT ""
set_parameter_property MSFIFO_DEPTH AFFECTS_GENERATION false
set_parameter_property MSFIFO_DEPTH HDL_PARAMETER true
add_parameter CLOCKS_SYNCHED BOOLEAN false
set_parameter_property CLOCKS_SYNCHED DEFAULT_VALUE false
set_parameter_property CLOCKS_SYNCHED DISPLAY_NAME CLOCKS_SYNCHED
set_parameter_property CLOCKS_SYNCHED UNITS None
set_parameter_property CLOCKS_SYNCHED DISPLAY_HINT ""
set_parameter_property CLOCKS_SYNCHED AFFECTS_GENERATION false
set_parameter_property CLOCKS_SYNCHED HDL_PARAMETER true
add_parameter SYNCH_STAGES INTEGER 3
set_parameter_property SYNCH_STAGES DEFAULT_VALUE 3
set_parameter_property SYNCH_STAGES DISPLAY_NAME SYNCH_STAGES
set_parameter_property SYNCH_STAGES UNITS None
set_parameter_property SYNCH_STAGES DISPLAY_HINT ""
set_parameter_property SYNCH_STAGES AFFECTS_GENERATION false
set_parameter_property SYNCH_STAGES HDL_PARAMETER true
add_parameter ENABLE_BURST BOOLEAN false
set_parameter_property ENABLE_BURST DEFAULT_VALUE false
set_parameter_property ENABLE_BURST DISPLAY_NAME ENABLE_BURST
set_parameter_property ENABLE_BURST UNITS None
set_parameter_property ENABLE_BURST DISPLAY_HINT ""
set_parameter_property ENABLE_BURST AFFECTS_GENERATION false
set_parameter_property ENABLE_BURST HDL_PARAMETER true
add_parameter BURST_BITS INTEGER 5
set_parameter_property BURST_BITS DEFAULT_VALUE 5
set_parameter_property BURST_BITS DISPLAY_NAME BURST_BITS
set_parameter_property BURST_BITS UNITS None
set_parameter_property BURST_BITS DISPLAY_HINT ""
set_parameter_property BURST_BITS AFFECTS_GENERATION false
set_parameter_property BURST_BITS HDL_PARAMETER true
add_parameter BURST_WRAP BOOLEAN false
set_parameter_property BURST_WRAP DEFAULT_VALUE false
set_parameter_property BURST_WRAP DISPLAY_NAME BURST_WRAP
set_parameter_property BURST_WRAP UNITS None
set_parameter_property BURST_WRAP DISPLAY_HINT ""
set_parameter_property BURST_WRAP AFFECTS_GENERATION false
set_parameter_property BURST_WRAP HDL_PARAMETER true
add_parameter MAP_BRIDGE BOOLEAN true
set_parameter_property MAP_BRIDGE DEFAULT_VALUE true
set_parameter_property MAP_BRIDGE DISPLAY_NAME MAP_BRIDGE
set_parameter_property MAP_BRIDGE UNITS None
set_parameter_property MAP_BRIDGE DISPLAY_HINT ""
set_parameter_property MAP_BRIDGE AFFECTS_GENERATION false
set_parameter_property MAP_BRIDGE HDL_PARAMETER false
# | 
# +-----------------------------------

# +-----------------------------------
# | display items
# | 
# | 
# +-----------------------------------

# +-----------------------------------
# | connection point slave
# | 
add_interface slave avalon end
set_interface_property slave addressAlignment DYNAMIC
set_interface_property slave associatedClock slave_clock
set_interface_property slave burstOnBurstBoundariesOnly false
set_interface_property slave explicitAddressSpan 0
set_interface_property slave holdTime 0
set_interface_property slave isMemoryDevice false
set_interface_property slave isNonVolatileStorage false
set_interface_property slave linewrapBursts false
set_interface_property slave maximumPendingReadTransactions 0
set_interface_property slave printableDevice false
set_interface_property slave readLatency 0
set_interface_property slave readWaitTime 0
set_interface_property slave setupTime 0
set_interface_property slave timingUnits Cycles
set_interface_property slave writeWaitTime 0

set_interface_property slave ASSOCIATED_CLOCK slave_clock
set_interface_property slave ENABLED true

add_interface_port slave s_wr write Input 1
add_interface_port slave s_in writedata Input width
add_interface_port slave s_out readdata Output width
add_interface_port slave s_be byteenable Input width/8
add_interface_port slave s_halt waitrequest Output 1
add_interface_port slave s_valid readdatavalid Output 1
add_interface_port slave s_rd read Input 1
add_interface_port slave s_addr address Input addrbits
# | 
# +-----------------------------------

# +-----------------------------------
# | connection point async_reset
# | 
add_interface async_reset clock end

set_interface_property async_reset ENABLED true

add_interface_port async_reset a_rst reset Input 1
# | 
# +-----------------------------------

# +-----------------------------------
# | connection point slave_clock
# | 
add_interface slave_clock clock end

set_interface_property slave_clock ENABLED true

add_interface_port slave_clock s_clk clk Input 1
# | 
# +-----------------------------------

# +-----------------------------------
# | connection point master
# | 
add_interface master avalon start
set_interface_property master associatedClock master_clock
set_interface_property master burstOnBurstBoundariesOnly false
set_interface_property master doStreamReads false
set_interface_property master doStreamWrites false
set_interface_property master linewrapBursts false

set_interface_property master ASSOCIATED_CLOCK master_clock
set_interface_property master ENABLED true

add_interface_port master m_rd read Output 1
add_interface_port master m_wr write Output 1
add_interface_port master m_in readdata Input width
add_interface_port master m_out writedata Output width
add_interface_port master m_be byteenable Output width/8
add_interface_port master m_halt waitrequest Input 1
add_interface_port master m_valid readdatavalid Input 1
add_interface_port master m_addr address Output 32
# | 
# +-----------------------------------

# +-----------------------------------
# | connection point master_clock
# | 
add_interface master_clock clock end

set_interface_property master_clock ENABLED true

add_interface_port master_clock m_clk clk Input 1
# | 
# +-----------------------------------

# dynamic interface magic
proc elaborate {} {
   set_interface_property slave maximumPendingReadTransactions [ expr [ get_parameter MSFIFO_DEPTH ] + [ get_parameter SMFIFO_DEPTH ] ]
   if { "[ get_parameter ENABLE_BURST ]" == "true" } {
      add_interface_port slave s_burstcount burstcount Input "[ get_parameter BURST_BITS ]"
      add_interface_port master m_burstcount burstcount Output "[ get_parameter BURST_BITS ]"
   }
   if { "[ get_parameter BURST_WRAP ]" == "true" } {
      set_interface_property slave linewrapBursts true
      set_interface_property master linewrapBursts true
   }
   if { "[ get_parameter MAP_BRIDGE ]" == "true" } {
      set_interface_property slave bridgesToMaster master
   }
}

set_module_property ELABORATION_CALLBACK elaborate
