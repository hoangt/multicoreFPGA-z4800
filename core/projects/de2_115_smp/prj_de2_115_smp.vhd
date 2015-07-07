--Copyright (C) 2012 Will Simoneau <simoneau@ele.uri.edu>
--
--This program is free software; you can redistribute it and/or
--modify it under the terms of the GNU General Public License,
--version 2, as published by the Free Software Foundation.
--Other versions of the license may NOT be used without
--the written consent of the copyright holder(s).
--
--This program is distributed in the hope that it will be useful,
--but WITHOUT ANY WARRANTY; without even the implied warranty of
--MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--GNU General Public License for more details.
--
--You should have received a copy of the GNU General Public License
--along with this program; if not, write to the Free Software
--Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
library lpm;
use lpm.lpm_components.all;
library altera_mf;
use altera_mf.altera_mf_components.all;
library z48common;
use z48common.z48common.all;

entity prj_de2_115_smp is
	port(
      CLOCK_50:                     in std_logic;
      CLOCK2_50:                    in std_logic;
      CLOCK3_50:                    in std_logic;

      DRAM_ADDR:                    out std_logic_vector(12 downto 0);
      DRAM_BA:                      out std_logic_vector(1 downto 0);
      DRAM_CAS_N:                   buffer std_logic;
      DRAM_CKE:                     out std_logic;
      DRAM_CLK:                     out std_logic;
      DRAM_CS_N:                    out std_logic;
      DRAM_DQ:                      inout std_logic_vector(31 downto 0);
      DRAM_DQM:                     inout std_logic_vector(3 downto 0);
      DRAM_RAS_N:                   buffer std_logic;
      DRAM_WE_N:                    out std_logic;
      
      GPIO:                         inout std_logic_vector(35 downto 0);

      KEY:                          in std_logic_vector(3 downto 0);

      LEDG:                         out std_logic_vector(8 downto 0);
      LEDR:                         out std_logic_vector(17 downto 0);

      ENET0_GTX_CLK:                inout std_logic;
      ENET0_INT_N:                  in std_logic;
      ENET0_LINK100:                in std_logic;
      ENET0_MDC:                    out std_logic;
      ENET0_MDIO:                   inout std_logic;
      ENET0_RST_N:                  out std_logic;
      ENET0_RX_CLK:                 in std_logic;
      ENET0_RX_COL:                 in std_logic;
      ENET0_RX_CRS:                 in std_logic;
      ENET0_RX_DATA:                in std_logic_vector(3 downto 0);
      ENET0_RX_DV:                  in std_logic;
      ENET0_RX_ER:                  in std_logic;
      ENET0_TX_CLK:                 in std_logic;
      ENET0_TX_DATA:                out std_logic_vector(3 downto 0);
      ENET0_TX_EN:                  out std_logic;
      ENET0_TX_ER:                  out std_logic;

      --ENET1_GTX_CLK:                inout std_logic;
      --ENET1_INT_N:                  in std_logic;
      --ENET1_LINK100:                in std_logic;
      --ENET1_MDC:                    out std_logic;
      --ENET1_MDIO:                   inout std_logic;
      --ENET1_RST_N:                  out std_logic;
      --ENET1_RX_CLK:                 in std_logic;
      --ENET1_RX_COL:                 in std_logic;
      --ENET1_RX_CRS:                 in std_logic;
      --ENET1_RX_DATA:                in std_logic_vector(3 downto 0);
      --ENET1_RX_DV:                  in std_logic;
      --ENET1_RX_ER:                  in std_logic;
      --ENET1_TX_CLK:                 in std_logic;
      --ENET1_TX_DATA:                out std_logic_vector(3 downto 0);
      --ENET1_TX_EN:                  out std_logic;
      --ENET1_TX_ER:                  out std_logic;

      ENETCLK_25:                   in std_logic;

      VGA_R:                        out std_logic_vector(7 downto 0);
      VGA_G:                        out std_logic_vector(7 downto 0);
      VGA_B:                        out std_logic_vector(7 downto 0);
      VGA_CLK:                      out std_logic;
      VGA_BLANK_N:                  out std_logic;
      VGA_HS:                       out std_logic;
      VGA_VS:                       out std_logic;
      VGA_SYNC_N:                   out std_logic;

      FL_ADDR:                      out std_logic_vector(22 downto 0);
      FL_DQ:                        inout std_logic_vector(7 downto 0);
      FL_WE_N:                      out std_logic;
      FL_RST_N:                     out std_logic;
      FL_WP_N:                      out std_logic;
      FL_RY:                        in std_logic;
      FL_CE_N:                      out std_logic;
      FL_OE_N:                      out std_logic;

      OTG_ADDR:                     out std_logic_vector(1 downto 0);
      OTG_DATA:                     inout std_logic_vector(15 downto 0);
      OTG_CS_N:                     out std_logic;
      OTG_RD_N:                     out std_logic;
      OTG_WR_N:                     out std_logic;
      OTG_RST_N:                    out std_logic;
      OTG_INT:                      in std_logic_vector(1 downto 0);
      OTG_DACK_N:                   out std_logic_vector(1 downto 0);
      OTG_DREQ:                     in std_logic_vector(1 downto 0);
      OTG_FSPEED:                   inout std_logic;
      OTG_LSPEED:                   inout std_logic;

      PS2_CLK:                      inout std_logic;
      PS2_DAT:                      inout std_logic;
      PS2_CLK2:                     inout std_logic;
      PS2_DAT2:                     inout std_logic;

      SW:                           in std_logic_vector(17 downto 0);

      UART_RXD:                     in std_logic;
      UART_TXD:                     out std_logic;

      HEX0:                         out std_logic_vector(6 downto 0);
      HEX1:                         out std_logic_vector(6 downto 0);
      HEX2:                         out std_logic_vector(6 downto 0);
      HEX3:                         out std_logic_vector(6 downto 0);
      HEX4:                         out std_logic_vector(6 downto 0);
      HEX5:                         out std_logic_vector(6 downto 0);
      HEX6:                         out std_logic_vector(6 downto 0);
      HEX7:                         out std_logic_vector(6 downto 0)
   );
