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

library ieee, lpm, altera_mf; use ieee.std_logic_1164.all, ieee.std_logic_unsigned.all, ieee.std_logic_arith.all, lpm.lpm_components.all, altera_mf.altera_mf_components.all;


entity camcell is
   generic(
      IN_LENGTH:                 integer
   );
   port(
      clock:                     in std_logic;
      rst:                       in std_logic;

      pattern:                   in std_logic_vector(IN_LENGTH - 1 downto 0);
      mask:                      in std_logic_vector(IN_LENGTH - 1 downto 0);
      write:                     in std_logic;
      match:                     out std_logic
   );
end entity;

architecture camcell of camcell is
   signal r_pattern, r_mask:     std_logic_vector(IN_LENGTH - 1 downto 0);
   signal valid:                 std_logic;
begin
   process(clock) is begin
      if(rising_edge(clock)) then
         match <= '0';
         if(write = '1') then
            r_pattern <= pattern;
            r_mask <= mask;
            valid <= '1';
         end if;
         if((r_pattern and r_mask) = (pattern and r_mask)) then
            match <= valid;
         end if;
         if(rst = '1') then
            valid <= '0';
         end if;
      end if;
   end process;
end architecture;
