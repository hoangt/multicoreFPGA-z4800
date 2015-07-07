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

set_time_format -unit ns -decimal_places 3

#JTAG stuff...
create_clock -period 100 -name {altera_reserved_tck} {altera_reserved_tck}
set_input_delay -clock altera_reserved_tck -clock_fall 20 [get_ports altera_reserved_tdi]
set_input_delay -clock altera_reserved_tck -clock_fall 20 [get_ports altera_reserved_tms]
set_output_delay -clock altera_reserved_tck -clock_fall 20 [get_ports altera_reserved_tdo]

#main clocks
create_clock -period 20 -name {CLOCK_50} {CLOCK_50}
create_clock -period 20 -name {CLOCK2_50} {CLOCK2_50}
create_clock -period 20 -name {CLOCK3_50} {CLOCK3_50}
create_clock -period 20 -name {GPIO[11]} {GPIO[11]}
create_clock -period 40 -name {ENETCLK_25} {ENETCLK_25}

#create_clock -period 8 -name {ENET0_RX_CLK} {ENET0_RX_CLK}
#create_clock -period 8 -name {ENET1_RX_CLK} {ENET1_RX_CLK}
create_clock -period 40 -name {ENET0_RX_CLK} {ENET0_RX_CLK}
create_clock -period 40 -name {ENET1_RX_CLK} {ENET1_RX_CLK}
create_clock -period 40 -name {ENET0_TX_CLK} {ENET0_TX_CLK}
create_clock -period 40 -name {ENET1_TX_CLK} {ENET1_TX_CLK}

derive_pll_clocks
derive_clock_uncertainty

#all clock pins should be independent
set_clock_groups -asynchronous \
   -group {altera_reserved_tck} \
   -group {CLOCK_50} \
   -group {CLOCK2_50} \
   -group {CLOCK3_50} \
   -group {GPIO[11]} \
   -group {ENETCLK_25} \
   -group {ENET0_RX_CLK} \
   -group {ENET0_TX_CLK} \
   -group {ENET1_RX_CLK} \
   -group {ENET1_TX_CLK} \
   -group { \
      sys|the_cpu_pll|the_pll|altpll_component|auto_generated|pll1|clk[0] \
      sys|the_cpu_pll|the_pll|altpll_component|auto_generated|pll1|clk[1] \
   } \
   -group { \
      sys|the_sdram_pll|the_pll|altpll_component|auto_generated|pll1|clk[0] \
      sys|the_sdram_pll|the_pll|altpll_component|auto_generated|pll1|clk[1] \
   } \
   -group { \
      sys|the_periph_pll|the_pll|altpll_component|auto_generated|pll1|clk[0] \
   } \
   -group { \
      sys|the_eth_pll|the_pll|altpll_component|auto_generated|pll1|clk[0] \
      sys|the_eth_pll|the_pll|altpll_component|auto_generated|pll1|clk[1] \
   }

#Tsu
set_max_delay -from [get_ports *] -to [get_registers *] 3

#Tco
set_max_delay -from [get_registers *] -to [get_ports *] 6
set_max_delay -to [get_ports DRAM_CLK*] 2

#Th
set_min_delay -from [get_ports *] -to [get_registers *] -1

#JTAG can be slow
set_max_delay -from [get_ports *] -to [get_clocks altera_reserved_tck] 20
set_max_delay -from [get_clocks altera_reserved_tck] -to [get_ports *] 20

#UART I/O doesn't matter
set_false_path -to [get_ports UART_TXD*]
set_false_path -from [get_ports UART_RXD*]

#VGA only cares about skew
set_max_delay -to [get_ports VGA_*] 50
set_max_skew -to [get_ports VGA_*] 5

#USB can be slow
set_max_delay -to [get_ports OTG_*] 15
set_max_delay -from [get_ports OTG_*] 15

#CFI can be slow
set_max_delay -to [get_ports FL_*] 20
set_max_delay -from [get_ports FL_*] 20

#PS/2 I/O doesn't matter
set_false_path -to [get_ports PS2_*]
set_false_path -from [get_ports PS2_*]

#pprdma stuff has different timing
set_max_delay -from [get_ports GPIO*] -to [get_registers *] 7
set_max_delay -from [get_registers *] -to [get_ports GPIO*] 7
set_min_delay -from [get_ports GPIO*] -to [get_registers *] -5
set_max_delay -to [get_ports GPIO[29]*] 3

#these I/O pins don't matter
set_false_path -from [get_ports KEY*]
set_false_path -from [get_ports SW*]
set_false_path -to [get_ports LED*]
set_false_path -to [get_ports HEX*]

set_false_path -from [get_registers rst]


