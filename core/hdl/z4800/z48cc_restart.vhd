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
library altera;
use altera.altera_syn_attributes.all;
library z48common;
use z48common.z48common.all;

entity z48cc_restart is
   generic(
      WAYS:                         natural;
      WAY_BITS:                     natural;
      RBLKL:                        natural;
      RBLKH:                        natural;
      OFFL:                         natural;
      OFFH:                         natural;
      TAGL:                         natural;
      TAGH:                         natural
   );
   port(
      clock:                        in std_logic;
      rst:                          in std_logic;

      mshr_addr:                    in word;
      mshr_valid:                   in std_logic;
      mshr_insstate:                in cache_state_t;

      miss_addr:                    in word;
      miss_valid:                   in std_logic;
      miss_minstate:                in cache_state_t;

      l1_way_mask:                  in std_logic_vector(WAYS - 1 downto 0);

      l1_data_addr:                 in word;
      l1_data_as:                   in std_logic;
      l1_u_data_we:                 in std_logic_vector(WAYS - 1 downto 0);

      l1_u_tag_we:                  in std_logic_vector(WAYS - 1 downto 0);

      restart_way:                  out std_logic_vector(WAY_BITS - 1 downto 0);
      restart_ok:                   out std_logic
   );
end entity;

architecture z48cc_restart of z48cc_restart is
   constant RBLKBITS:               natural := RBLKH - RBLKL + 1;
   constant RBLOCKS:                natural := 2 ** RBLKBITS;
   signal bitmap_next:              std_logic_vector(RBLOCKS - 1 downto 0);
   signal bitmap:                   std_logic_vector(RBLOCKS - 1 downto 0);

   signal l1_data_addr_r:           word;
begin
   
   restart_ok <=
      '0' when mshr_valid = '0' else
      '0' when mshr_addr(TAGH downto OFFL) /= miss_addr(TAGH downto OFFL) else
      '0' when not cache_state_test_access_ok(mshr_insstate, miss_minstate) else
      '0' when bitmap(int(miss_addr(RBLKH downto RBLKL))) = '0' else
      '1';

   process(clock) is
      variable cur_data_addr:       word;
   begin
      if(rising_edge(clock)) then
         bitmap <= bitmap_next; -- match M4K/M9K cross-port latency

         if(l1_data_as = '0') then
            l1_data_addr_r <= l1_data_addr;
            cur_data_addr := l1_data_addr;
         else
            cur_data_addr := l1_data_addr_r;
         end if;

         restart_way <= (others => '0');
         for i in 0 to WAYS - 1 loop
            if(l1_way_mask(i) = '1') then
               restart_way <= vec(i, restart_way'length);
            end if;
         end loop;
            
         if(any_bit_set(l1_u_data_we)) then
            bitmap_next(int(cur_data_addr(RBLKH downto RBLKL))) <= '1';
         end if;

         if(any_bit_set(l1_u_tag_we) or mshr_valid = '0') then
            bitmap_next <= (others => '0');
         end if;

         if(rst = '1') then
            bitmap_next <= (others => '0');
            bitmap <= (others => '0');
         end if;
      end if;
   end process;
end architecture;
