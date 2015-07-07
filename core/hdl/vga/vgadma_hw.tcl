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
# | module vgadma
# | 
set_module_property NAME vgadma
set_module_property VERSION 1.0
set_module_property INTERNAL false
set_module_property GROUP ""
set_module_property DISPLAY_NAME "VGA DMA controller"
set_module_property TOP_LEVEL_HDL_FILE vgadma.vhd
set_module_property TOP_LEVEL_HDL_MODULE vgadma
set_module_property INSTANTIATE_IN_SYSTEM_MODULE true
set_module_property EDITABLE false
set_module_property ANALYZE_HDL true
# | 
# +-----------------------------------

# +-----------------------------------
# | files
# | 
add_file vgadma.vhd {SYNTHESIS SIMULATION}
# | 
# +-----------------------------------

# +-----------------------------------
# | parameters
# | 
add_parameter HDISP NATURAL 1024
set_parameter_property HDISP DEFAULT_VALUE 1024
set_parameter_property HDISP DISPLAY_NAME HDISP
set_parameter_property HDISP UNITS None
set_parameter_property HDISP ALLOWED_RANGES 0:2147483647
set_parameter_property HDISP DISPLAY_HINT ""
set_parameter_property HDISP AFFECTS_GENERATION false
set_parameter_property HDISP HDL_PARAMETER true
add_parameter HSYNCSTART NATURAL 1056
set_parameter_property HSYNCSTART DEFAULT_VALUE 1056
set_parameter_property HSYNCSTART DISPLAY_NAME HSYNCSTART
set_parameter_property HSYNCSTART UNITS None
set_parameter_property HSYNCSTART ALLOWED_RANGES 0:2147483647
set_parameter_property HSYNCSTART DISPLAY_HINT ""
set_parameter_property HSYNCSTART AFFECTS_GENERATION false
set_parameter_property HSYNCSTART HDL_PARAMETER true
add_parameter HSYNCEND NATURAL 1296
set_parameter_property HSYNCEND DEFAULT_VALUE 1296
set_parameter_property HSYNCEND DISPLAY_NAME HSYNCEND
set_parameter_property HSYNCEND UNITS None
set_parameter_property HSYNCEND ALLOWED_RANGES 0:2147483647
set_parameter_property HSYNCEND DISPLAY_HINT ""
set_parameter_property HSYNCEND AFFECTS_GENERATION false
set_parameter_property HSYNCEND HDL_PARAMETER true
add_parameter HTOTAL NATURAL 1328
set_parameter_property HTOTAL DEFAULT_VALUE 1328
set_parameter_property HTOTAL DISPLAY_NAME HTOTAL
set_parameter_property HTOTAL UNITS None
set_parameter_property HTOTAL ALLOWED_RANGES 0:2147483647
set_parameter_property HTOTAL DISPLAY_HINT ""
set_parameter_property HTOTAL AFFECTS_GENERATION false
set_parameter_property HTOTAL HDL_PARAMETER true
add_parameter VDISP NATURAL 768
set_parameter_property VDISP DEFAULT_VALUE 768
set_parameter_property VDISP DISPLAY_NAME VDISP
set_parameter_property VDISP UNITS None
set_parameter_property VDISP ALLOWED_RANGES 0:2147483647
set_parameter_property VDISP DISPLAY_HINT ""
set_parameter_property VDISP AFFECTS_GENERATION false
set_parameter_property VDISP HDL_PARAMETER true
add_parameter VSYNCSTART NATURAL 783
set_parameter_property VSYNCSTART DEFAULT_VALUE 783
set_parameter_property VSYNCSTART DISPLAY_NAME VSYNCSTART
set_parameter_property VSYNCSTART UNITS None
set_parameter_property VSYNCSTART ALLOWED_RANGES 0:2147483647
set_parameter_property VSYNCSTART DISPLAY_HINT ""
set_parameter_property VSYNCSTART AFFECTS_GENERATION false
set_parameter_property VSYNCSTART HDL_PARAMETER true
add_parameter VSYNCEND NATURAL 791
set_parameter_property VSYNCEND DEFAULT_VALUE 791
set_parameter_property VSYNCEND DISPLAY_NAME VSYNCEND
set_parameter_property VSYNCEND UNITS None
set_parameter_property VSYNCEND ALLOWED_RANGES 0:2147483647
set_parameter_property VSYNCEND DISPLAY_HINT ""
set_parameter_property VSYNCEND AFFECTS_GENERATION false
set_parameter_property VSYNCEND HDL_PARAMETER true
add_parameter VTOTAL NATURAL 807
set_parameter_property VTOTAL DEFAULT_VALUE 807
set_parameter_property VTOTAL DISPLAY_NAME VTOTAL
set_parameter_property VTOTAL UNITS None
set_parameter_property VTOTAL ALLOWED_RANGES 0:2147483647
set_parameter_property VTOTAL DISPLAY_HINT ""
set_parameter_property VTOTAL AFFECTS_GENERATION false
set_parameter_property VTOTAL HDL_PARAMETER true
add_parameter HSYNC_ACT_HIGH BOOLEAN false
set_parameter_property HSYNC_ACT_HIGH DEFAULT_VALUE false
set_parameter_property HSYNC_ACT_HIGH DISPLAY_NAME HSYNC_ACT_HIGH
set_parameter_property HSYNC_ACT_HIGH UNITS None
set_parameter_property HSYNC_ACT_HIGH DISPLAY_HINT ""
set_parameter_property HSYNC_ACT_HIGH AFFECTS_GENERATION false
set_parameter_property HSYNC_ACT_HIGH HDL_PARAMETER true
add_parameter VSYNC_ACT_HIGH BOOLEAN false
set_parameter_property VSYNC_ACT_HIGH DEFAULT_VALUE false
set_parameter_property VSYNC_ACT_HIGH DISPLAY_NAME VSYNC_ACT_HIGH
set_parameter_property VSYNC_ACT_HIGH UNITS None
set_parameter_property VSYNC_ACT_HIGH DISPLAY_HINT ""
set_parameter_property VSYNC_ACT_HIGH AFFECTS_GENERATION false
set_parameter_property VSYNC_ACT_HIGH HDL_PARAMETER true
add_parameter BLANK_ACT_HIGH BOOLEAN false
set_parameter_property BLANK_ACT_HIGH DEFAULT_VALUE false
set_parameter_property BLANK_ACT_HIGH DISPLAY_NAME BLANK_ACT_HIGH
set_parameter_property BLANK_ACT_HIGH UNITS None
set_parameter_property BLANK_ACT_HIGH DISPLAY_HINT ""
set_parameter_property BLANK_ACT_HIGH AFFECTS_GENERATION false
set_parameter_property BLANK_ACT_HIGH HDL_PARAMETER true
add_parameter MASTER_WIDTH NATURAL 32
set_parameter_property MASTER_WIDTH DEFAULT_VALUE 32
set_parameter_property MASTER_WIDTH DISPLAY_NAME MASTER_WIDTH
set_parameter_property MASTER_WIDTH UNITS None
set_parameter_property MASTER_WIDTH ALLOWED_RANGES 0:2147483647
set_parameter_property MASTER_WIDTH DISPLAY_HINT ""
set_parameter_property MASTER_WIDTH AFFECTS_GENERATION false
set_parameter_property MASTER_WIDTH HDL_PARAMETER true
add_parameter PBITS NATURAL 0
set_parameter_property PBITS DEFAULT_VALUE 0
set_parameter_property PBITS DISPLAY_NAME PBITS
set_parameter_property PBITS UNITS None
set_parameter_property PBITS ALLOWED_RANGES 0:2147483647
set_parameter_property PBITS DISPLAY_HINT ""
set_parameter_property PBITS AFFECTS_GENERATION false
set_parameter_property PBITS HDL_PARAMETER true
add_parameter RBITS NATURAL 5
set_parameter_property RBITS DEFAULT_VALUE 5
set_parameter_property RBITS DISPLAY_NAME RBITS
set_parameter_property RBITS UNITS None
set_parameter_property RBITS ALLOWED_RANGES 0:2147483647
set_parameter_property RBITS DISPLAY_HINT ""
set_parameter_property RBITS AFFECTS_GENERATION false
set_parameter_property RBITS HDL_PARAMETER true
add_parameter GBITS NATURAL 6
set_parameter_property GBITS DEFAULT_VALUE 6
set_parameter_property GBITS DISPLAY_NAME GBITS
set_parameter_property GBITS UNITS None
set_parameter_property GBITS ALLOWED_RANGES 0:2147483647
set_parameter_property GBITS DISPLAY_HINT ""
set_parameter_property GBITS AFFECTS_GENERATION false
set_parameter_property GBITS HDL_PARAMETER true
add_parameter BBITS NATURAL 5
set_parameter_property BBITS DEFAULT_VALUE 5
set_parameter_property BBITS DISPLAY_NAME BBITS
set_parameter_property BBITS UNITS None
set_parameter_property BBITS ALLOWED_RANGES 0:2147483647
set_parameter_property BBITS DISPLAY_HINT ""
set_parameter_property BBITS AFFECTS_GENERATION false
set_parameter_property BBITS HDL_PARAMETER true
add_parameter FIFO_DEPTH NATURAL 128
set_parameter_property FIFO_DEPTH DEFAULT_VALUE 128
set_parameter_property FIFO_DEPTH DISPLAY_NAME FIFO_DEPTH
set_parameter_property FIFO_DEPTH UNITS None
set_parameter_property FIFO_DEPTH ALLOWED_RANGES 0:2147483647
set_parameter_property FIFO_DEPTH DISPLAY_HINT ""
set_parameter_property FIFO_DEPTH AFFECTS_GENERATION false
set_parameter_property FIFO_DEPTH HDL_PARAMETER true
add_parameter FIFO_FILL_START NATURAL 64
set_parameter_property FIFO_FILL_START DEFAULT_VALUE 64
set_parameter_property FIFO_FILL_START DISPLAY_NAME FIFO_FILL_START
set_parameter_property FIFO_FILL_START UNITS None
set_parameter_property FIFO_FILL_START ALLOWED_RANGES 0:2147483647
set_parameter_property FIFO_FILL_START DISPLAY_HINT ""
set_parameter_property FIFO_FILL_START AFFECTS_GENERATION false
set_parameter_property FIFO_FILL_START HDL_PARAMETER true
add_parameter BURST_BITS NATURAL 4
set_parameter_property BURST_BITS DEFAULT_VALUE 4
set_parameter_property BURST_BITS DISPLAY_NAME BURST_BITS
set_parameter_property BURST_BITS UNITS None
set_parameter_property BURST_BITS ALLOWED_RANGES 0:2147483647
set_parameter_property BURST_BITS DISPLAY_HINT ""
set_parameter_property BURST_BITS AFFECTS_GENERATION false
set_parameter_property BURST_BITS HDL_PARAMETER true
# | 
# +-----------------------------------

