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
library altera;
use altera.altera_syn_attributes.all;

entity isp1362_hc is
   port(
      clk                     :  in       std_logic;
      rst                     :  in       std_logic;

      s_addr                  :  in       std_logic_vector(1 downto 0);
      s_cs                    :  in       std_logic;
      s_rd                    :  in       std_logic;
      s_wr                    :  in       std_logic;
      s_in                    :  in       std_logic_vector(31 downto 0);
      s_out                   :  out      std_logic_vector(31 downto 0);
      s_int                   :  out      std_logic;

      pin_addr                :  out      std_logic_vector(1 downto 0);
      pin_data                :  inout    std_logic_vector(15 downto 0);
      pin_cs_n                :  out      std_logic;
      pin_rd_n                :  out      std_logic;
      pin_wr_n                :  out      std_logic;
      pin_rst_n               :  out      std_logic;
      pin_int0                :  in       std_logic
   );
end;

architecture isp1362_hc of isp1362_hc is
   attribute altera_attribute of pin_addr, pin_cs_n, pin_rd_n, pin_wr_n, pin_rst_n: signal is "FAST_OUTPUT_REGISTER=ON";
   attribute altera_attribute of pin_int0: signal is "FAST_INPUT_REGISTER=ON";
   attribute altera_attribute of pin_data: signal is "FAST_OUTPUT_REGISTER=ON;FAST_INPUT_REGISTER=ON";

   signal int_synch           :  std_logic_vector(2 downto 0);
begin
   process(clk) is begin
      if(rising_edge(clk)) then
         int_synch <= int_synch(int_synch'high - 1 downto 0) & pin_int0;

         pin_rst_n <= not rst;
         pin_cs_n <= not s_cs;
         pin_rd_n <= not s_rd;
         pin_wr_n <= not s_wr;
         pin_addr <= s_addr;
         if(s_wr = '1') then
            pin_data <= s_in(15 downto 0);
         else
            pin_data <= (others => 'Z');
         end if;

         s_out <= (31 downto 16 => '0') & pin_data;

         if(rst = '1') then
            pin_cs_n <= '1';
            pin_data <= (others => 'Z');
         end if;
      end if;
   end process;

   s_int <= not int_synch(int_synch'high);
end;
