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

entity altregfile is
   generic(
      WRITE_PORTS:                  natural;
      READ_PORTS:                   natural;
      MIXED_BYPASS:                 boolean
   );
   port(
      clock:                        in std_logic;
      reset:                        in std_logic;

      read_ad:                      in regport_addr_t(READ_PORTS - 1 downto 0);
      read_data:                    out regport_data_t(READ_PORTS - 1 downto 0);
      read_as:                      in std_logic_vector(READ_PORTS - 1 downto 0);

      write_ad:                     in regport_addr_t(WRITE_PORTS - 1 downto 0);
      write_data:                   in regport_data_t(WRITE_PORTS - 1 downto 0);
      write_en:                     in std_logic_vector(WRITE_PORTS - 1 downto 0)
   );
end altregfile;

architecture altregfile of altregfile is
   type reg_bank_t is array(WRITE_PORTS - 1 downto 0, READ_PORTS - 1 downto 0) of word;
   signal b: reg_bank_t;
   constant IBITS: integer := log2c(WRITE_PORTS);
   type index_t is array(31 downto 0) of std_logic_vector(IBITS - 1 downto 0);
   signal index: index_t;
   signal cur_read_ad: regport_addr_t(READ_PORTS - 1 downto 0);
   signal valid, valid_in: std_logic_vector(31 downto 0);
begin
   rbanks: for i in 0 to READ_PORTS - 1 generate
      wbanks: for j in 0 to WRITE_PORTS - 1 generate
         bank: entity work.ramwrap generic map(
            WIDTH_A => 32,
            WIDTHAD_A => 5,
            WIDTH_B => 32,
            WIDTHAD_B => 5,
            OPERATION_MODE => "DUAL_PORT",
            MIXED_PORT_FORWARDING => MIXED_BYPASS
         )
         port map(
            clock0 => clock,
            clock1 => clock,
            address_a => write_ad(j),
            address_b => read_ad(i),
            addressstall_b => read_as(i),
            q_b => b(j, i),
            data_a => write_data(j)(31 downto 0),
            wren_a => write_en(j)
         );
      end generate;

      read_data(i) <= valid(int(cur_read_ad(i))) & b(int(index(int(cur_read_ad(i)))), i);
   end generate;

   process(clock) is begin
      if(rising_edge(clock)) then
         if(not MIXED_BYPASS) then -- delay valid bits to match read latency
            valid <= valid_in;
         end if;
         for i in 0 to WRITE_PORTS - 1 loop
            if(write_en(i) = '1') then
               index(int(write_ad(i))) <= vec(i, IBITS);
               if(MIXED_BYPASS) then
                  valid(int(write_ad(i))) <= write_data(i)(32);
               else
                  valid_in(int(write_ad(i))) <= write_data(i)(32);
               end if;
            end if;
         end loop;
         for i in 0 to READ_PORTS - 1 loop
            if(read_as(i) = '0') then
               cur_read_ad(i) <= read_ad(i);
            end if;
         end loop;

         if(reset = '1') then
            valid <= (others => '1');
            valid_in <= (others => '1');
         end if;

         valid(0) <= '1'; -- r0 ($zero) is always valid
      end if;
   end process;
end architecture;
