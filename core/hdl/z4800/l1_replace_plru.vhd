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

entity l1_replace_plru is
   generic(
      OFFSET_BITS:                  natural;
      WAY_BITS:                     natural;
      WAYS:                         natural
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

architecture l1_replace_plru of l1_replace_plru is
   constant WAY_STATE_BITS:         natural := WAYS - 1;

   type ref_t is record
      addr: std_logic_vector(OFFSET_BITS - 1 downto 0);
      way: std_logic_vector(WAY_BITS - 1 downto 0);
      valid: std_logic;
   end record;
   type ref_a_t is array(0 to 1) of ref_t;
   signal ref:                      ref_a_t;

   function get_lru(curstate: std_logic_vector) return std_logic_vector is
      constant split: integer := ((curstate'length - 1) / 2) + curstate'low;
      variable selector: std_logic;
   begin
      selector := curstate(curstate'high);
      if(curstate'length = 1) then
         return (0 downto 0 => selector);
      else
         if(selector = '1') then
            return '1' & get_lru(curstate(curstate'high - 1 downto split));
         else
            return '0' & get_lru(curstate(split - 1 downto curstate'low));
         end if;
      end if;
   end function;

   function update_lru(curstate: std_logic_vector; ref_way: std_logic_vector) return std_logic_vector is
      constant split: integer := ((curstate'length - 1) / 2) + curstate'low;
      variable newstate: std_logic_vector(curstate'range);
   begin
      newstate := curstate;
      newstate(newstate'high) := not ref_way(ref_way'high);
      if(newstate'length = 1) then
         return newstate;
      else
         if(ref_way(ref_way'high) = '1') then
            return newstate(newstate'high) & update_lru(newstate(newstate'high - 1 downto split), ref_way(ref_way'high - 1 downto ref_way'low)) & newstate(split - 1 downto newstate'low);
         else
            return newstate(newstate'high) & newstate(newstate'high - 1 downto split) & update_lru(newstate(split - 1 downto newstate'low), ref_way(ref_way'high - 1 downto ref_way'low));
         end if;
      end if;
   end function;

   signal lru_addr_a, lru_addr_b, lru_addr_c: std_logic_vector(OFFSET_BITS - 1 downto 0);
   signal lru_data_a, lru_q_b, lru_q_c: std_logic_vector(WAY_STATE_BITS - 1 downto 0);
   signal lru_we_a:                 std_logic;
begin
   assert((2 ** log2c(WAYS)) = WAYS) report "PLRU replacement requires power-of-2 way count" severity error;

   ref(0).addr <= ref_addr;
   ref(0).way <= ref_way;
   ref(0).valid <= ref_valid;

   lrustate_ab: entity work.ramwrap generic map(
      WIDTH_A => WAY_STATE_BITS,
      WIDTHAD_A => OFFSET_BITS,
      WIDTH_B => WAY_STATE_BITS,
      WIDTHAD_B => OFFSET_BITS,
      OPERATION_MODE => "DUAL_PORT",
      MIXED_PORT_FORWARDING => true
   )
   port map(
      clock0 => clock,
      clock1 => clock,
      address_a => lru_addr_a,
      address_b => lru_addr_b,
      data_a => lru_data_a,
      wren_a => lru_we_a,
      q_b => lru_q_b
   );
   lrustate_ac: entity work.ramwrap generic map(
      WIDTH_A => WAY_STATE_BITS,
      WIDTHAD_A => OFFSET_BITS,
      WIDTH_B => WAY_STATE_BITS,
      WIDTHAD_B => OFFSET_BITS,
      OPERATION_MODE => "DUAL_PORT",
      MIXED_PORT_FORWARDING => true
   )
   port map(
      clock0 => clock,
      clock1 => clock,
      address_a => lru_addr_a,
      address_b => lru_addr_c,
      data_a => lru_data_a,
      wren_a => lru_we_a,
      q_b => lru_q_c
   );

   -- pipelined lru update (reference/hit side)
   lru_addr_b <= ref(0).addr;
   lru_addr_a <= ref(1).addr;
   lru_data_a <= update_lru(lru_q_b, ref(1).way);
   lru_we_a <= ref(1).valid;

   -- pipelined lru lookup (refill side)
   lru_addr_c <= fill_addr;
   fill_way <= get_lru(lru_q_c);

   -- pipeline registers
   process(clock) is begin
      if(rising_edge(clock)) then
         for i in ref'high downto ref'low + 1 loop
            ref(i) <= ref(i - 1);
         end loop;
      end if;
   end process;
end architecture;