# +-----------------------------------
# | display items
# | 
# | 
# +-----------------------------------

# +-----------------------------------
# | connection point sclk
# | 
add_interface sclk clock end

set_interface_property sclk ENABLED true

add_interface_port sclk sclk clk Input 1
add_interface_port sclk rst reset Input 1
# | 
# +-----------------------------------

# +-----------------------------------
# | connection point mclk
# | 
add_interface mclk clock end

set_interface_property mclk ENABLED true

add_interface_port mclk mclk clk Input 1
add_interface_port mclk rst reset Input 1
# | 
# +-----------------------------------

# +-----------------------------------
# | connection point control
# | 
add_interface control avalon end
set_interface_property control addressAlignment DYNAMIC
set_interface_property control associatedClock sclk
set_interface_property control burstOnBurstBoundariesOnly false
set_interface_property control explicitAddressSpan 0
set_interface_property control holdTime 0
set_interface_property control isMemoryDevice false
set_interface_property control isNonVolatileStorage false
set_interface_property control linewrapBursts false
set_interface_property control maximumPendingReadTransactions 0
set_interface_property control printableDevice false
set_interface_property control readLatency 1
set_interface_property control readWaitStates 0
set_interface_property control readWaitTime 0
set_interface_property control setupTime 0
set_interface_property control timingUnits Cycles
set_interface_property control writeWaitTime 0

