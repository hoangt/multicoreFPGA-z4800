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

# +-----------------------------------
# | module pprdma
# | 
set_module_property NAME pprdma
set_module_property VERSION 1.0
set_module_property INTERNAL false
set_module_property GROUP ""
set_module_property DISPLAY_NAME "Point-to-point parallel RDMA controller"
set_module_property TOP_LEVEL_HDL_FILE pprdma.vhd
set_module_property TOP_LEVEL_HDL_MODULE pprdma
set_module_property INSTANTIATE_IN_SYSTEM_MODULE true
set_module_property EDITABLE false
set_module_property ANALYZE_HDL true
# | 
# +-----------------------------------

# +-----------------------------------
# | files
# | 
add_file pprdma.vhd {SYNTHESIS SIMULATION}
# | 
# +-----------------------------------

# +-----------------------------------
# | parameters
# | 
add_parameter SADDR_WIDTH NATURAL 28 ""
set_parameter_property SADDR_WIDTH DEFAULT_VALUE 28
set_parameter_property SADDR_WIDTH DISPLAY_NAME SADDR_WIDTH
set_parameter_property SADDR_WIDTH UNITS None
set_parameter_property SADDR_WIDTH ALLOWED_RANGES 0:2147483647
set_parameter_property SADDR_WIDTH DESCRIPTION ""
set_parameter_property SADDR_WIDTH DISPLAY_HINT ""
set_parameter_property SADDR_WIDTH AFFECTS_GENERATION false
set_parameter_property SADDR_WIDTH HDL_PARAMETER true
add_parameter PHY_WIDTH NATURAL 8
set_parameter_property PHY_WIDTH DEFAULT_VALUE 8
set_parameter_property PHY_WIDTH DISPLAY_NAME PHY_WIDTH
set_parameter_property PHY_WIDTH UNITS None
set_parameter_property PHY_WIDTH ALLOWED_RANGES 0:2147483647
set_parameter_property PHY_WIDTH DISPLAY_HINT ""
set_parameter_property PHY_WIDTH AFFECTS_GENERATION false
set_parameter_property PHY_WIDTH HDL_PARAMETER true
add_parameter LOG_WIDTH NATURAL 32 ""
set_parameter_property LOG_WIDTH DEFAULT_VALUE 32
set_parameter_property LOG_WIDTH DISPLAY_NAME LOG_WIDTH
set_parameter_property LOG_WIDTH UNITS None
set_parameter_property LOG_WIDTH ALLOWED_RANGES 0:2147483647
set_parameter_property LOG_WIDTH DESCRIPTION ""
set_parameter_property LOG_WIDTH DISPLAY_HINT ""
set_parameter_property LOG_WIDTH AFFECTS_GENERATION false
set_parameter_property LOG_WIDTH HDL_PARAMETER true
add_parameter SFIFO_DEPTH NATURAL 32 ""
set_parameter_property SFIFO_DEPTH DEFAULT_VALUE 32
set_parameter_property SFIFO_DEPTH DISPLAY_NAME SFIFO_DEPTH
set_parameter_property SFIFO_DEPTH UNITS None
set_parameter_property SFIFO_DEPTH ALLOWED_RANGES 0:2147483647
set_parameter_property SFIFO_DEPTH DESCRIPTION ""
set_parameter_property SFIFO_DEPTH DISPLAY_HINT ""
set_parameter_property SFIFO_DEPTH AFFECTS_GENERATION false
set_parameter_property SFIFO_DEPTH HDL_PARAMETER true
add_parameter TFIFO_DEPTH NATURAL 32 ""
set_parameter_property TFIFO_DEPTH DEFAULT_VALUE 32
set_parameter_property TFIFO_DEPTH DISPLAY_NAME TFIFO_DEPTH
set_parameter_property TFIFO_DEPTH UNITS None
set_parameter_property TFIFO_DEPTH ALLOWED_RANGES 0:2147483647
set_parameter_property TFIFO_DEPTH DESCRIPTION ""
set_parameter_property TFIFO_DEPTH DISPLAY_HINT ""
set_parameter_property TFIFO_DEPTH AFFECTS_GENERATION false
set_parameter_property TFIFO_DEPTH HDL_PARAMETER true
add_parameter CFIFO_DEPTH NATURAL 8
set_parameter_property CFIFO_DEPTH DEFAULT_VALUE 8
set_parameter_property CFIFO_DEPTH DISPLAY_NAME CFIFO_DEPTH
set_parameter_property CFIFO_DEPTH UNITS None
set_parameter_property CFIFO_DEPTH ALLOWED_RANGES 0:2147483647
set_parameter_property CFIFO_DEPTH DISPLAY_HINT ""
set_parameter_property CFIFO_DEPTH AFFECTS_GENERATION false
set_parameter_property CFIFO_DEPTH HDL_PARAMETER true
add_parameter READ_THRESH NATURAL 8
set_parameter_property READ_THRESH DEFAULT_VALUE 8
set_parameter_property READ_THRESH DISPLAY_NAME READ_THRESH
set_parameter_property READ_THRESH UNITS None
set_parameter_property READ_THRESH ALLOWED_RANGES 0:2147483647
set_parameter_property READ_THRESH DISPLAY_HINT ""
set_parameter_property READ_THRESH AFFECTS_GENERATION false
set_parameter_property READ_THRESH HDL_PARAMETER true
add_parameter READ_LIMIT NATURAL 16
set_parameter_property READ_LIMIT DEFAULT_VALUE 16
set_parameter_property READ_LIMIT DISPLAY_NAME READ_LIMIT
set_parameter_property READ_LIMIT UNITS None
set_parameter_property READ_LIMIT ALLOWED_RANGES 0:2147483647
set_parameter_property READ_LIMIT DISPLAY_HINT ""
set_parameter_property READ_LIMIT AFFECTS_GENERATION false
set_parameter_property READ_LIMIT HDL_PARAMETER true
add_parameter LINK_BP_THRESH NATURAL 8
set_parameter_property LINK_BP_THRESH DEFAULT_VALUE 8
set_parameter_property LINK_BP_THRESH DISPLAY_NAME LINK_BP_THRESH
set_parameter_property LINK_BP_THRESH UNITS None
set_parameter_property LINK_BP_THRESH ALLOWED_RANGES 0:2147483647
set_parameter_property LINK_BP_THRESH DISPLAY_HINT ""
set_parameter_property LINK_BP_THRESH AFFECTS_GENERATION false
set_parameter_property LINK_BP_THRESH HDL_PARAMETER true
add_parameter LINK_BP_SYNCH NATURAL 2
set_parameter_property LINK_BP_SYNCH DEFAULT_VALUE 2
set_parameter_property LINK_BP_SYNCH DISPLAY_NAME LINK_BP_SYNCH
set_parameter_property LINK_BP_SYNCH UNITS None
set_parameter_property LINK_BP_SYNCH ALLOWED_RANGES 0:2147483647
set_parameter_property LINK_BP_SYNCH DISPLAY_HINT ""
set_parameter_property LINK_BP_SYNCH AFFECTS_GENERATION false
set_parameter_property LINK_BP_SYNCH HDL_PARAMETER true
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
add_interface_port master m_halt waitrequest Input 1
add_interface_port master m_be byteenable Output log_width/8
add_interface_port master m_out writedata Output log_width
add_interface_port master m_in readdata Input log_width
add_interface_port master m_valid readdatavalid Input 1
# | 
# +-----------------------------------

