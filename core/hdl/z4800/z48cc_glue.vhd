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

entity z48cc_glue is
   generic(
      WIDTH:                        natural;
      ICACHE_WAYS:                  natural;
      DCACHE_WAYS:                  natural;
      HINT_ICACHE_SHARE:            boolean
   );
   port(
      clock:                        in std_logic;
      rst:                          in std_logic;

      l1_miss_addr:                 out word;
      l1_miss_valid:                out std_logic;
      l1_miss_minstate:             out cache_state_t;
      l1_miss_curstate:             out cache_state_t;
      l1_miss_way:                  out std_logic_vector(log2c(DCACHE_WAYS + ICACHE_WAYS) - 1 downto 0);
      l1_hint_share:                out std_logic;

      l1_tag_addr:                  in word;
      l1_way_mask:                  in std_logic_vector(DCACHE_WAYS + ICACHE_WAYS - 1 downto 0);
      l1_tag_as:                    in std_logic;
      l1_data_addr:                 in word;
      l1_data_as:                   in std_logic;
      l1_stag_addr:                 in word;
      l1_stag_as:                   in std_logic;

      l1_u_data:                    in std_logic_vector(WIDTH - 1 downto 0);
      l1_u_data_we:                 in std_logic_vector(DCACHE_WAYS + ICACHE_WAYS - 1 downto 0);
      l1_u_tag_we:                  in std_logic_vector(DCACHE_WAYS + ICACHE_WAYS - 1 downto 0);
   
      l1_d_tag_match:               out std_logic_vector(DCACHE_WAYS + ICACHE_WAYS - 1 downto 0);
      l1_d_tag_dirty:               out std_logic_vector(DCACHE_WAYS + ICACHE_WAYS - 1 downto 0);

      l1_d_stag_match:              out std_logic_vector(DCACHE_WAYS + ICACHE_WAYS - 1 downto 0);
      l1_d_stag_excl:               out std_logic_vector(DCACHE_WAYS + ICACHE_WAYS - 1 downto 0);

      d_miss_addr:                  in word;
      d_miss_valid:                 in std_logic;
      d_miss_minstate:              in cache_state_t;
      d_miss_curstate:              in cache_state_t;
      d_miss_way:                   in std_logic_vector(log2c(DCACHE_WAYS) - 1 downto 0);

      i_miss_addr:                  in word;
      i_miss_valid:                 in std_logic;
      i_miss_minstate:              in cache_state_t;
      i_miss_curstate:              in cache_state_t;
      i_miss_way:                   in std_logic_vector(log2c(ICACHE_WAYS) - 1 downto 0);

      d_tag_addr:                   out word;
      d_tag_as:                     out std_logic;
      d_tag_match:                  in std_logic_vector(DCACHE_WAYS - 1 downto 0);
      d_tag_dirty:                  in std_logic_vector(DCACHE_WAYS - 1 downto 0);
      d_tag_oe:                     out std_logic_vector(DCACHE_WAYS - 1 downto 0);
      d_tag_we:                     out std_logic_vector(DCACHE_WAYS - 1 downto 0);

      d_data_addr:                  out word;
      d_data_as:                    out std_logic;
      d_data_data:                  out std_logic_vector(WIDTH - 1 downto 0);
      d_data_oe:                    out std_logic_vector(DCACHE_WAYS - 1 downto 0);
      d_data_we:                    out std_logic_vector(DCACHE_WAYS - 1 downto 0);

      d_stag_addr:                  out word;
      d_stag_as:                    out std_logic;
      d_stag_match:                 in std_logic_vector(DCACHE_WAYS - 1 downto 0);
      d_stag_excl:                  in std_logic_vector(DCACHE_WAYS - 1 downto 0);

      i_tag_addr:                   out word;
      i_tag_as:                     out std_logic;
      i_tag_match:                  in std_logic_vector(ICACHE_WAYS - 1 downto 0);
      i_tag_dirty:                  in std_logic_vector(ICACHE_WAYS - 1 downto 0);
      i_tag_oe:                     out std_logic_vector(ICACHE_WAYS - 1 downto 0);
      i_tag_we:                     out std_logic_vector(ICACHE_WAYS - 1 downto 0);

      i_data_addr:                  out word;
      i_data_as:                    out std_logic;
      i_data_data:                  out std_logic_vector(WIDTH - 1 downto 0);
      i_data_oe:                    out std_logic_vector(ICACHE_WAYS - 1 downto 0);
      i_data_we:                    out std_logic_vector(ICACHE_WAYS - 1 downto 0);

      i_stag_addr:                  out word;
      i_stag_as:                    out std_logic;
      i_stag_match:                 in std_logic_vector(ICACHE_WAYS - 1 downto 0);
      i_stag_excl:                  in std_logic_vector(ICACHE_WAYS - 1 downto 0)
   );
end entity;

architecture z48cc_glue of z48cc_glue is
   constant DCACHE_WAY_OFFSET:      natural := 0;
   constant ICACHE_WAY_OFFSET:      natural := DCACHE_WAYS;

   function is_dcache(way: integer) return boolean is begin
      return way < ICACHE_WAY_OFFSET;
   end function;
   function is_icache(way: integer) return boolean is begin
      return not is_dcache(way);
   end function;

   signal rr_prio:                  std_logic;
   signal sel_d_miss, sel_i_miss:   std_logic;
