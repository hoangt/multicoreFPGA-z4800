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
# | module ecache
# | 
set_module_property NAME ecache
set_module_property VERSION 1.0
set_module_property INTERNAL false
set_module_property GROUP ""
set_module_property DISPLAY_NAME "External Cache Controller"
set_module_property TOP_LEVEL_HDL_FILE ecache.vhd
set_module_property TOP_LEVEL_HDL_MODULE ecache
set_module_property INSTANTIATE_IN_SYSTEM_MODULE true
set_module_property EDITABLE false
set_module_property ANALYZE_HDL true
# | 
# +-----------------------------------

# +-----------------------------------
# | files
# | 
add_file z48common.vhd {SYNTHESIS SIMULATION}
add_file fifo.vhd {SYNTHESIS SIMULATION}
add_file l1_replace.vhd {SYNTHESIS SIMULATION}
add_file l1_replace_random.vhd {SYNTHESIS SIMULATION}
add_file l1_replace_lru.vhd {SYNTHESIS SIMULATION}
add_file l1_replace_plru.vhd {SYNTHESIS SIMULATION}
add_file l1_replace_randomhybrid.vhd {SYNTHESIS SIMULATION}
add_file l2_replace_srrip.vhd {SYNTHESIS SIMULATION}
add_file ecache.vhd {SYNTHESIS SIMULATION}
add_file ramwrap.vhd {SYNTHESIS SIMULATION}
add_file perf.vhd {SYNTHESIS SIMULATION}
add_file lfsr.vhd {SYNTHESIS SIMULATION}
# | 
# +-----------------------------------

