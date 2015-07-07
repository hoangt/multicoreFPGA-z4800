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

library ieee, lpm, z48common; use ieee.std_logic_1164.all, ieee.std_logic_unsigned.all, ieee.std_logic_arith.all, lpm.lpm_components.all, z48common.z48common.all;


entity z48rastack is
   generic(
      ENTRIES:                   natural
   );
   port(
      clock:                     in       std_logic;
      reset:                     in       std_logic;
      cke:                       in       std_logic;

      ra_in:                     in       word;
      push:                      in       std_logic;
      ra_out:                    out      word;
      pop:                       in       std_logic
   );
end entity;

architecture z48rastack of z48rastack is
   type stack_t is array(ENTRIES - 1 downto 0) of word;
   signal stack:                 stack_t;
   signal top:                   integer range 0 to ENTRIES - 1;
begin
   ra_out <= stack(top - 1);

   process(clock) is begin
      if(rising_edge(clock)) then
         if(cke = '1') then
            if(push = '1') then
               stack(top) <= ra_in;
               top <= top + 1;
            elsif(pop = '1') then
               top <= top - 1;
            end if;
         end if;

         -- synch reset
         if(reset = '1') then
            top <= 0;
         end if;
      end if;
   end process;
end architecture;
