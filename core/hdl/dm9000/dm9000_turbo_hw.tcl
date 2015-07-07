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
# | module dm9000_turbo
# | 
set_module_property DESCRIPTION ""
set_module_property NAME dm9000_turbo
set_module_property VERSION 1.0
set_module_property INTERNAL false
set_module_property GROUP ""
set_module_property DISPLAY_NAME "DM9000 Interface"
set_module_property TOP_LEVEL_HDL_FILE dm9000_turbo.vhd
set_module_property TOP_LEVEL_HDL_MODULE dm9000_turbo
set_module_property INSTANTIATE_IN_SYSTEM_MODULE true
set_module_property EDITABLE false
set_module_property ANALYZE_HDL true
# | 
# +-----------------------------------

# +-----------------------------------
# | files
# | 
add_file dm9000_turbo.vhd {SYNTHESIS SIMULATION}
# | 
# +-----------------------------------

# +-----------------------------------
# | parameters
# | 
add_parameter EXTRA_SETUP_WS BOOLEAN false
set_parameter_property EXTRA_SETUP_WS DEFAULT_VALUE false
set_parameter_property EXTRA_SETUP_WS DISPLAY_NAME EXTRA_SETUP_WS
set_parameter_property EXTRA_SETUP_WS UNITS None
set_parameter_property EXTRA_SETUP_WS DISPLAY_HINT ""
set_parameter_property EXTRA_SETUP_WS AFFECTS_GENERATION false
set_parameter_property EXTRA_SETUP_WS HDL_PARAMETER true
add_parameter EXTRA_READ_WS BOOLEAN false
set_parameter_property EXTRA_READ_WS DEFAULT_VALUE false
set_parameter_property EXTRA_READ_WS DISPLAY_NAME EXTRA_READ_WS
set_parameter_property EXTRA_READ_WS UNITS None
set_parameter_property EXTRA_READ_WS DISPLAY_HINT ""
set_parameter_property EXTRA_READ_WS AFFECTS_GENERATION false
set_parameter_property EXTRA_READ_WS HDL_PARAMETER true
add_parameter EXTRA_WRITE_WS BOOLEAN false
set_parameter_property EXTRA_WRITE_WS DEFAULT_VALUE false
set_parameter_property EXTRA_WRITE_WS DISPLAY_NAME EXTRA_WRITE_WS
set_parameter_property EXTRA_WRITE_WS UNITS None
set_parameter_property EXTRA_WRITE_WS DISPLAY_HINT ""
set_parameter_property EXTRA_WRITE_WS AFFECTS_GENERATION false
set_parameter_property EXTRA_WRITE_WS HDL_PARAMETER true
add_parameter EXTRA_INACTIVE_WS INTEGER 0 ""
set_parameter_property EXTRA_INACTIVE_WS DEFAULT_VALUE 0
set_parameter_property EXTRA_INACTIVE_WS DISPLAY_NAME EXTRA_INACTIVE_WS
set_parameter_property EXTRA_INACTIVE_WS UNITS None
set_parameter_property EXTRA_INACTIVE_WS ALLOWED_RANGES 0:10
set_parameter_property EXTRA_INACTIVE_WS DESCRIPTION ""
set_parameter_property EXTRA_INACTIVE_WS DISPLAY_HINT ""
set_parameter_property EXTRA_INACTIVE_WS AFFECTS_GENERATION false
set_parameter_property EXTRA_INACTIVE_WS HDL_PARAMETER true
add_parameter ALWAYS_ASSERT_CS BOOLEAN false
set_parameter_property ALWAYS_ASSERT_CS DEFAULT_VALUE false
set_parameter_property ALWAYS_ASSERT_CS DISPLAY_NAME ALWAYS_ASSERT_CS
set_parameter_property ALWAYS_ASSERT_CS UNITS None
set_parameter_property ALWAYS_ASSERT_CS DISPLAY_HINT ""
set_parameter_property ALWAYS_ASSERT_CS AFFECTS_GENERATION false
set_parameter_property ALWAYS_ASSERT_CS HDL_PARAMETER true
add_parameter INT_SYNCH INTEGER 2 ""
set_parameter_property INT_SYNCH DEFAULT_VALUE 2
set_parameter_property INT_SYNCH DISPLAY_NAME INT_SYNCH
set_parameter_property INT_SYNCH UNITS None
set_parameter_property INT_SYNCH ALLOWED_RANGES 0:5
set_parameter_property INT_SYNCH DESCRIPTION ""
set_parameter_property INT_SYNCH DISPLAY_HINT ""
set_parameter_property INT_SYNCH AFFECTS_GENERATION false
set_parameter_property INT_SYNCH HDL_PARAMETER true
add_parameter KICK_DEAD_HORSE BOOLEAN false
set_parameter_property KICK_DEAD_HORSE DEFAULT_VALUE false
set_parameter_property KICK_DEAD_HORSE DISPLAY_NAME KICK_DEAD_HORSE
set_parameter_property KICK_DEAD_HORSE UNITS None
set_parameter_property KICK_DEAD_HORSE DISPLAY_HINT ""
set_parameter_property KICK_DEAD_HORSE AFFECTS_GENERATION false
set_parameter_property KICK_DEAD_HORSE HDL_PARAMETER true
add_parameter KICK_DEAD_CYCLES INTEGER 25000000 ""
set_parameter_property KICK_DEAD_CYCLES DEFAULT_VALUE 25000000
set_parameter_property KICK_DEAD_CYCLES DISPLAY_NAME KICK_DEAD_CYCLES
set_parameter_property KICK_DEAD_CYCLES UNITS None
set_parameter_property KICK_DEAD_CYCLES ALLOWED_RANGES 0:2147483647
set_parameter_property KICK_DEAD_CYCLES DESCRIPTION ""
set_parameter_property KICK_DEAD_CYCLES DISPLAY_HINT ""
set_parameter_property KICK_DEAD_CYCLES AFFECTS_GENERATION false
set_parameter_property INT_SYNCH HDL_PARAMETER true
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
set_interface_property slave associatedClock clock
set_interface_property slave burstOnBurstBoundariesOnly false
set_interface_property slave explicitAddressSpan 0
set_interface_property slave holdTime 0
set_interface_property slave isMemoryDevice false
set_interface_property slave isNonVolatileStorage false
set_interface_property slave linewrapBursts false
set_interface_property slave maximumPendingReadTransactions 1
set_interface_property slave printableDevice false
set_interface_property slave readLatency 0
set_interface_property slave readWaitTime 0
set_interface_property slave setupTime 0
set_interface_property slave timingUnits Cycles
set_interface_property slave writeWaitTime 0

