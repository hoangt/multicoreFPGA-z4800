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

entity l1_replace_random is
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

architecture l1_replace_random of l1_replace_random is
   signal rotor                     :  integer range 0 to WAYS - 1;
begin
   lfsr: entity work.lfsr generic map(
      BITS => 24,
      TAPS => (24, 23, 22, 17)
   )
   port map(
      clock => clock,
      rst => rst,
      q(fill_way'range) => fill_way
   );
end architecture;