# +-----------------------------------
# | parameters
# | 
add_parameter ABITS NATURAL 23 ""
set_parameter_property ABITS DEFAULT_VALUE 23
set_parameter_property ABITS DISPLAY_NAME ABITS
set_parameter_property ABITS UNITS None
set_parameter_property ABITS ALLOWED_RANGES 0:2147483647
set_parameter_property ABITS DESCRIPTION ""
set_parameter_property ABITS DISPLAY_HINT ""
set_parameter_property ABITS AFFECTS_GENERATION false
set_parameter_property ABITS HDL_PARAMETER true
add_parameter OFFSET_BITS NATURAL 11
set_parameter_property OFFSET_BITS DEFAULT_VALUE 11
set_parameter_property OFFSET_BITS DISPLAY_NAME OFFSET_BITS
set_parameter_property OFFSET_BITS UNITS None
set_parameter_property OFFSET_BITS ALLOWED_RANGES 0:2147483647
set_parameter_property OFFSET_BITS DISPLAY_HINT ""
set_parameter_property OFFSET_BITS AFFECTS_GENERATION false
set_parameter_property OFFSET_BITS HDL_PARAMETER true
add_parameter BLOCK_BITS NATURAL 4
set_parameter_property BLOCK_BITS DEFAULT_VALUE 4
set_parameter_property BLOCK_BITS DISPLAY_NAME BLOCK_BITS
set_parameter_property BLOCK_BITS UNITS None
set_parameter_property BLOCK_BITS ALLOWED_RANGES 0:2147483647
set_parameter_property BLOCK_BITS DISPLAY_HINT ""
set_parameter_property BLOCK_BITS AFFECTS_GENERATION false
set_parameter_property BLOCK_BITS HDL_PARAMETER true
add_parameter WAYS NATURAL 8
set_parameter_property WAYS DEFAULT_VALUE 8
set_parameter_property WAYS DISPLAY_NAME WAYS
set_parameter_property WAYS UNITS None
set_parameter_property WAYS ALLOWED_RANGES 0:2147483647
set_parameter_property WAYS DISPLAY_HINT ""
set_parameter_property WAYS AFFECTS_GENERATION false
set_parameter_property WAYS HDL_PARAMETER true
add_parameter REPLACE_TYPE STRING "RANDOM"
set_parameter_property REPLACE_TYPE DEFAULT_VALUE "RANDOM"
set_parameter_property REPLACE_TYPE DISPLAY_NAME REPLACE_TYPE
set_parameter_property REPLACE_TYPE UNITS None
set_parameter_property REPLACE_TYPE DISPLAY_HINT ""
set_parameter_property REPLACE_TYPE AFFECTS_GENERATION false
set_parameter_property REPLACE_TYPE HDL_PARAMETER true
add_parameter SUB_REPLACE_TYPE STRING ""
set_parameter_property SUB_REPLACE_TYPE DEFAULT_VALUE ""
set_parameter_property SUB_REPLACE_TYPE DISPLAY_NAME SUB_REPLACE_TYPE
set_parameter_property SUB_REPLACE_TYPE UNITS None
set_parameter_property SUB_REPLACE_TYPE DISPLAY_HINT ""
set_parameter_property SUB_REPLACE_TYPE AFFECTS_GENERATION false
set_parameter_property SUB_REPLACE_TYPE HDL_PARAMETER true
add_parameter HYBRID_BLOCK_FACTOR NATURAL 2
set_parameter_property HYBRID_BLOCK_FACTOR DEFAULT_VALUE 2
set_parameter_property HYBRID_BLOCK_FACTOR DISPLAY_NAME HYBRID_BLOCK_FACTOR
set_parameter_property HYBRID_BLOCK_FACTOR UNITS None
set_parameter_property HYBRID_BLOCK_FACTOR ALLOWED_RANGES 0:2147483647
set_parameter_property HYBRID_BLOCK_FACTOR DISPLAY_HINT ""
set_parameter_property HYBRID_BLOCK_FACTOR AFFECTS_GENERATION false
set_parameter_property HYBRID_BLOCK_FACTOR HDL_PARAMETER true
add_parameter RRIP_RRPV_BITS NATURAL 2
set_parameter_property RRIP_RRPV_BITS DEFAULT_VALUE 2
set_parameter_property RRIP_RRPV_BITS DISPLAY_NAME RRIP_RRPV_BITS
set_parameter_property RRIP_RRPV_BITS UNITS None
set_parameter_property RRIP_RRPV_BITS ALLOWED_RANGES 0:2147483647
set_parameter_property RRIP_RRPV_BITS DISPLAY_HINT ""
set_parameter_property RRIP_RRPV_BITS AFFECTS_GENERATION false
set_parameter_property RRIP_RRPV_BITS HDL_PARAMETER true
add_parameter RRIP_INSERT_RRPV NATURAL 2
set_parameter_property RRIP_INSERT_RRPV DEFAULT_VALUE 2
set_parameter_property RRIP_INSERT_RRPV DISPLAY_NAME RRIP_INSERT_RRPV
set_parameter_property RRIP_INSERT_RRPV UNITS None
set_parameter_property RRIP_INSERT_RRPV ALLOWED_RANGES 0:2147483647
set_parameter_property RRIP_INSERT_RRPV DISPLAY_HINT ""
set_parameter_property RRIP_INSERT_RRPV AFFECTS_GENERATION false
set_parameter_property RRIP_INSERT_RRPV HDL_PARAMETER true
add_parameter RRIP_HIT_RRPV NATURAL 0
set_parameter_property RRIP_HIT_RRPV DEFAULT_VALUE 0
set_parameter_property RRIP_HIT_RRPV DISPLAY_NAME RRIP_HIT_RRPV
set_parameter_property RRIP_HIT_RRPV UNITS None
set_parameter_property RRIP_HIT_RRPV ALLOWED_RANGES 0:2147483647
set_parameter_property RRIP_HIT_RRPV DISPLAY_HINT ""
set_parameter_property RRIP_HIT_RRPV AFFECTS_GENERATION false
set_parameter_property RRIP_HIT_RRPV HDL_PARAMETER true
add_parameter PMFIFO_LENGTH NATURAL 4
set_parameter_property PMFIFO_LENGTH DEFAULT_VALUE 4
set_parameter_property PMFIFO_LENGTH DISPLAY_NAME PMFIFO_LENGTH
set_parameter_property PMFIFO_LENGTH UNITS None
set_parameter_property PMFIFO_LENGTH ALLOWED_RANGES 0:2147483647
set_parameter_property PMFIFO_LENGTH DISPLAY_HINT ""
set_parameter_property PMFIFO_LENGTH AFFECTS_GENERATION false
set_parameter_property PMFIFO_LENGTH HDL_PARAMETER true
add_parameter WRITE_ALLOCATE BOOLEAN true
set_parameter_property WRITE_ALLOCATE DEFAULT_VALUE true
set_parameter_property WRITE_ALLOCATE DISPLAY_NAME WRITE_ALLOCATE
set_parameter_property WRITE_ALLOCATE UNITS None
set_parameter_property WRITE_ALLOCATE DISPLAY_HINT ""
set_parameter_property WRITE_ALLOCATE AFFECTS_GENERATION false
set_parameter_property WRITE_ALLOCATE HDL_PARAMETER true
add_parameter WIDTH NATURAL 64
set_parameter_property WIDTH DEFAULT_VALUE 64
set_parameter_property WIDTH DISPLAY_NAME WIDTH
set_parameter_property WIDTH UNITS None
set_parameter_property WIDTH ALLOWED_RANGES 0:2147483647
set_parameter_property WIDTH DISPLAY_HINT ""
set_parameter_property WIDTH AFFECTS_GENERATION false
set_parameter_property WIDTH HDL_PARAMETER true
add_parameter LIMIT_OUTSTANDING_REQS BOOLEAN true ""
set_parameter_property LIMIT_OUTSTANDING_REQS DEFAULT_VALUE true
set_parameter_property LIMIT_OUTSTANDING_REQS DISPLAY_NAME LIMIT_OUTSTANDING_REQS
set_parameter_property LIMIT_OUTSTANDING_REQS UNITS None
set_parameter_property LIMIT_OUTSTANDING_REQS DESCRIPTION ""
set_parameter_property LIMIT_OUTSTANDING_REQS DISPLAY_HINT ""
set_parameter_property LIMIT_OUTSTANDING_REQS AFFECTS_GENERATION false
set_parameter_property LIMIT_OUTSTANDING_REQS HDL_PARAMETER true
add_parameter OUTSTANDING_LIMIT NATURAL 16 ""
set_parameter_property OUTSTANDING_LIMIT DEFAULT_VALUE 16
set_parameter_property OUTSTANDING_LIMIT DISPLAY_NAME OUTSTANDING_LIMIT
set_parameter_property OUTSTANDING_LIMIT UNITS None
set_parameter_property OUTSTANDING_LIMIT ALLOWED_RANGES 0:2147483647
set_parameter_property OUTSTANDING_LIMIT DESCRIPTION ""
set_parameter_property OUTSTANDING_LIMIT DISPLAY_HINT ""
set_parameter_property OUTSTANDING_LIMIT AFFECTS_GENERATION false
set_parameter_property OUTSTANDING_LIMIT HDL_PARAMETER true
add_parameter MBURST_MODE BOOLEAN false
set_parameter_property MBURST_MODE DEFAULT_VALUE false
set_parameter_property MBURST_MODE DISPLAY_NAME MBURST_MODE
set_parameter_property MBURST_MODE UNITS None
set_parameter_property MBURST_MODE DISPLAY_HINT ""
set_parameter_property MBURST_MODE AFFECTS_GENERATION false
set_parameter_property MBURST_MODE HDL_PARAMETER true
add_parameter MAX_MBURST_LENGTH NATURAL 0 ""
set_parameter_property MAX_MBURST_LENGTH DEFAULT_VALUE 0
set_parameter_property MAX_MBURST_LENGTH DISPLAY_NAME MAX_MBURST_LENGTH
set_parameter_property MAX_MBURST_LENGTH UNITS None
set_parameter_property MAX_MBURST_LENGTH ALLOWED_RANGES 0:2147483647
set_parameter_property MAX_MBURST_LENGTH DESCRIPTION ""
set_parameter_property MAX_MBURST_LENGTH DISPLAY_HINT ""
set_parameter_property MAX_MBURST_LENGTH AFFECTS_GENERATION false
set_parameter_property MAX_MBURST_LENGTH HDL_PARAMETER true
add_parameter CBURST_MODE BOOLEAN false
set_parameter_property CBURST_MODE DEFAULT_VALUE false
set_parameter_property CBURST_MODE DISPLAY_NAME CBURST_MODE
set_parameter_property CBURST_MODE UNITS None
set_parameter_property CBURST_MODE DISPLAY_HINT ""
set_parameter_property CBURST_MODE AFFECTS_GENERATION false
set_parameter_property CBURST_MODE HDL_PARAMETER true
add_parameter CBURSTBITS NATURAL 4 ""
set_parameter_property CBURSTBITS DEFAULT_VALUE 4
set_parameter_property CBURSTBITS DISPLAY_NAME CBURSTBITS
set_parameter_property CBURSTBITS UNITS None
set_parameter_property CBURSTBITS ALLOWED_RANGES 0:2147483647
set_parameter_property CBURSTBITS DESCRIPTION ""
set_parameter_property CBURSTBITS DISPLAY_HINT ""
set_parameter_property CBURSTBITS AFFECTS_GENERATION false
set_parameter_property CBURSTBITS HDL_PARAMETER true
add_parameter CBURST_WRAP BOOLEAN false
set_parameter_property CBURST_WRAP DEFAULT_VALUE false
set_parameter_property CBURST_WRAP DISPLAY_NAME CBURST_WRAP
set_parameter_property CBURST_WRAP UNITS None
set_parameter_property CBURST_WRAP DISPLAY_HINT ""
set_parameter_property CBURST_WRAP AFFECTS_GENERATION false
set_parameter_property CBURST_WRAP HDL_PARAMETER true
add_parameter ENABLE_PERF BOOLEAN false
set_parameter_property ENABLE_PERF DEFAULT_VALUE false
set_parameter_property ENABLE_PERF DISPLAY_NAME ENABLE_PERF
set_parameter_property ENABLE_PERF UNITS None
set_parameter_property ENABLE_PERF DISPLAY_HINT ""
set_parameter_property ENABLE_PERF AFFECTS_GENERATION false
set_parameter_property ENABLE_PERF HDL_PARAMETER false
# | 
# +-----------------------------------

