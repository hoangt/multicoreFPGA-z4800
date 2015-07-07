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

entity rgmii_voodoo is
   port(
      clk_125_mac:                  in std_logic;
      clk_125_phy:                  in std_logic;
      rst:                          in std_logic;

      pin_gtx_clk:                  inout std_logic;
      pin_int_n:                    in std_logic;
      pin_link100:                  in std_logic;
      pin_mdc:                      out std_logic;
      pin_mdio:                     inout std_logic;
      pin_rst_n:                    out std_logic;
      pin_rx_clk:                   in std_logic;
      pin_rx_col:                   in std_logic;
      pin_rx_crs:                   in std_logic;
      pin_rx_data:                  in std_logic_vector(3 downto 0);
      pin_rx_dv:                    in std_logic;
      pin_rx_er:                    in std_logic;
      pin_tx_clk:                   in std_logic;
      pin_tx_data:                  out std_logic_vector(3 downto 0);
      pin_tx_en:                    out std_logic;
      pin_tx_er:                    out std_logic;


      ena_10:                       in std_logic;
      eth_mode:                     in std_logic;
      mdc:                          in std_logic;
      mdio_in:                      out std_logic;
      mdio_oen:                     in std_logic;
      mdio_out:                     in std_logic;
      rgmii_in:                     out std_logic_vector(3 downto 0);
      rgmii_out:                    in std_logic_vector(3 downto 0);
      rx_clk:                       out std_logic;
      rx_control:                   out std_logic;
      set_1000:                     out std_logic;
      set_10:                       out std_logic;
      tx_clk:                       out std_logic;
      tx_control:                   in std_logic
   );
end entity;

architecture rgmii_voodoo of rgmii_voodoo is
begin
   pin_gtx_clk <=
      clk_125_phy when eth_mode = '1' else
      'Z';

   tx_clk <=
      clk_125_mac when eth_mode = '1' else
      pin_tx_clk;

   pin_tx_en <= tx_control;
   pin_tx_data <= rgmii_out;
   pin_tx_er <= '0';

   set_1000 <= '0';
   set_10 <= '0';

   rx_clk <= pin_rx_clk;
   rx_control <= pin_rx_dv;
   rgmii_in <= pin_rx_data;

   pin_mdio <=
      'Z' when mdio_oen = '1' else
      mdio_out;

   mdio_in <= pin_mdio;
   pin_mdc <= mdc;

   pin_rst_n <= not rst;
end architecture;
