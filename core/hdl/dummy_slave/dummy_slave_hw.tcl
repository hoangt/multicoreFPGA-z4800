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
# | module dummy_slave
# | 
set_module_property NAME dummy_slave
set_module_property VERSION 1.0
set_module_property INTERNAL false
set_module_property GROUP ""
set_module_property DISPLAY_NAME "Avalon Dummy Slave"
set_module_property TOP_LEVEL_HDL_FILE dummy_slave.vhd
set_module_property TOP_LEVEL_HDL_MODULE dummy_slave
set_module_property INSTANTIATE_IN_SYSTEM_MODULE true
set_module_property EDITABLE false
set_module_property ANALYZE_HDL true
# | 
# +-----------------------------------

# +-----------------------------------
# | files
# | 
add_file dummy_slave.vhd {SYNTHESIS SIMULATION}
# | 
# +-----------------------------------

# +-----------------------------------
# | parameters
# | 
add_parameter ADDRWIDTH NATURAL 6
set_parameter_property ADDRWIDTH DEFAULT_VALUE 6
set_parameter_property ADDRWIDTH DISPLAY_NAME ADDRWIDTH
set_parameter_property ADDRWIDTH UNITS None
set_parameter_property ADDRWIDTH ALLOWED_RANGES 0:2147483647
set_parameter_property ADDRWIDTH DISPLAY_HINT ""
set_parameter_property ADDRWIDTH AFFECTS_GENERATION false
set_parameter_property ADDRWIDTH HDL_PARAMETER true
add_parameter WIDTH NATURAL 32
set_parameter_property WIDTH DEFAULT_VALUE 32
set_parameter_property WIDTH DISPLAY_NAME WIDTH
set_parameter_property WIDTH UNITS None
set_parameter_property WIDTH ALLOWED_RANGES 0:2147483647
set_parameter_property WIDTH DISPLAY_HINT ""
set_parameter_property WIDTH AFFECTS_GENERATION false
set_parameter_property WIDTH HDL_PARAMETER true
# | 
# +-----------------------------------

# +-----------------------------------
# | display items
# | 
# | 
# +-----------------------------------

# +-----------------------------------
# | connection point clock_reset
# | 
add_interface clock_reset clock end

set_interface_property clock_reset ENABLED true

add_interface_port clock_reset clk clk Input 1
add_interface_port clock_reset rst reset Input 1
# | 
# +-----------------------------------

# +-----------------------------------
# | connection point slave
# | 
add_interface slave avalon end
set_interface_property slave addressAlignment DYNAMIC
set_interface_property slave associatedClock clock_reset
set_interface_property slave burstOnBurstBoundariesOnly false
set_interface_property slave explicitAddressSpan 0
set_interface_property slave holdTime 0
set_interface_property slave isMemoryDevice false
set_interface_property slave isNonVolatileStorage false
set_interface_property slave linewrapBursts false
set_interface_property slave maximumPendingReadTransactions 0
set_interface_property slave printableDevice false
set_interface_property slave readLatency 1
set_interface_property slave readWaitStates 0
set_interface_property slave readWaitTime 0
set_interface_property slave setupTime 0
set_interface_property slave timingUnits Cycles
set_interface_property slave writeWaitTime 0

set_interface_property slave ASSOCIATED_CLOCK clock_reset
set_interface_property slave ENABLED true

add_interface_port slave s_rd read Input 1
add_interface_port slave s_wr write Input 1
add_interface_port slave s_be byteenable Input width/8
add_interface_port slave s_in writedata Input width
add_interface_port slave s_out readdata Output width
add_interface_port slave s_addr address Input 32
# | 
# +-----------------------------------