# +-----------------------------------
# | display items
# | 
# | 
# +-----------------------------------

# +-----------------------------------
# | connection point clock
# | 
add_interface clock clock end

set_interface_property clock ENABLED true

add_interface_port clock clock clk Input 1
add_interface_port clock rst reset Input 1
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
set_interface_property slave isMemoryDevice true
set_interface_property slave isNonVolatileStorage false
set_interface_property slave linewrapBursts false
set_interface_property slave printableDevice false
set_interface_property slave readLatency 0
set_interface_property slave readWaitTime 0
set_interface_property slave setupTime 0
set_interface_property slave timingUnits Cycles
set_interface_property slave writeWaitTime 0
set_interface_property slave maximumPendingReadTransactions 0

set_interface_property slave ASSOCIATED_CLOCK clock
set_interface_property slave ENABLED true

add_interface_port slave p_out readdata Output width
add_interface_port slave p_in writedata Input width
add_interface_port slave p_rd read Input 1
add_interface_port slave p_wr write Input 1
add_interface_port slave p_valid readdatavalid Output 1
add_interface_port slave p_halt waitrequest Output 1
add_interface_port slave p_be byteenable Input width/8
add_interface_port slave p_addr address Input abits
# | 
# +-----------------------------------

# +-----------------------------------
# | connection point memory
# | 
add_interface memory avalon start
set_interface_property memory associatedClock clock
set_interface_property memory burstOnBurstBoundariesOnly false
set_interface_property memory doStreamReads false
set_interface_property memory doStreamWrites false
set_interface_property memory linewrapBursts false

