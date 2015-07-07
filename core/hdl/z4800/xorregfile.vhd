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

entity xorregfile is
   generic(
      WRITE_PORTS:                  natural;
      READ_PORTS:                   natural
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
end entity;

architecture xorregfile of xorregfile is
   type reg_xbank_t is array(WRITE_PORTS - 1 downto 0) of regport_data_t(READ_PORTS - 1 downto 0);
   type reg_abank_t is array(WRITE_PORTS - 1 downto 0) of regport_data_t(WRITE_PORTS - 1 downto 0);

   signal s0_alien_read_ad:         regport_addr_t(WRITE_PORTS - 1 downto 0);

   signal s1_write_data:            regport_data_t(WRITE_PORTS - 1 downto 0);
   signal s1_alien_read_data:       reg_abank_t;
   signal s1_write_ad:              regport_addr_t(WRITE_PORTS - 1 downto 0);
   signal s1_xor_write_data:        regport_data_t(WRITE_PORTS - 1 downto 0);
   signal s1_alien_write_data:      regport_data_t(WRITE_PORTS - 1 downto 0);
   signal s1_write_en:              std_logic_vector(WRITE_PORTS - 1 downto 0);

   signal s0_xor_read_ad:           regport_addr_t(READ_PORTS - 1 downto 0);
   signal s0_xor_read_as:           std_logic_vector(READ_PORTS - 1 downto 0);

   signal s1_xor_read_data:         reg_xbank_t;
begin
   write_banks: for i in 0 to WRITE_PORTS - 1 generate
      alien_ports: for j in 0 to WRITE_PORTS - 1 generate
         alien_port: entity work.ramwrap generic map(
            WIDTH_A => 33,
            WIDTHAD_A => 5,
            WIDTH_B => 33,
            WIDTHAD_B => 5,
            OPERATION_MODE => "DUAL_PORT",
            MIXED_PORT_FORWARDING => true
         )
         port map(
            clock0 => clock,
            clock1 => clock,
            address_a => s1_write_ad(i),
            address_b => s0_alien_read_ad(j),
            q_b => s1_alien_read_data(i)(j),
            data_a => s1_alien_write_data(i),
            wren_a => s1_write_en(i)
         );
      end generate;

      xor_encode: process(s1_write_data(i), s1_alien_read_data(i)) is
         variable encoded:          vword;
      begin
         encoded := (32 => '1', 31 downto 0 => '0');
         for j in s1_alien_read_data'range loop
            if(i = j) then
               encoded := encoded xor s1_write_data(i);
            else
               encoded := encoded xor s1_alien_read_data(j)(i);
            end if;
         end loop;
         s1_xor_write_data(i) <= encoded;
         s1_alien_write_data(i) <= encoded;
      end process;

      xor_ports: for j in 0 to READ_PORTS - 1 generate
         xor_port: entity work.ramwrap generic map(
            WIDTH_A => 33,
            WIDTHAD_A => 5,
            WIDTH_B => 33,
            WIDTHAD_B => 5,
            OPERATION_MODE => "DUAL_PORT",
            MIXED_PORT_FORWARDING => true
         )
         port map(
            clock0 => clock,
            clock1 => clock,
            address_a => s1_write_ad(i),
            address_b => s0_xor_read_ad(j),
            addressstall_b => s0_xor_read_as(j),
            q_b => s1_xor_read_data(i)(j),
            data_a => s1_xor_write_data(i),
            wren_a => s1_write_en(i)
         );
      end generate;
   end generate;

   read_banks: for i in 0 to READ_PORTS - 1 generate
      xor_decode: process(s1_xor_read_data) is
         variable decoded:          vword;
      begin
         decoded := (32 => '1', 31 downto 0 => '0');
         for j in s1_xor_read_data'range loop
            decoded := decoded xor s1_xor_read_data(j)(i);
         end loop;
         read_data(i) <= decoded;
      end process;
   end generate;

   s0_alien_read_ad <= write_ad;
   s0_xor_read_ad <= read_ad;
   s0_xor_read_as <= read_as;
   process(clock) is begin
      if(rising_edge(clock)) then
         s1_write_ad <= write_ad;
         s1_write_data <= write_data;
         s1_write_en <= write_en;
      end if;
   end process;
end architecture;
