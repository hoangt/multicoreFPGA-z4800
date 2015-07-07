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
# | module dummy_master
# | 
set_module_property NAME dummy_master
set_module_property VERSION 1.0
set_module_property INTERNAL false
set_module_property GROUP ""
set_module_property DISPLAY_NAME "Avalon Dummy Master"
set_module_property TOP_LEVEL_HDL_FILE dummy_master.vhd
set_module_property TOP_LEVEL_HDL_MODULE dummy_master
set_module_property INSTANTIATE_IN_SYSTEM_MODULE true
set_module_property EDITABLE false
set_module_property ANALYZE_HDL true
# | 
# +-----------------------------------

# +-----------------------------------
# | files
# | 
add_file dummy_master.vhd {SYNTHESIS SIMULATION}
# | 
# +-----------------------------------

# +-----------------------------------
# | parameters
# | 
add_parameter WIDTH NATURAL 32
set_parameter_property WIDTH DEFAULT_VALUE 32
set_parameter_property WIDTH DISPLAY_NAME WIDTH
set_parameter_property WIDTH UNITS None
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
# | connection point master
# | 
add_interface master avalon start
set_interface_property master associatedClock clock_reset
set_interface_property master burstOnBurstBoundariesOnly false
set_interface_property master doStreamReads false
set_interface_property master doStreamWrites false
set_interface_property master linewrapBursts false

set_interface_property master ASSOCIATED_CLOCK clock_reset
set_interface_property master ENABLED true

add_interface_port master m_addr address Output 32
add_interface_port master m_rd read Output 1
add_interface_port master m_wr write Output 1
add_interface_port master m_in readdata Input width
add_interface_port master m_out writedata Output width
add_interface_port master m_halt waitrequest Input 1
# | 
# +-----------------------------------