# +-----------------------------------
# | connection point io
# | 
add_interface io conduit end

set_interface_property io ENABLED true

add_interface_port io o_clk export Output 1
add_interface_port io o_data export Output phy_width
add_interface_port io o_nstb export Output 1
add_interface_port io o_sel export Output 2
add_interface_port io o_nrd export Output 1
add_interface_port io o_nwr export Output 1
add_interface_port io o_bp export Output 1
add_interface_port io i_clk export Input 1
add_interface_port io i_data export Input phy_width
add_interface_port io i_nstb export Input 1
add_interface_port io i_sel export Input 2
add_interface_port io i_nrd export Input 1
add_interface_port io i_nwr export Input 1
add_interface_port io i_bp export Input 1
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
set_interface_property slave readLatency 0
set_interface_property slave readWaitTime 0
set_interface_property slave setupTime 0
set_interface_property slave timingUnits Cycles
set_interface_property slave writeWaitTime 0

set_interface_property slave ASSOCIATED_CLOCK clock_reset
set_interface_property slave ENABLED true

add_interface_port slave s_addr address Input saddr_width
add_interface_port slave s_rd read Input 1
add_interface_port slave s_wr write Input 1
add_interface_port slave s_halt waitrequest Output 1
add_interface_port slave s_be byteenable Input log_width/8
add_interface_port slave s_out readdata Output log_width
add_interface_port slave s_in writedata Input log_width
add_interface_port slave s_valid readdatavalid Output 1
# | 
# +-----------------------------------

# dynamically adjust avalon slave's number of outstanding reads
proc elaborate {} {
   set_interface_property slave maximumPendingReadTransactions "[ get_parameter READ_LIMIT ]"
}

set_module_property ELABORATION_CALLBACK elaborate
