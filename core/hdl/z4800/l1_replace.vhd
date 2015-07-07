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

entity l1_replace is
   generic(
      OFFSET_BITS:                  natural;
      WAY_BITS:                     natural;
      WAYS:                         natural;
      REPLACE_TYPE:                 string;
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

architecture l1_replace of l1_replace is begin
   direct_mapped: if(WAYS = 1) generate
      fill_way <= (others => '0');
   end generate;
   set_assoc: if(WAYS > 1) generate
      replace_random: if(REPLACE_TYPE = "RANDOM") generate
         l1_replace_random: entity work.l1_replace_random generic map(
            OFFSET_BITS => OFFSET_BITS,
            WAY_BITS => WAY_BITS,
            WAYS => WAYS
         )
         port map(
            clock => clock,
            rst => rst,

            ref_addr => ref_addr,
            ref_way => ref_way,
            ref_valid => ref_valid,

            fill_addr => fill_addr,
            fill_way => fill_way
         );
      end generate;
      replace_lru: if(REPLACE_TYPE = "LRU") generate
         l1_replace_lru: entity work.l1_replace_lru generic map(
            OFFSET_BITS => OFFSET_BITS,
            WAY_BITS => WAY_BITS,
            WAYS => WAYS
         )
         port map(
            clock => clock,
            rst => rst,

            ref_addr => ref_addr,
            ref_way => ref_way,
            ref_valid => ref_valid,

            fill_addr => fill_addr,
            fill_way => fill_way
         );
      end generate;
      replace_plru: if(REPLACE_TYPE = "PLRU") generate
         l1_replace_plru: entity work.l1_replace_plru generic map(
            OFFSET_BITS => OFFSET_BITS,
            WAY_BITS => WAY_BITS,
            WAYS => WAYS
         )
         port map(
            clock => clock,
            rst => rst,

            ref_addr => ref_addr,
            ref_way => ref_way,
            ref_valid => ref_valid,

            fill_addr => fill_addr,
            fill_way => fill_way
         );
      end generate;
      replace_randomhybrid: if(REPLACE_TYPE = "RANDOMHYBRID") generate
         l1_replace_randomhybrid: entity work.l1_replace_randomhybrid generic map(
            OFFSET_BITS => OFFSET_BITS,
            WAY_BITS => WAY_BITS,
            WAYS => WAYS,
            SUB_REPLACE_TYPE => SUB_REPLACE_TYPE,
            BLOCK_FACTOR => BLOCK_FACTOR
         )
         port map(
            clock => clock,
            rst => rst,

            ref_addr => ref_addr,
            ref_way => ref_way,
            ref_valid => ref_valid,

            fill_addr => fill_addr,
            fill_way => fill_way
         );
      end generate;
   end generate;

   assert
      REPLACE_TYPE = "RANDOM" or
      REPLACE_TYPE = "LRU" or
      REPLACE_TYPE = "PLRU" or
      REPLACE_TYPE = "RANDOMHYBRID"
      report "Must select valid REPLACE_TYPE" severity error;
end architecture;