end entity;

architecture prj of prj_de2_115_smp is
   signal pprdma_i_clk, pprdma_o_clk: std_logic;
   signal pprdma_i_data, pprdma_o_data: std_logic_vector(7 downto 0);
   signal pprdma_i_nstb, pprdma_o_nstb: std_logic;
   signal pprdma_i_sel, pprdma_o_sel: std_logic_vector(1 downto 0);
   signal pprdma_i_nrd, pprdma_o_nrd: std_logic;
   signal pprdma_i_nwr, pprdma_o_nwr: std_logic;
   signal pprdma_i_bp, pprdma_o_bp: std_logic;

   signal clk, psdramclk, vgaclk:   std_logic;
   signal rst:                      std_logic;

   signal pll_locked:               std_logic_vector(2 downto 0);
   signal hard_reset:               std_logic;

   signal SW_synched:               std_logic_vector(17 downto 0);

   constant NCPUS:                  integer := 4;
   constant NAGENTS:                integer := NCPUS + 2;
   signal s_bus_reqn:               std_logic_vector(NAGENTS - 1 downto 0);
   signal s_bus_gntn:               std_logic_vector(NAGENTS - 1 downto 0);
   signal arbit_rst:                std_logic;

   signal s_bus_r_addr_oe:          std_logic_vector(NAGENTS - 1 downto 0);
   type s_bus_r_addr_t is array(NAGENTS - 1 downto 0) of word;
   signal s_bus_r_addr_out:         s_bus_r_addr_t;
   signal s_bus_r_addr:             word;

   signal s_bus_r_sharen_oe:        std_logic_vector(NAGENTS - 1 downto 0);
   signal s_bus_r_sharen:           std_logic;
   signal s_bus_r_excln_oe:         std_logic_vector(NAGENTS - 1 downto 0);
   signal s_bus_r_excln:            std_logic;
   signal s_bus_a_waitn_oe:         std_logic_vector(NAGENTS - 1 downto 0);
   signal s_bus_a_waitn:            std_logic;
   signal s_bus_a_ackn_oe:          std_logic_vector(NAGENTS - 1 downto 0);
   signal s_bus_a_ackn:             std_logic;
   signal s_bus_a_sharen_oe:        std_logic_vector(NAGENTS - 1 downto 0);
   signal s_bus_a_sharen:           std_logic;
   signal s_bus_a_excln_oe:         std_logic_vector(NAGENTS - 1 downto 0);
   signal s_bus_a_excln:            std_logic;

   type blinkenlights_t is array(NCPUS - 1 downto 0) of std_logic_vector(14 downto 0);
   signal cpu_blinkenlights:        blinkenlights_t;
   signal blinkenlights:            std_logic_vector(14 downto 0);

   signal eirqs:                    std_logic_vector(NCPUS - 1 downto 0);

   type mce_code_t is array(NCPUS - 1 downto 0) of std_logic_vector(8 downto 0);
   signal mce_code:                 mce_code_t;

   signal eth_clk_125_mac, eth_clk_125_phy: std_logic;
   -- rgmii
   --type eth_t is record
   --   ena_10:                       std_logic;
   --   eth_mode:                     std_logic;
   --   mdc:                          std_logic;
   --   mdio_in:                      std_logic;
   --   mdio_oen:                     std_logic;
   --   mdio_out:                     std_logic;
   --   rgmii_in:                     std_logic_vector(3 downto 0);
   --   rgmii_out:                    std_logic_vector(3 downto 0);
   --   rx_clk:                       std_logic;
   --   rx_control:                   std_logic;
   --   set_1000:                     std_logic;
   --   set_10:                       std_logic;
   --   tx_clk:                       std_logic;
   --   tx_control:                   std_logic;
   --end record;

   -- mii
   type eth_t is record
      ena_10:                       std_logic;
      eth_mode:                     std_logic;
      m_rx_col:                     std_logic;
      m_rx_crs:                     std_logic;
      m_rx_d:                       std_logic_vector(3 downto 0);
      m_rx_en:                      std_logic;
      m_rx_err:                     std_logic;
      m_tx_d:                       std_logic_vector(3 downto 0);
      m_tx_en:                      std_logic;
      m_tx_err:                     std_logic;
      mdc:                          std_logic;
      mdio_in:                      std_logic;
      mdio_oen:                     std_logic;
      mdio_out:                     std_logic;
      rgmii_in:                     std_logic_vector(3 downto 0);
      rgmii_out:                    std_logic_vector(3 downto 0);
      rx_clk:                       std_logic;
      set_1000:                     std_logic;
      set_10:                       std_logic;
      tx_clk:                       std_logic;
   end record;

   signal eth0:                     eth_t;
   --signal eth1:                     eth_t;

   component ocp_timeout_indicator is
      generic(
         TIMEOUT_INDICATOR:            string := "ACTIVE_HIGH"
      );
      port(
         ip_timeout:                   out std_logic
      );
   end component;
   signal ip_timeout:               std_logic;
