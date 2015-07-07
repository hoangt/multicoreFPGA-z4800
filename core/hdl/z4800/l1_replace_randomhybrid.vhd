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

entity l1_replace_randomhybrid is
   generic(
      OFFSET_BITS:                  natural;
      WAY_BITS:                     natural;
      WAYS:                         natural;
      SUB_REPLACE_TYPE:             string;
      BLOCK_FACTOR:                 natural
   );
   port(
      clock:                        in std_logic;
      rst:                          in std_logic;

      ref_addr:                     in std_logic_vector(OFFSET_BITS - 1 downto 0);
      ref_way:                      in std_logic_vector(WAY_BITS - 1 downto 0);
      ref_valid:                    in std_logic;

      fill_addr:                    in std_logic_vector(OFFSET_BITS - 1 downto 0);
      fill_way:                     out std_logic_vector(WAY_BITS - 1 downto 0)
   );
end entity;

architecture l1_replace_randomhybrid of l1_replace_randomhybrid is
   constant SUB_WAYS: integer := WAYS / BLOCK_FACTOR;
   constant SUB_WAY_BITS: integer := log2c(SUB_WAYS);
   constant RANDOM_WAYS: integer := BLOCK_FACTOR;
   constant RANDOM_WAY_BITS: integer := log2c(RANDOM_WAYS);
   type ref_t is record
      addr: std_logic_vector(OFFSET_BITS - 1 downto 0);
      way: std_logic_vector(WAY_BITS - 1 downto 0);
      valid: std_logic;
   end record;
   type ref_a_t is array(0 to 2) of ref_t;
   signal ref:                      ref_a_t;

   signal sub_ref_way, sub_fill_way: std_logic_vector(SUB_WAY_BITS - 1 downto 0);
   signal lfsr_out:                  std_logic_vector(RANDOM_WAY_BITS - 1 downto 0);
begin
   assert BLOCK_FACTOR >= 2 report "BLOCK_FACTOR must be at least 2" severity error;
   assert (2 ** log2c(BLOCK_FACTOR)) = BLOCK_FACTOR report "BLOCK_FACTOR must be power of 2" severity error;
   assert WAYS mod BLOCK_FACTOR = 0 report "WAYS must divide by BLOCK_FACTOR" severity error;
   assert SUB_REPLACE_TYPE /= "RANDOMHYBRID" report "can't stack RANDOMHYBRID instances" severity error;

   sub_replace: entity work.l1_replace generic map(
      OFFSET_BITS => OFFSET_BITS,
      WAY_BITS => SUB_WAY_BITS,
      WAYS => SUB_WAYS,
      REPLACE_TYPE => SUB_REPLACE_TYPE,
      SUB_REPLACE_TYPE => "",
      BLOCK_FACTOR => 1
   )
   port map(
      clock => clock,
      rst => rst,

      ref_addr => ref_addr,
      ref_way => sub_ref_way,
      ref_valid => ref_valid,

      fill_addr => fill_addr,
      fill_way => sub_fill_way
   );

   lfsr: entity work.lfsr generic map(
      BITS => 24,
      TAPS => (24, 23, 22, 17)
   )
   port map(
      clock => clock,
      rst => rst,
      q(lfsr_out'range) => lfsr_out
   );

   sub_ref_way <= vec(int(ref_way) / BLOCK_FACTOR, SUB_WAY_BITS);
   fill_way <= vec(int(sub_fill_way) * BLOCK_FACTOR + int(lfsr_out), WAY_BITS);

   -- pipeline registers
   process(clock) is begin
      if(rising_edge(clock)) then
         for i in ref'high downto ref'low + 1 loop
            ref(i) <= ref(i - 1);
         end loop;
      end if;
   end process;
end architecture;