set_interface_property control ASSOCIATED_CLOCK sclk
set_interface_property control ENABLED true

add_interface_port control s_rd read Input 1
add_interface_port control s_addr address Input 2
add_interface_port control s_wr write Input 1
add_interface_port control s_in writedata Input 32
add_interface_port control s_out readdata Output 32
# | 
# +-----------------------------------

# +-----------------------------------
# | connection point vga
# | 
add_interface vga conduit end

set_interface_property vga ENABLED true

add_interface_port vga pclk export Input 1
add_interface_port vga hsync export Output 1
add_interface_port vga vsync export Output 1
add_interface_port vga blank export Output 1
add_interface_port vga r export Output 10
add_interface_port vga g export Output 10
add_interface_port vga b export Output 10
# | 
# +-----------------------------------

# +-----------------------------------
# | connection point master
# | 
add_interface master avalon start
set_interface_property master associatedClock mclk
set_interface_property master burstOnBurstBoundariesOnly true
set_interface_property master alwaysBurstMaxBurst true
set_interface_property master doStreamReads false
set_interface_property master doStreamWrites false
set_interface_property master linewrapBursts false

set_interface_property master ASSOCIATED_CLOCK mclk
set_interface_property master ENABLED true

add_interface_port master m_addr address Output 32
add_interface_port master m_rd read Output 1
add_interface_port master m_valid readdatavalid Input 1
add_interface_port master m_data readdata Input master_width
add_interface_port master m_halt waitrequest Input 1
add_interface_port master m_burstcount burstcount Output burst_bits
# | 
# +-----------------------------------