set_interface_property memory ASSOCIATED_CLOCK clock
set_interface_property memory ENABLED true

add_interface_port memory m_addr address Output 32
add_interface_port memory m_out writedata Output width
add_interface_port memory m_in readdata Input width
add_interface_port memory m_rd read Output 1
add_interface_port memory m_wr write Output 1
add_interface_port memory m_valid readdatavalid Input 1
add_interface_port memory m_halt waitrequest Input 1
add_interface_port memory m_be byteenable Output width/8
# | 
# +-----------------------------------

# +-----------------------------------
# | connection point cache
# | 
add_interface cache avalon start
set_interface_property cache associatedClock clock
set_interface_property cache burstOnBurstBoundariesOnly false
set_interface_property cache doStreamReads false
set_interface_property cache doStreamWrites false
set_interface_property cache linewrapBursts false

set_interface_property cache ASSOCIATED_CLOCK clock
set_interface_property cache ENABLED true

add_interface_port cache c_addr address Output 32
add_interface_port cache c_out writedata Output width
add_interface_port cache c_in readdata Input width
add_interface_port cache c_rd read Output 1
add_interface_port cache c_wr write Output 1
add_interface_port cache c_valid readdatavalid Input 1
add_interface_port cache c_halt waitrequest Input 1
add_interface_port cache c_be byteenable Output width/8
# | 
# +-----------------------------------

