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

set_module_property NAME eth_dma
set_module_property VERSION 1.0
set_module_property INTERNAL false
set_module_property GROUP ""
set_module_property DISPLAY_NAME "Ethernet Avalon-ST DMA Controller"
set_module_property TOP_LEVEL_HDL_FILE eth_dma.vhd
set_module_property TOP_LEVEL_HDL_MODULE eth_dma
set_module_property INSTANTIATE_IN_SYSTEM_MODULE true
set_module_property EDITABLE false
set_module_property ANALYZE_HDL true

add_file ../z4800/z48common.vhd {SYNTHESIS SIMULATION}
add_file eth_dma.vhd {SYNTHESIS SIMULATION}
add_file eth_align.vhd {SYNTHESIS SIMULATION}

add_parameter BUS_WIDTH NATURAL 64 ""
add_parameter RX_RING_BITS NATURAL 6 ""
add_parameter RX_ERROR_BITS NATURAL 6 ""
add_parameter TX_RING_BITS NATURAL 6 ""
add_parameter TX_ERROR_BITS NATURAL 1 ""
add_parameter TX_FIFO_DEPTH NATURAL 128 ""

add_parameter BUS_BYTES NATURAL 8 ""
set_parameter_property BUS_BYTES DERIVED true
set_parameter_property BUS_BYTES VISIBLE false
add_parameter BUS_BYTES_LOG2 NATURAL 3 ""
set_parameter_property BUS_BYTES_LOG2 DERIVED true
set_parameter_property BUS_BYTES_LOG2 VISIBLE false

add_interface clock clock end
set_interface_property clock ENABLED true
add_interface_port clock rst reset Input 1
add_interface_port clock clk clk Input 1

add_interface rx_ring avalon end
set_interface_property rx_ring associatedClock clock
set_interface_property rx_ring ASSOCIATED_CLOCK clock
set_interface_property rx_ring addressAlignment DYNAMIC
set_interface_property rx_ring readLatency 1
set_interface_property rx_ring readWaitStates 0
set_interface_property rx_ring readWaitTime 0
set_interface_property rx_ring setupTime 0
set_interface_property rx_ring timingUnits Cycles
set_interface_property rx_ring writeWaitTime 0
set_interface_property rx_ring ENABLED true
add_interface_port rx_ring rxr_addr address Input RX_RING_BITS
add_interface_port rx_ring rxr_rd read Input 1
add_interface_port rx_ring rxr_wr write Input 1
add_interface_port rx_ring rxr_in writedata Input 64
add_interface_port rx_ring rxr_out readdata Output 64
add_interface_port rx_ring rxr_be byteenable Input 8

add_interface rx_master avalon start
set_interface_property rx_master associatedClock clock
set_interface_property rx_master ASSOCIATED_CLOCK clock
set_interface_property rx_master ENABLED true
add_interface_port rx_master rxd_addr address Output 32
add_interface_port rx_master rxd_wr write Output 1
add_interface_port rx_master rxd_out writedata Output BUS_WIDTH
add_interface_port rx_master rxd_halt waitrequest Input 1

add_interface rx_stream avalon_streaming end
set_interface_property rx_stream associatedClock clock
set_interface_property rx_stream ASSOCIATED_CLOCK clock
set_interface_property rx_stream ENABLED true
set_interface_property rx_stream dataBitsPerSymbol 8
set_interface_property rx_stream errorDescriptor ""
set_interface_property rx_stream maxChannel 0
set_interface_property rx_stream readyLatency 0
add_interface_port rx_stream rxs_data data Input BUS_WIDTH
add_interface_port rx_stream rxs_empty empty Input BUS_BYTES_LOG2
add_interface_port rx_stream rxs_error error Input RX_ERROR_BITS
add_interface_port rx_stream rxs_sop startofpacket Input 1
add_interface_port rx_stream rxs_eop endofpacket Input 1
add_interface_port rx_stream rxs_valid valid Input 1
add_interface_port rx_stream rxs_ready ready Output 1

add_interface rx_irq interrupt end
set_interface_property rx_irq associatedAddressablePoint rx_ring
set_interface_property rx_irq associatedClock clock
set_interface_property rx_irq ASSOCIATED_CLOCK clock
add_interface_port rx_irq rx_irq irq Output 1