begin
   switch_cdc: entity work.delay_chain generic map(
      LENGTH => 2
   )
   port map(
      clk => clk,
      d => SW,
      q => SW_synched
   );

   sys : entity work.sys_de2_115_smp port map(
      CLOCK_50 => CLOCK_50,
      CLOCK2_50 => CLOCK2_50,
      CLOCK3_50 => CLOCK3_50,
      ENETCLK_25 => ENETCLK_25,
      cpu_pll_c0_out => clk,
      reset_n => not rst,

      locked_from_the_cpu_pll => pll_locked(0),
      locked_from_the_sdram_pll => pll_locked(1),
      locked_from_the_periph_pll => pll_locked(2),

      sdram_pll_c1_out => psdramclk,
      periph_pll_c0_out => vgaclk,
      eth_pll_c0_out => eth_clk_125_mac,
      eth_pll_c1_out => eth_clk_125_phy,

      blinkentriggers_from_the_cpu0(14 downto 0) => cpu_blinkenlights(0),
      blinkentriggers_from_the_cpu1(14 downto 0) => cpu_blinkenlights(1),
      blinkentriggers_from_the_cpu2(14 downto 0) => cpu_blinkenlights(2),
      blinkentriggers_from_the_cpu3(14 downto 0) => cpu_blinkenlights(3),
      triggermask_to_the_cpu0 => SW_synched,
      triggermask_to_the_cpu1 => (others => '0'),
      triggermask_to_the_cpu2 => (others => '0'),
      triggermask_to_the_cpu3 => (others => '0'),

      irqs_out_from_the_irqrouter => eirqs,
      eirqs_to_the_cpu0 => '0' & eirqs(0),
      eirqs_to_the_cpu1 => '0' & eirqs(1),
      eirqs_to_the_cpu2 => '0' & eirqs(2),
      eirqs_to_the_cpu3 => '0' & eirqs(3),

      mce_code_from_the_cpu0 => mce_code(0),
      mce_code_from_the_cpu1 => mce_code(1),
      mce_code_from_the_cpu2 => mce_code(2),
      mce_code_from_the_cpu3 => mce_code(3),

      s_bus_reqn_from_the_cpu0 => s_bus_reqn(0),
      s_bus_gntn_to_the_cpu0 => s_bus_gntn(0),
      s_bus_r_addr_oe_from_the_cpu0 => s_bus_r_addr_oe(0),
      s_bus_r_addr_out_from_the_cpu0 => s_bus_r_addr_out(0),
      s_bus_r_addr_to_the_cpu0 => s_bus_r_addr,
      s_bus_r_sharen_oe_from_the_cpu0 => s_bus_r_sharen_oe(0),
      s_bus_r_sharen_to_the_cpu0 => s_bus_r_sharen,
      s_bus_r_excln_oe_from_the_cpu0 => s_bus_r_excln_oe(0),
      s_bus_r_excln_to_the_cpu0 => s_bus_r_excln,
      s_bus_a_waitn_oe_from_the_cpu0 => s_bus_a_waitn_oe(0),
      s_bus_a_waitn_to_the_cpu0 => s_bus_a_waitn,
      s_bus_a_ackn_oe_from_the_cpu0 => s_bus_a_ackn_oe(0),
      s_bus_a_ackn_to_the_cpu0 => s_bus_a_ackn,
      s_bus_a_sharen_oe_from_the_cpu0 => s_bus_a_sharen_oe(0),
      s_bus_a_sharen_to_the_cpu0 => s_bus_a_sharen,
      s_bus_a_excln_oe_from_the_cpu0 => s_bus_a_excln_oe(0),
      s_bus_a_excln_to_the_cpu0 => s_bus_a_excln,

      s_bus_reqn_from_the_cpu1 => s_bus_reqn(1),
      s_bus_gntn_to_the_cpu1 => s_bus_gntn(1),
      s_bus_r_addr_oe_from_the_cpu1 => s_bus_r_addr_oe(1),
      s_bus_r_addr_out_from_the_cpu1 => s_bus_r_addr_out(1),
      s_bus_r_addr_to_the_cpu1 => s_bus_r_addr,
      s_bus_r_sharen_oe_from_the_cpu1 => s_bus_r_sharen_oe(1),
      s_bus_r_sharen_to_the_cpu1 => s_bus_r_sharen,
      s_bus_r_excln_oe_from_the_cpu1 => s_bus_r_excln_oe(1),
      s_bus_r_excln_to_the_cpu1 => s_bus_r_excln,
      s_bus_a_waitn_oe_from_the_cpu1 => s_bus_a_waitn_oe(1),
      s_bus_a_waitn_to_the_cpu1 => s_bus_a_waitn,
      s_bus_a_ackn_oe_from_the_cpu1 => s_bus_a_ackn_oe(1),
      s_bus_a_ackn_to_the_cpu1 => s_bus_a_ackn,
      s_bus_a_sharen_oe_from_the_cpu1 => s_bus_a_sharen_oe(1),
      s_bus_a_sharen_to_the_cpu1 => s_bus_a_sharen,
      s_bus_a_excln_oe_from_the_cpu1 => s_bus_a_excln_oe(1),
      s_bus_a_excln_to_the_cpu1 => s_bus_a_excln,

      s_bus_reqn_from_the_cpu2 => s_bus_reqn(2),
      s_bus_gntn_to_the_cpu2 => s_bus_gntn(2),
      s_bus_r_addr_oe_from_the_cpu2 => s_bus_r_addr_oe(2),
      s_bus_r_addr_out_from_the_cpu2 => s_bus_r_addr_out(2),
      s_bus_r_addr_to_the_cpu2 => s_bus_r_addr,
      s_bus_r_sharen_oe_from_the_cpu2 => s_bus_r_sharen_oe(2),
      s_bus_r_sharen_to_the_cpu2 => s_bus_r_sharen,
      s_bus_r_excln_oe_from_the_cpu2 => s_bus_r_excln_oe(2),
      s_bus_r_excln_to_the_cpu2 => s_bus_r_excln,
      s_bus_a_waitn_oe_from_the_cpu2 => s_bus_a_waitn_oe(2),
      s_bus_a_waitn_to_the_cpu2 => s_bus_a_waitn,
      s_bus_a_ackn_oe_from_the_cpu2 => s_bus_a_ackn_oe(2),
      s_bus_a_ackn_to_the_cpu2 => s_bus_a_ackn,
      s_bus_a_sharen_oe_from_the_cpu2 => s_bus_a_sharen_oe(2),
      s_bus_a_sharen_to_the_cpu2 => s_bus_a_sharen,
      s_bus_a_excln_oe_from_the_cpu2 => s_bus_a_excln_oe(2),
      s_bus_a_excln_to_the_cpu2 => s_bus_a_excln,

      s_bus_reqn_from_the_cpu3 => s_bus_reqn(3),
      s_bus_gntn_to_the_cpu3 => s_bus_gntn(3),
      s_bus_r_addr_oe_from_the_cpu3 => s_bus_r_addr_oe(3),
      s_bus_r_addr_out_from_the_cpu3 => s_bus_r_addr_out(3),
      s_bus_r_addr_to_the_cpu3 => s_bus_r_addr,
      s_bus_r_sharen_oe_from_the_cpu3 => s_bus_r_sharen_oe(3),
      s_bus_r_sharen_to_the_cpu3 => s_bus_r_sharen,
      s_bus_r_excln_oe_from_the_cpu3 => s_bus_r_excln_oe(3),
      s_bus_r_excln_to_the_cpu3 => s_bus_r_excln,
      s_bus_a_waitn_oe_from_the_cpu3 => s_bus_a_waitn_oe(3),
      s_bus_a_waitn_to_the_cpu3 => s_bus_a_waitn,
      s_bus_a_ackn_oe_from_the_cpu3 => s_bus_a_ackn_oe(3),
      s_bus_a_ackn_to_the_cpu3 => s_bus_a_ackn,
      s_bus_a_sharen_oe_from_the_cpu3 => s_bus_a_sharen_oe(3),
      s_bus_a_sharen_to_the_cpu3 => s_bus_a_sharen,
      s_bus_a_excln_oe_from_the_cpu3 => s_bus_a_excln_oe(3),
      s_bus_a_excln_to_the_cpu3 => s_bus_a_excln,

      s_bus_reqn_from_the_eth_ccdma => s_bus_reqn(4),
      s_bus_gntn_to_the_eth_ccdma => s_bus_gntn(4),
      s_bus_r_addr_oe_from_the_eth_ccdma => s_bus_r_addr_oe(4),
      s_bus_r_addr_out_from_the_eth_ccdma => s_bus_r_addr_out(4),
      s_bus_r_addr_to_the_eth_ccdma => s_bus_r_addr,
      s_bus_r_sharen_oe_from_the_eth_ccdma => s_bus_r_sharen_oe(4),
      s_bus_r_sharen_to_the_eth_ccdma => s_bus_r_sharen,
      s_bus_r_excln_oe_from_the_eth_ccdma => s_bus_r_excln_oe(4),
      s_bus_r_excln_to_the_eth_ccdma => s_bus_r_excln,
      s_bus_a_waitn_oe_from_the_eth_ccdma => s_bus_a_waitn_oe(4),
      s_bus_a_waitn_to_the_eth_ccdma => s_bus_a_waitn,
      s_bus_a_ackn_oe_from_the_eth_ccdma => s_bus_a_ackn_oe(4),
      s_bus_a_ackn_to_the_eth_ccdma => s_bus_a_ackn,
      s_bus_a_sharen_oe_from_the_eth_ccdma => s_bus_a_sharen_oe(4),
      s_bus_a_sharen_to_the_eth_ccdma => s_bus_a_sharen,
      s_bus_a_excln_oe_from_the_eth_ccdma => s_bus_a_excln_oe(4),
      s_bus_a_excln_to_the_eth_ccdma => s_bus_a_excln,

      s_bus_reqn_from_the_pprdma_ccdma => s_bus_reqn(5),
      s_bus_gntn_to_the_pprdma_ccdma => s_bus_gntn(5),
      s_bus_r_addr_oe_from_the_pprdma_ccdma => s_bus_r_addr_oe(5),
      s_bus_r_addr_out_from_the_pprdma_ccdma => s_bus_r_addr_out(5),
      s_bus_r_addr_to_the_pprdma_ccdma => s_bus_r_addr,
      s_bus_r_sharen_oe_from_the_pprdma_ccdma => s_bus_r_sharen_oe(5),
      s_bus_r_sharen_to_the_pprdma_ccdma => s_bus_r_sharen,
      s_bus_r_excln_oe_from_the_pprdma_ccdma => s_bus_r_excln_oe(5),
      s_bus_r_excln_to_the_pprdma_ccdma => s_bus_r_excln,
      s_bus_a_waitn_oe_from_the_pprdma_ccdma => s_bus_a_waitn_oe(5),
      s_bus_a_waitn_to_the_pprdma_ccdma => s_bus_a_waitn,
      s_bus_a_ackn_oe_from_the_pprdma_ccdma => s_bus_a_ackn_oe(5),
      s_bus_a_ackn_to_the_pprdma_ccdma => s_bus_a_ackn,
      s_bus_a_sharen_oe_from_the_pprdma_ccdma => s_bus_a_sharen_oe(5),
      s_bus_a_sharen_to_the_pprdma_ccdma => s_bus_a_sharen,
      s_bus_a_excln_oe_from_the_pprdma_ccdma => s_bus_a_excln_oe(5),
      s_bus_a_excln_to_the_pprdma_ccdma => s_bus_a_excln,

      zs_addr_from_the_sdram => DRAM_ADDR,
      zs_ba_from_the_sdram => DRAM_BA,
      zs_cas_n_from_the_sdram => DRAM_CAS_N,
      zs_cke_from_the_sdram => DRAM_CKE,
      zs_cs_n_from_the_sdram => DRAM_CS_N,
      zs_dq_to_and_from_the_sdram => DRAM_DQ,
      zs_dqm_from_the_sdram => DRAM_DQM,
      zs_ras_n_from_the_sdram => DRAM_RAS_N,
      zs_we_n_from_the_sdram => DRAM_WE_N,

      i_data_to_the_pprdma_ctrl => pprdma_i_data,
      i_bp_to_the_pprdma_ctrl => pprdma_i_bp,
      i_clk_to_the_pprdma_ctrl => pprdma_i_clk,
      i_nrd_to_the_pprdma_ctrl => pprdma_i_nrd,
      i_nstb_to_the_pprdma_ctrl => pprdma_i_nstb,
      i_nwr_to_the_pprdma_ctrl => pprdma_i_nwr,
      i_sel_to_the_pprdma_ctrl => pprdma_i_sel,

      o_data_from_the_pprdma_ctrl => pprdma_o_data,
      o_bp_from_the_pprdma_ctrl => pprdma_o_bp,
      o_clk_from_the_pprdma_ctrl => pprdma_o_clk,
      o_nrd_from_the_pprdma_ctrl => pprdma_o_nrd,
      o_nstb_from_the_pprdma_ctrl => pprdma_o_nstb,
      o_nwr_from_the_pprdma_ctrl => pprdma_o_nwr,
      o_sel_from_the_pprdma_ctrl => pprdma_o_sel,

      -- rgmii
      --ena_10_from_the_eth0 => eth0.ena_10,
      --eth_mode_from_the_eth0 => eth0.eth_mode,
      --mdc_from_the_eth0 => eth0.mdc,
      --mdio_in_to_the_eth0 => eth0.mdio_in,
      --mdio_oen_from_the_eth0 => eth0.mdio_oen,
      --mdio_out_from_the_eth0 => eth0.mdio_out,
      --rgmii_in_to_the_eth0 => eth0.rgmii_in,
      --rgmii_out_from_the_eth0 => eth0.rgmii_out,
      --rx_clk_to_the_eth0 => eth0.rx_clk,
      --rx_control_to_the_eth0 => eth0.rx_control,
      --set_1000_to_the_eth0 => eth0.set_1000,
      --set_10_to_the_eth0 => eth0.set_10,
      --tx_clk_to_the_eth0 => eth0.tx_clk,
      --tx_control_from_the_eth0 => eth0.tx_control,

      -- mii
      ena_10_from_the_eth0 => eth0.ena_10,
      eth_mode_from_the_eth0 => eth0.eth_mode,
      m_rx_col_to_the_eth0 => eth0.m_rx_col,
      m_rx_crs_to_the_eth0 => eth0.m_rx_crs,
      m_rx_d_to_the_eth0 => eth0.m_rx_d,
      m_rx_en_to_the_eth0 => eth0.m_rx_en,
      m_rx_err_to_the_eth0 => eth0.m_rx_err,
      m_tx_d_from_the_eth0 => eth0.m_tx_d,
      m_tx_en_from_the_eth0 => eth0.m_tx_en,
      m_tx_err_from_the_eth0 => eth0.m_tx_err,
      mdc_from_the_eth0 => eth0.mdc,
      mdio_in_to_the_eth0 => eth0.mdio_in,
      mdio_oen_from_the_eth0 => eth0.mdio_oen,
      mdio_out_from_the_eth0 => eth0.mdio_out,
      rx_clk_to_the_eth0 => eth0.rx_clk,
      set_1000_to_the_eth0 => eth0.set_1000,
      set_10_to_the_eth0 => eth0.set_10,
      tx_clk_to_the_eth0 => eth0.tx_clk,
      gm_rx_d_to_the_eth0 => (others => '0'),
      gm_rx_dv_to_the_eth0 => '0',
      gm_rx_err_to_the_eth0 => '0',

      --ena_10_from_the_eth1 => eth1.ena_10,
      --eth_mode_from_the_eth1 => eth1.eth_mode,
      --m_rx_col_to_the_eth1 => eth1.m_rx_col,
      --m_rx_crs_to_the_eth1 => eth1.m_rx_crs,
      --m_rx_d_to_the_eth1 => eth1.m_rx_d,
      --m_rx_en_to_the_eth1 => eth1.m_rx_en,
      --m_rx_err_to_the_eth1 => eth1.m_rx_err,
      --m_tx_d_from_the_eth1 => eth1.m_tx_d,
      --m_tx_en_from_the_eth1 => eth1.m_tx_en,
      --m_tx_err_from_the_eth1 => eth1.m_tx_err,
      --mdc_from_the_eth1 => eth1.mdc,
      --mdio_in_to_the_eth1 => eth1.mdio_in,
      --mdio_oen_from_the_eth1 => eth1.mdio_oen,
      --mdio_out_from_the_eth1 => eth1.mdio_out,
      --rx_clk_to_the_eth1 => eth1.rx_clk,
      --set_1000_to_the_eth1 => eth1.set_1000,
      --set_10_to_the_eth1 => eth1.set_10,
      --tx_clk_to_the_eth1 => eth1.tx_clk,
      --gm_rx_d_to_the_eth1 => (others => '0'),
      --gm_rx_dv_to_the_eth1 => '0',
      --gm_rx_err_to_the_eth1 => '0',

      r_from_the_vga(9 downto 2) => VGA_R,
      g_from_the_vga(9 downto 2) => VGA_G,
      b_from_the_vga(9 downto 2) => VGA_B,
      blank_from_the_vga => VGA_BLANK_N,
      hsync_from_the_vga => VGA_HS,
      vsync_from_the_vga => VGA_VS,
      pclk_to_the_vga => vgaclk,

      rxd_to_the_uart => UART_RXD,
      txd_from_the_uart => UART_TXD,

      pin_addr_from_the_isp1362 => OTG_ADDR,
      pin_data_to_and_from_the_isp1362 => OTG_DATA,
      pin_cs_n_from_the_isp1362 => OTG_CS_N,
      pin_rd_n_from_the_isp1362 => OTG_RD_N,
      pin_wr_n_from_the_isp1362 => OTG_WR_N,
      pin_rst_n_from_the_isp1362 => OTG_RST_N,
      pin_int0_to_the_isp1362 => OTG_INT(0),

      address_to_the_cfi => FL_ADDR,
      data_to_and_from_the_cfi => FL_DQ,
      read_n_to_the_cfi => FL_OE_N,
      select_n_to_the_cfi => FL_CE_N,
      write_n_to_the_cfi => FL_WE_N,

      --MISO_to_the_spi => SD_DAT,
      --MOSI_from_the_spi => SD_CMD,
      --SCLK_from_the_spi => oSD_CLK,
      --SS_n_from_the_spi => SD_DAT3,

      PS2_CLK_to_and_from_the_ps2k => PS2_CLK,
      PS2_DAT_to_and_from_the_ps2k => PS2_DAT,
      PS2_CLK_to_and_from_the_ps2m => PS2_CLK2,
      PS2_DAT_to_and_from_the_ps2m => PS2_DAT2
   );

   DRAM_CLK <= psdramclk;

   VGA_SYNC_N <= '1'; -- not using sync-on-green
   VGA_CLK <= not vgaclk;

   FL_WP_N <= '1';
   FL_RST_N <= not rst;

   OTG_DACK_N <= "11";
   OTG_FSPEED <= '0';
   OTG_LSPEED <= '0';

   pprdma_map: entity work.pprdma_map_de2 generic map(
      PHY_WIDTH => 8,
      INDATA_LOW => 0,
      INCTL_LOW => 8,
      OUTDATA_LOW => 16,
      OUTCTL_LOW => 24
   )
   port map(
      i_clk => pprdma_i_clk,
      i_data => pprdma_i_data,
      i_nstb => pprdma_i_nstb,
      i_sel => pprdma_i_sel,
      i_nrd => pprdma_i_nrd,
      i_nwr => pprdma_i_nwr,
      i_bp => pprdma_i_bp,

      o_clk => pprdma_o_clk,
      o_data => pprdma_o_data,
      o_nstb => pprdma_o_nstb,
      o_sel => pprdma_o_sel,
      o_nrd => pprdma_o_nrd,
      o_nwr => pprdma_o_nwr,
      o_bp => pprdma_o_bp,

      io => GPIO
   );

   LEDG <= (
      0 => not pprdma_i_nstb,
      1 => pprdma_i_bp,
      2 => not pprdma_o_nstb,
      3 => pprdma_o_bp,
      --4 => not oSRAM_ADSC_N,
      5 => not DRAM_RAS_N,
      6 => not DRAM_CAS_N,
      7 => rst,
      8 => ip_timeout,
      --8 => not iFLASH_RY_N,
      others => '0'
   );

   LEDR(17 downto 15) <= (
      17 => not FL_RY,
      --16 => not iOTG_INT0,
      --15 => not iOTG_INT1,
      others => '0'
   );
   process(cpu_blinkenlights) is begin
      blinkenlights <= (others => '0');
      for i in cpu_blinkenlights'range loop
         for j in cpu_blinkenlights(i)'range loop
            if(cpu_blinkenlights(i)(j) = '1') then
               blinkenlights(j) <= '1';
            end if;
         end loop;
      end loop;
   end process;
   LEDR(14 downto 0) <= blinkenlights;

   -- reset generator
   hard_reset <=  '1' when KEY(0) = '0' else
                  '1' when pll_locked(0) = '0' else
                  '1' when pll_locked(1) = '0' else
                  '1' when pll_locked(2) = '0' else
                  '0';
   process(hard_reset, CLOCK_50) is
      variable rstcount: std_logic_vector(9 downto 0);
   begin
      if(hard_reset = '1') then
         rst <= '1';
         rstcount := (others => '0');
      elsif(rising_edge(CLOCK_50)) then
         if(rstcount = (rstcount'range => '1')) then
            rst <= '0';
         end if;
         rstcount := rstcount + 1;
      end if;
   end process;

   -- emulate tristate/open-drain bus signals
   addr_bus_drivers: for i in 0 to NAGENTS - 1 generate
      s_bus_r_addr <= s_bus_r_addr_out(i) when s_bus_r_addr_oe(i) = '1' else (others => 'Z');
   end generate;
   s_bus_r_sharen <= '0' when any_bit_set(s_bus_r_sharen_oe) else '1';
   s_bus_r_excln <= '0' when any_bit_set(s_bus_r_excln_oe) else '1';
   s_bus_a_waitn <= '0' when any_bit_set(s_bus_a_waitn_oe) else '1';
   s_bus_a_ackn <= '0' when any_bit_set(s_bus_a_ackn_oe) else '1';
   s_bus_a_sharen <= '0' when any_bit_set(s_bus_a_sharen_oe) else '1';
   s_bus_a_excln <= '0' when any_bit_set(s_bus_a_excln_oe) else '1';

   snoop_arbit: entity work.snoop_arbit generic map(
      NAGENTS => NAGENTS
   )
   port map(
      clk => clk,
      rst => arbit_rst,

      s_bus_a_waitn => s_bus_a_waitn,
      reqn => s_bus_reqn,
      gntn => s_bus_gntn
   );
   snoop_rst_synch: entity work.delay_chain generic map(
      LENGTH => 3
   )
   port map(
      clk => clk,
      d(0) => rst,
      q(0) => arbit_rst
   );

   eth0_mii: entity work.mii_voodoo port map(
      --clk_125_mac => eth_clk_125_mac,
      --clk_125_phy => eth_clk_125_phy,
      rst => rst,

      pin_gtx_clk => ENET0_GTX_CLK,
      pin_int_n => ENET0_INT_N,
      pin_link100 => ENET0_LINK100,
      pin_mdc => ENET0_MDC,
      pin_mdio => ENET0_MDIO,
      pin_rst_n => ENET0_RST_N,
      pin_rx_clk => ENET0_RX_CLK,
      pin_rx_col => ENET0_RX_COL,
      pin_rx_crs => ENET0_RX_CRS,
      pin_rx_data => ENET0_RX_DATA,
      pin_rx_dv => ENET0_RX_DV,
      pin_rx_er => ENET0_RX_ER,
      pin_tx_clk => ENET0_TX_CLK,
      pin_tx_data => ENET0_TX_DATA,
      pin_tx_en => ENET0_TX_EN,
      pin_tx_er => ENET0_TX_ER,

      -- rgmii
      --ena_10 => eth0.ena_10,
      --eth_mode => eth0.eth_mode,
      --mdc => eth0.mdc,
      --mdio_in => eth0.mdio_in,
      --mdio_oen => eth0.mdio_oen,
      --mdio_out => eth0.mdio_out,
      --rgmii_in => eth0.rgmii_in,
      --rgmii_out => eth0.rgmii_out,
      --rx_clk => eth0.rx_clk,
      --rx_control => eth0.rx_control,
      --set_1000 => eth0.set_1000,
      --set_10 => eth0.set_10,
      --tx_clk => eth0.tx_clk,
      --tx_control => eth0.tx_control

      -- mii
      ena_10 => eth0.ena_10,
      eth_mode => eth0.eth_mode,
      m_rx_col => eth0.m_rx_col,
      m_rx_crs => eth0.m_rx_crs,
      m_rx_d => eth0.m_rx_d,
      m_rx_en => eth0.m_rx_en,
      m_rx_err => eth0.m_rx_err,
      m_tx_d => eth0.m_tx_d,
      m_tx_en => eth0.m_tx_en,
      m_tx_err => eth0.m_tx_err,
      mdc => eth0.mdc,
      mdio_in => eth0.mdio_in,
      mdio_oen => eth0.mdio_oen,
      mdio_out => eth0.mdio_out,
      rx_clk => eth0.rx_clk,
      set_1000 => eth0.set_1000,
      set_10 => eth0.set_10,
      tx_clk => eth0.tx_clk
   );

   --eth1_mii: entity work.mii_voodoo port map(
   --   --clk_125_mac => eth_clk_125_mac,
   --   --clk_125_phy => eth_clk_125_phy,
   --   rst => rst,

   --   pin_gtx_clk => ENET1_GTX_CLK,
   --   pin_int_n => ENET1_INT_N,
   --   pin_link100 => ENET1_LINK100,
   --   pin_mdc => ENET1_MDC,
   --   pin_mdio => ENET1_MDIO,
   --   pin_rst_n => ENET1_RST_N,
   --   pin_rx_clk => ENET1_RX_CLK,
   --   pin_rx_col => ENET1_RX_COL,
   --   pin_rx_crs => ENET1_RX_CRS,
   --   pin_rx_data => ENET1_RX_DATA,
   --   pin_rx_dv => ENET1_RX_DV,
   --   pin_rx_er => ENET1_RX_ER,
   --   pin_tx_clk => ENET1_TX_CLK,
   --   pin_tx_data => ENET1_TX_DATA,
   --   pin_tx_en => ENET1_TX_EN,
   --   pin_tx_er => ENET1_TX_ER,

   --   -- rgmii
   --   --ena_10 => eth1.ena_10,
   --   --eth_mode => eth1.eth_mode,
   --   --mdc => eth1.mdc,
   --   --mdio_in => eth1.mdio_in,
   --   --mdio_oen => eth1.mdio_oen,
   --   --mdio_out => eth1.mdio_out,
   --   --rgmii_in => eth1.rgmii_in,
   --   --rgmii_out => eth1.rgmii_out,
   --   --rx_clk => eth1.rx_clk,
   --   --rx_control => eth1.rx_control,
   --   --set_1000 => eth1.set_1000,
   --   --set_10 => eth1.set_10,
   --   --tx_clk => eth1.tx_clk,
   --   --tx_control => eth1.tx_control

   --   -- mii
   --   ena_10 => eth1.ena_10,
   --   eth_mode => eth1.eth_mode,
   --   m_rx_col => eth1.m_rx_col,
   --   m_rx_crs => eth1.m_rx_crs,
   --   m_rx_d => eth1.m_rx_d,
   --   m_rx_en => eth1.m_rx_en,
   --   m_rx_err => eth1.m_rx_err,
   --   m_tx_d => eth1.m_tx_d,
   --   m_tx_en => eth1.m_tx_en,
   --   m_tx_err => eth1.m_tx_err,
   --   mdc => eth1.mdc,
   --   mdio_in => eth1.mdio_in,
   --   mdio_oen => eth1.mdio_oen,
   --   mdio_out => eth1.mdio_out,
   --   rx_clk => eth1.rx_clk,
   --   set_1000 => eth1.set_1000,
   --   set_10 => eth1.set_10,
   --   tx_clk => eth1.tx_clk
   --);

   timeout: ocp_timeout_indicator port map(
      ip_timeout => ip_timeout
   );

   hex0_driver: entity work.sevenseg port map(mce_code(3)(3 downto 0), HEX0, not mce_code(3)(8));
   hex1_driver: entity work.sevenseg port map(mce_code(3)(7 downto 4), HEX1, not mce_code(3)(8));
   hex2_driver: entity work.sevenseg port map(mce_code(2)(3 downto 0), HEX2, not mce_code(2)(8));
   hex3_driver: entity work.sevenseg port map(mce_code(2)(7 downto 4), HEX3, not mce_code(2)(8));
   hex4_driver: entity work.sevenseg port map(mce_code(1)(3 downto 0), HEX4, not mce_code(1)(8));
   hex5_driver: entity work.sevenseg port map(mce_code(1)(7 downto 4), HEX5, not mce_code(1)(8));
   hex6_driver: entity work.sevenseg port map(mce_code(0)(3 downto 0), HEX6, not mce_code(0)(8));
   hex7_driver: entity work.sevenseg port map(mce_code(0)(7 downto 4), HEX7, not mce_code(0)(8));
end architecture;