#here be dragons.
#RGMII
#set_false_path -from [get_clocks *eth_pll*] -to [get_clocks *cpu_pll*]
#set_false_path -to [get_clocks *eth_pll*] -from [get_clocks *cpu_pll*]
#set ETH_MAC_CLK sys|the_eth_pll|the_pll|altpll_component|auto_generated|pll1|clk[0]
#set ETH_PHY_CLK sys|the_eth_pll|the_pll|altpll_component|auto_generated|pll1|clk[1]
#set_false_path -from [get_ports {ENET0_MDIO}]
#set_false_path -to [get_ports {ENET0_MDC ENET0_MDIO}]
#set_false_path -from [get_clocks ENET0_RX_CLK] -to [get_clocks *pll*]
#set_false_path -from [get_clocks *pll*] -to [get_clocks ENET0_RX_CLK]
#remove_input_delay {ENET0_RX*}
#set_input_delay -clock ENET0_RX_CLK -min 1.5 [get_ports {ENET0_RX_DATA[*] ENET0_RX_DV ENET0_RX_COL ENET0_RX_CRS}]
#set_input_delay -clock ENET0_RX_CLK -max 2.5 [get_ports {ENET0_RX_DATA[*] ENET0_RX_DV ENET0_RX_COL ENET0_RX_CRS}]
#set_input_delay -clock ENET0_RX_CLK -min 1.5 [get_ports {ENET0_RX_DATA[*] ENET0_RX_DV ENET0_RX_COL ENET0_RX_CRS}] -clock_fall
#set_input_delay -clock ENET0_RX_CLK -max 2.5 [get_ports {ENET0_RX_DATA[*] ENET0_RX_DV ENET0_RX_COL ENET0_RX_CRS}] -clock_fall
#remove_output_delay {ENET0_TX*}
#set_output_delay -clock $ETH_MAC_CLK -max 1 [get_ports {ENET0_TX_DATA[*] ENET0_TX_EN ENET0_TX_ER}]
#set_output_delay -clock $ETH_MAC_CLK -min -1 [get_ports {ENET0_TX_DATA[*] ENET0_TX_EN ENET0_TX_ER}]
#set_output_delay -clock $ETH_MAC_CLK -clock_fall -max 1 [get_ports {ENET0_TX_DATA[*] ENET0_TX_EN ENET0_TX_ER}]
#set_output_delay -clock $ETH_MAC_CLK -clock_fall -min -1 [get_ports {ENET0_TX_DATA[*] ENET0_TX_EN ENET0_TX_ER}]
#set_false_path -setup -rise_from $ETH_MAC_CLK -fall_to $ETH_PHY_CLK
#set_false_path -setup -fall_from $ETH_MAC_CLK -rise_to $ETH_PHY_CLK
#set_false_path -hold -rise_from $ETH_MAC_CLK -rise_to $ETH_PHY_CLK
#set_false_path -hold -fall_from $ETH_MAC_CLK -fall_to $ETH_PHY_CLK
#set_multicycle_path -from $ETH_MAC_CLK -to $ETH_PHY_CLK -setup -start 2
#set_min_delay -from $ETH_PHY_CLK -to [get_ports {ENET0_GTX_CLK}] 0
#set_max_delay -from $ETH_PHY_CLK -to [get_ports {ENET0_GTX_CLK}] 20
#set_min_delay -from $ETH_MAC_CLK -to [get_clocks {*rgmii_voodoo*|tx_clk}] 0
#set_max_delay -from $ETH_MAC_CLK -to [get_clocks {*rgmii_voodoo*|tx_clk}] 20

#MII
set_false_path -from [get_ports {ENET0_MDIO}]
set_false_path -to [get_ports {ENET0_MDC ENET0_MDIO}]
set_false_path -from [get_clocks ENET0_RX_CLK] -to [get_clocks *pll*]
set_false_path -from [get_clocks *pll*] -to [get_clocks ENET0_RX_CLK]
set_false_path -from [get_clocks ENET0_TX_CLK] -to [get_clocks *pll*]
set_false_path -from [get_clocks *pll*] -to [get_clocks ENET0_TX_CLK]
set_max_delay -from [get_ports ENET0_RX*] 20
set_max_delay -to [get_ports ENET0_TX*] 20
set_input_delay -clock ENET0_RX_CLK -min 2 [get_ports {ENET0_RX_DATA[*] ENET0_RX_DV ENET0_RX_COL ENET0_RX_CRS}] -add_delay
set_input_delay -clock ENET0_RX_CLK -max 10 [get_ports {ENET0_RX_DATA[*] ENET0_RX_DV ENET0_RX_COL ENET0_RX_CRS}] -add_delay
set_output_delay -clock ENET0_TX_CLK -min 2 [get_ports {ENET0_TX_DATA[*] ENET0_TX_EN ENET0_TX_ER}] -add_delay
set_output_delay -clock ENET0_TX_CLK -max 10 [get_ports {ENET0_TX_DATA[*] ENET0_TX_EN ENET0_TX_ER}] -add_delay

set_false_path -from [get_ports {ENET1_MDIO}]
set_false_path -to [get_ports {ENET1_MDC ENET1_MDIO}]
set_false_path -from [get_clocks ENET1_RX_CLK] -to [get_clocks *pll*]
set_false_path -from [get_clocks *pll*] -to [get_clocks ENET1_RX_CLK]
set_false_path -from [get_clocks ENET1_TX_CLK] -to [get_clocks *pll*]
set_false_path -from [get_clocks *pll*] -to [get_clocks ENET1_TX_CLK]
set_max_delay -from [get_ports ENET1_RX*] 20
set_max_delay -to [get_ports ENET1_TX*] 20
set_input_delay -clock ENET1_RX_CLK -min 2 [get_ports {ENET1_RX_DATA[*] ENET1_RX_DV ENET1_RX_COL ENET1_RX_CRS}] -add_delay
set_input_delay -clock ENET1_RX_CLK -max 10 [get_ports {ENET1_RX_DATA[*] ENET1_RX_DV ENET1_RX_COL ENET1_RX_CRS}] -add_delay
set_output_delay -clock ENET1_TX_CLK -min 2 [get_ports {ENET1_TX_DATA[*] ENET1_TX_EN ENET1_TX_ER}] -add_delay
set_output_delay -clock ENET1_TX_CLK -max 10 [get_ports {ENET1_TX_DATA[*] ENET1_TX_EN ENET1_TX_ER}] -add_delay