add_interface tx_ring avalon end
set_interface_property tx_ring associatedClock clock
set_interface_property tx_ring ASSOCIATED_CLOCK clock
set_interface_property tx_ring addressAlignment DYNAMIC
set_interface_property tx_ring readLatency 1
set_interface_property tx_ring readWaitStates 0
set_interface_property tx_ring readWaitTime 0
set_interface_property tx_ring setupTime 0
set_interface_property tx_ring timingUnits Cycles
set_interface_property tx_ring writeWaitTime 0
set_interface_property tx_ring ENABLED true
add_interface_port tx_ring txr_addr address Input TX_RING_BITS
add_interface_port tx_ring txr_rd read Input 1
add_interface_port tx_ring txr_wr write Input 1
add_interface_port tx_ring txr_in writedata Input 64
add_interface_port tx_ring txr_out readdata Output 64
add_interface_port tx_ring txr_be byteenable Input 8

add_interface tx_master avalon start
set_interface_property tx_master associatedClock clock
set_interface_property tx_master ASSOCIATED_CLOCK clock
set_interface_property tx_master ENABLED true
add_interface_port tx_master txd_addr address Output 32
add_interface_port tx_master txd_rd read Output 1
add_interface_port tx_master txd_in readdata Input BUS_WIDTH
add_interface_port tx_master txd_halt waitrequest Input 1
add_interface_port tx_master txd_valid readdatavalid Input 1

add_interface tx_stream avalon_streaming start
set_interface_property tx_stream associatedClock clock
set_interface_property tx_stream ASSOCIATED_CLOCK clock
set_interface_property tx_stream ENABLED true
set_interface_property tx_stream dataBitsPerSymbol 8
set_interface_property tx_stream errorDescriptor ""
set_interface_property tx_stream maxChannel 0
set_interface_property tx_stream readyLatency 0
add_interface_port tx_stream txs_data data Output BUS_WIDTH
add_interface_port tx_stream txs_empty empty Output BUS_BYTES_LOG2
add_interface_port tx_stream txs_error error Output TX_ERROR_BITS
add_interface_port tx_stream txs_sop startofpacket Output 1
add_interface_port tx_stream txs_eop endofpacket Output 1
add_interface_port tx_stream txs_valid valid Output 1
add_interface_port tx_stream txs_ready ready Input 1

add_interface tx_irq interrupt end
set_interface_property tx_irq associatedAddressablePoint tx_ring
set_interface_property tx_irq associatedClock clock
set_interface_property tx_irq ASSOCIATED_CLOCK clock
add_interface_port tx_irq tx_irq irq Output 1


add_interface csr avalon end
set_interface_property csr associatedClock clock
set_interface_property csr ASSOCIATED_CLOCK clock
set_interface_property csr addressAlignment DYNAMIC
set_interface_property csr readLatency 1
set_interface_property csr readWaitStates 0
set_interface_property csr readWaitTime 0
set_interface_property csr setupTime 0
set_interface_property csr timingUnits Cycles
set_interface_property csr writeWaitTime 0
set_interface_property csr ENABLED true
add_interface_port csr csr_addr address Input 2
add_interface_port csr csr_rd read Input 1
add_interface_port csr csr_wr write Input 1
add_interface_port csr csr_in writedata Input 32
add_interface_port csr csr_out readdata Output 32

add_interface phy_irq interrupt end
set_interface_property phy_irq associatedAddressablePoint csr
set_interface_property phy_irq associatedClock clock
set_interface_property phy_irq ASSOCIATED_CLOCK clock
add_interface_port phy_irq phy_irq irq Output 1

proc elaborate {} {
   set_parameter_value BUS_BYTES [expr {[get_parameter BUS_WIDTH] / 8}]
   set_parameter_value BUS_BYTES_LOG2 [expr {(log([get_parameter BUS_BYTES]) / log(2))}]
   set_interface_property rx_stream symbolsPerBeat [get_parameter_value BUS_BYTES]
   set_interface_property tx_stream symbolsPerBeat [get_parameter_value BUS_BYTES]
}

set_module_property ELABORATION_CALLBACK elaborate
