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
library lpm;
use lpm.lpm_components.all;
library z48common;
use z48common.z48common.all;

entity eth_align is
   port(
      clk                     :  in       std_logic;
      rst                     :  in       std_logic;

      in_empty                :  in       std_logic_vector;
      in_offset               :  in       std_logic_vector;
      in_data                 :  in       std_logic_vector;
      in_sop                  :  in       std_logic;
      in_eop                  :  in       std_logic;
      in_ready                :  buffer   std_logic;
      in_valid                :  in       std_logic;

      out_empty               :  out      std_logic_vector;
      out_data                :  out      std_logic_vector;
      out_sop                 :  out      std_logic;
      out_eop                 :  out      std_logic;
      out_ready               :  in       std_logic;
      out_valid               :  buffer   std_logic
   );
end;

architecture eth_align of eth_align is
   constant WIDTH             :  natural := in_data'length;
   constant BYTES             :  natural := WIDTH / 8;
   constant BYTES_LOG2        :  natural := log2c(BYTES);

   constant LSBL              :  natural := 0;
   constant LSBH              :  natural := in_data'length - 1;
   constant MSBL              :  natural := LSBH + 1;
   constant MSBH              :  natural := MSBL + in_data'length - 1;

   constant LSBEL             :  natural := 0;
   constant LSBEH             :  natural := BYTES - 1;
   constant MSBEL             :  natural := LSBEH + 1;
   constant MSBEH             :  natural := MSBEL + BYTES - 1;

   signal msb_data            :  std_logic_vector(WIDTH - 1 downto 0);
   signal msb_data_reg        :  std_logic_vector(WIDTH - 1 downto 0);
   signal msb_data_reg2       :  std_logic_vector(WIDTH - 1 downto 0);
   signal lsb_data            :  std_logic_vector(WIDTH - 1 downto 0);
   signal lsb_data_reg        :  std_logic_vector(WIDTH - 1 downto 0);
   signal lsb_data_reg2       :  std_logic_vector(WIDTH - 1 downto 0);

   signal msb_be              :  std_logic_vector(BYTES - 1 downto 0);
   signal msb_be_reg          :  std_logic_vector(BYTES - 1 downto 0);
   signal msb_be_reg2         :  std_logic_vector(BYTES - 1 downto 0);
   signal lsb_be              :  std_logic_vector(BYTES - 1 downto 0);
   signal lsb_be_reg          :  std_logic_vector(BYTES - 1 downto 0);
   signal lsb_be_reg2         :  std_logic_vector(BYTES - 1 downto 0);

   signal sop_reg             :  std_logic;
   signal sop_reg2            :  std_logic;
   signal eop_reg             :  std_logic;
   signal eop_reg2            :  std_logic;
   signal valid_reg           :  std_logic;
   signal valid_reg2          :  std_logic;
   signal empty_reg           :  std_logic_vector(in_empty'range);
   signal empty_reg2          :  std_logic_vector(in_empty'range);
begin
   assert(in_offset'length = BYTES_LOG2) report "in_offset length mismatch" severity error;

   data_shifter: lpm_clshift generic map(
      LPM_WIDTH => in_data'length * 2,
      LPM_WIDTHDIST => 1 + BYTES_LOG2 + 3
   )
   port map(
      data => in_data & (in_data'range => '0'),
      distance => '0' & in_offset & "000",
      direction => '1',
      result(MSBH downto MSBL) => msb_data,
      result(LSBH downto LSBL) => lsb_data
   );
   be_shifter: lpm_clshift generic map(
      LPM_WIDTH => BYTES * 2,
      LPM_WIDTHDIST => 1 + BYTES_LOG2
   )
   port map(
      data => (BYTES - 1 downto 0 => '1') & (BYTES - 1 downto 0 => '0'),
      distance => '0' & in_offset,
      direction => '1',
      result(MSBEH downto MSBEL) => msb_be,
      result(LSBEH downto LSBEL) => lsb_be
   );

   byte_lanes: for i in BYTES - 1 downto 0 generate
      out_data((i * 8) + 7 downto (i * 8) + 0) <=
         msb_data_reg2((i * 8) + 7 downto (i * 8) + 0) when msb_be_reg2(i) = '1' else
         lsb_data_reg((i * 8) + 7 downto (i * 8) + 0);
   end generate;

   out_sop <= sop_reg2;
   out_eop <= eop_reg2;

   out_valid <=
      valid_reg2 when eop_reg2 = '1' else
      valid_reg2 and valid_reg;

   out_empty <= empty_reg2;

   in_ready <= out_ready;

   process(clk) is begin
      if(rising_edge(clk)) then
         if(out_ready = '1') then
            if(out_valid = '1') then
               valid_reg2 <= '0';
            end if;

            if(in_valid = '1') then
               msb_data_reg <= msb_data;
               msb_be_reg <= msb_be;
               lsb_data_reg <= lsb_data;
               lsb_be_reg <= lsb_be;
               sop_reg <= in_sop;
               eop_reg <= in_eop;
               empty_reg <= in_empty;
            end if;

            valid_reg <= in_valid;

            if(valid_reg = '1') then
               msb_data_reg2 <= msb_data_reg;
               msb_be_reg2 <= msb_be_reg;
               lsb_data_reg2 <= lsb_data_reg;
               lsb_be_reg2 <= lsb_be_reg;
               sop_reg2 <= sop_reg;
               eop_reg2 <= eop_reg;
               empty_reg2 <= empty_reg;
               valid_reg2 <= '1';
            end if;
         end if;

         if(rst = '1') then
            valid_reg <= '0';
            valid_reg2 <= '0';
         end if;
      end if;
   end process;
end;