set_interface_property slave ASSOCIATED_CLOCK clock
set_interface_property slave ENABLED true

add_interface_port slave s_wr write Input 1
add_interface_port slave s_in writedata Input 32
add_interface_port slave s_out readdata Output 32
add_interface_port slave s_halt waitrequest Output 1
add_interface_port slave s_addr address Input 1
add_interface_port slave s_rd read Input 1
add_interface_port slave s_valid readdatavalid Output 1
# | 
# +-----------------------------------

# +-----------------------------------
# | connection point clock
# | 
add_interface clock clock end

set_interface_property clock ENABLED true

add_interface_port clock sysclk clk Input 1
add_interface_port clock rst reset Input 1
# | 
# +-----------------------------------

# +-----------------------------------
# | connection point export
# | 
add_interface export conduit end

set_interface_property export ENABLED true

add_interface_port export clk50 export Input 1
add_interface_port export rst50 export Input 1
add_interface_port export enet_clk export Output 1
add_interface_port export enet_cmd export Output 1
add_interface_port export enet_cs_n export Output 1
add_interface_port export enet_data export Bidir 16
add_interface_port export enet_int export Input 1
add_interface_port export enet_rd_n export Output 1
add_interface_port export enet_rst_n export Output 1
add_interface_port export enet_wr_n export Output 1
add_interface_port export on_crack export Output 1
# | 
# +-----------------------------------

# +-----------------------------------
# | connection point interrupt_sender
# | 
add_interface interrupt_sender interrupt end
set_interface_property interrupt_sender associatedAddressablePoint slave

set_interface_property interrupt_sender ASSOCIATED_CLOCK clock
set_interface_property interrupt_sender ENABLED true

add_interface_port interrupt_sender s_int irq Output 1
# | 
# +-----------------------------------