# +-----------------------------------
# | connection point perf_slave
# | 
add_interface perf_slave avalon end
set_interface_property perf_slave addressAlignment NATIVE
set_interface_property perf_slave associatedClock clock
set_interface_property perf_slave burstOnBurstBoundariesOnly false
set_interface_property perf_slave explicitAddressSpan 0
set_interface_property perf_slave holdTime 0
set_interface_property perf_slave isMemoryDevice false
set_interface_property perf_slave isNonVolatileStorage false
set_interface_property perf_slave linewrapBursts false
set_interface_property perf_slave maximumPendingReadTransactions 0
set_interface_property perf_slave printableDevice false
set_interface_property perf_slave readLatency 1
set_interface_property perf_slave readWaitStates 0
set_interface_property perf_slave readWaitTime 0
set_interface_property perf_slave setupTime 0
set_interface_property perf_slave timingUnits Cycles
set_interface_property perf_slave writeWaitTime 0

set_interface_property perf_slave ASSOCIATED_CLOCK clock
set_interface_property perf_slave ENABLED true

add_interface_port perf_slave perf_addr address Input 3
add_interface_port perf_slave perf_out readdata Output 32
add_interface_port perf_slave perf_rd read Input 1
add_interface_port perf_slave perf_in writedata Input 32
add_interface_port perf_slave perf_wr write Input 1
add_interface_port perf_slave perf_be byteenable Input 4
# | 
# +-----------------------------------

# dynamically adjust avalon interface properties
proc elaborate {} {
   set_interface_property slave maximumPendingReadTransactions "[ get_parameter OUTSTANDING_LIMIT ]"
   if { "[ get_parameter MBURST_MODE ]" == "true" } {
      add_interface_port memory m_burstcount burstcount Output [ expr [ get_parameter BLOCK_BITS ] + 1 ]
   }
   if { "[ get_parameter MAX_MBURST_LENGTH ]" == "0" } {
      set_interface_property memory burstOnBurstBoundariesOnly true
   }
   if { "[ get_parameter CBURST_MODE ]" == "true" } {
      add_interface_port slave p_burstcount burstcount Input "[ get_parameter CBURSTBITS ]"
      add_interface_port cache c_burstcount burstcount Output "[ get_parameter CBURSTBITS ]"
   }
   if { "[ get_parameter CBURST_WRAP ]" == "true" } {
      set_interface_property slave linewrapBursts true
      set_interface_property cache linewrapBursts true
   }
   if { "[ get_parameter ENABLE_PERF ]" == "false" } {
      set_interface_property perf_slave ENABLED false
   }
}

set_module_property ELABORATION_CALLBACK elaborate