begin
   sel_d_miss <=
      d_miss_valid when i_miss_valid = '0' else
      d_miss_valid when rr_prio = '0' else
      '0';
   sel_i_miss <=
      i_miss_valid when d_miss_valid = '0' else
      i_miss_valid when rr_prio = '1' else
      '0';

   l1_miss_addr <=
      d_miss_addr when sel_d_miss = '1' else
      i_miss_addr when sel_i_miss = '1' else
      (others => '-');
   l1_miss_valid <=
      d_miss_valid when sel_d_miss = '1' else
      i_miss_valid when sel_i_miss = '1' else
      '0';
   l1_miss_minstate <=
      d_miss_minstate when sel_d_miss = '1' else
      i_miss_minstate when sel_i_miss = '1' else
      (others => '-');
   l1_miss_curstate <=
      d_miss_curstate when sel_d_miss = '1' else
      i_miss_curstate when sel_i_miss = '1' else
      (others => '-');
   l1_miss_way <=
      vec(int(d_miss_way) + DCACHE_WAY_OFFSET, l1_miss_way'length) when sel_d_miss = '1' else
      vec(int(i_miss_way) + ICACHE_WAY_OFFSET, l1_miss_way'length) when sel_i_miss = '1' else
      (others => '-');
   l1_hint_share <=
      '0' when HINT_ICACHE_SHARE else
      sel_i_miss;

   d_tag_addr <= l1_tag_addr;
   d_tag_as <= l1_tag_as;
   d_tag_we <= l1_u_tag_we(DCACHE_WAY_OFFSET + DCACHE_WAYS - 1 downto DCACHE_WAY_OFFSET);
   d_data_addr <= l1_data_addr;
   d_data_as <= l1_data_as;
   d_data_data <= l1_u_data;
   d_data_we <= l1_u_data_we(DCACHE_WAY_OFFSET + DCACHE_WAYS - 1 downto DCACHE_WAY_OFFSET);
   d_stag_addr <= l1_stag_addr;
   d_stag_as <= l1_stag_as;

   i_tag_addr <= l1_tag_addr;
   i_tag_as <= l1_tag_as;
   i_tag_we <= l1_u_tag_we(ICACHE_WAY_OFFSET + ICACHE_WAYS - 1 downto ICACHE_WAY_OFFSET);
   i_data_addr <= l1_data_addr;
   i_data_as <= l1_data_as;
   i_data_data <= l1_u_data;
   i_data_we <= l1_u_data_we(ICACHE_WAY_OFFSET + ICACHE_WAYS - 1 downto ICACHE_WAY_OFFSET);
   i_stag_addr <= l1_stag_addr;
   i_stag_as <= l1_stag_as;

   l1_d_tag_match(DCACHE_WAY_OFFSET + DCACHE_WAYS - 1 downto DCACHE_WAY_OFFSET) <= d_tag_match;
   l1_d_tag_dirty(DCACHE_WAY_OFFSET + DCACHE_WAYS - 1 downto DCACHE_WAY_OFFSET) <= d_tag_dirty;
   l1_d_tag_match(ICACHE_WAY_OFFSET + ICACHE_WAYS - 1 downto ICACHE_WAY_OFFSET) <= i_tag_match;
   l1_d_tag_dirty(ICACHE_WAY_OFFSET + ICACHE_WAYS - 1 downto ICACHE_WAY_OFFSET) <= i_tag_dirty;

   l1_d_stag_match(DCACHE_WAY_OFFSET + DCACHE_WAYS - 1 downto DCACHE_WAY_OFFSET) <= d_stag_match;
   l1_d_stag_excl(DCACHE_WAY_OFFSET + DCACHE_WAYS - 1 downto DCACHE_WAY_OFFSET) <= d_stag_excl;
   l1_d_stag_match(ICACHE_WAY_OFFSET + ICACHE_WAYS - 1 downto ICACHE_WAY_OFFSET) <= i_stag_match;
   l1_d_stag_excl(ICACHE_WAY_OFFSET + ICACHE_WAYS - 1 downto ICACHE_WAY_OFFSET) <= i_stag_excl;

   d_tag_oe <= l1_way_mask(DCACHE_WAY_OFFSET + DCACHE_WAYS - 1 downto DCACHE_WAY_OFFSET);
   d_data_oe <= l1_way_mask(DCACHE_WAY_OFFSET + DCACHE_WAYS - 1 downto DCACHE_WAY_OFFSET);
   i_tag_oe <= l1_way_mask(ICACHE_WAY_OFFSET + ICACHE_WAYS - 1 downto ICACHE_WAY_OFFSET);
   i_data_oe <= l1_way_mask(ICACHE_WAY_OFFSET + ICACHE_WAYS - 1 downto ICACHE_WAY_OFFSET);

   process(clock) is begin
      if(rising_edge(clock)) then
         rr_prio <= not rr_prio;
      end if;
   end process;
end architecture;
