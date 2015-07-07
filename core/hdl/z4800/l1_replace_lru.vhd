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

entity l1_replace_lru is
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

architecture l1_replace_lru of l1_replace_lru is
   constant WAY_STATE_BITS          :  integer := log2c(fact(WAYS));

   function get_waystate(x: std_logic_vector) return std_logic_vector is begin
      return x(WAY_STATE_BITS + WAY_BITS - 1 downto WAY_BITS);
   end function;
   function get_way(x: std_logic_vector) return std_logic_vector is begin
      return x(WAY_BITS - 1 downto 0);
   end function;

   type ref_t is record
      addr: std_logic_vector(OFFSET_BITS - 1 downto 0);
      way: std_logic_vector(WAY_BITS - 1 downto 0);
      valid: std_logic;
   end record;
   type ref_a_t is array(0 to 1) of ref_t;
   signal ref:                      ref_a_t;

   signal lrulut_addr_a, lrulut_addr_b: std_logic_vector(WAY_STATE_BITS + WAY_BITS - 1 downto 0);
   signal lrulut_q_a, lrulut_q_b:   std_logic_vector(WAY_STATE_BITS + WAY_BITS - 1 downto 0);

   signal lru_addr_a, lru_addr_b, lru_addr_c: std_logic_vector(OFFSET_BITS - 1 downto 0);
   signal lru_data_a, lru_q_b, lru_q_c: std_logic_vector(WAY_STATE_BITS - 1 downto 0);
   signal lru_we_a:                 std_logic;
begin
   ref(0).addr <= ref_addr;
   ref(0).way <= ref_way;
   ref(0).valid <= ref_valid;

   lrulut: altsyncram generic map(
      WIDTH_A => WAY_STATE_BITS + WAY_BITS,
      WIDTHAD_A => WAY_STATE_BITS + WAY_BITS,
      WIDTH_B => WAY_STATE_BITS + WAY_BITS,
      WIDTHAD_B => WAY_STATE_BITS + WAY_BITS,
      INIT_FILE => "lru." & integer'image(WAYS) & "way.mif"
   )
   port map(
      clock0 => not clock,
      clock1 => not clock, -- sneaky hack to avoid taking 2 cycles
      address_a => lrulut_addr_a,
      address_b => lrulut_addr_b,
      q_a => lrulut_q_a,
      q_b => lrulut_q_b
   );

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
   lrulut_addr_a <= lru_q_b & ref(1).way;
   lru_addr_a <= ref(1).addr;
   lru_data_a <= get_waystate(lrulut_q_a);
   lru_we_a <= ref(1).valid;

   -- pipelined lru lookup (refill side)
   lru_addr_c <= fill_addr;
   lrulut_addr_b <= lru_q_c & (WAY_BITS - 1 downto 0 => '-');
   fill_way <= get_way(lrulut_q_b);

   -- pipeline registers
   process(clock) is begin
      if(rising_edge(clock)) then
         for i in ref'high downto ref'low + 1 loop
            ref(i) <= ref(i - 1);
         end loop;
      end if;
   end process;
end architecture;
