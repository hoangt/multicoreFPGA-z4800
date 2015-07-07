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

entity mul_comb is
   generic(
      BITS:                      natural;
      CYCLES:                    natural
   );
   port(
      clock:                     in       std_logic;
      rst:                       in       std_logic;

      start:                     in       std_logic;
      done:                      out      std_logic;
      
      a:                         in       std_logic_vector(BITS - 1 downto 0);
      b:                         in       std_logic_vector(BITS - 1 downto 0);
      o:                         out      std_logic_vector((BITS * 2) - 1 downto 0)
   );
end;

architecture mul_comb of mul_comb is
   attribute altera_attribute:   string;
   attribute altera_attribute of o: signal is sdc_multicycle_voodoo("*|mul_comb:*|o*", CYCLES);

   signal p:                     std_logic_vector(o'range);
   signal run:                   std_logic;
begin
   multiplier: lpm_mult generic map(
      LPM_WIDTHA => BITS,
      LPM_WIDTHB => BITS,
      LPM_WIDTHP => BITS * 2,
      LPM_REPRESENTATION => "SIGNED"
   )
   port map(
      dataa => a,
      datab => b,
      result => p
   );

   mul_timer: process(clock) is
      variable count:         integer range 0 to CYCLES - 1;
   begin
      if(rising_edge(clock)) then
         o <= p;
         done <= '0';

         if(start = '1') then
            count := count'high;
            run <= '1';
         end if;

         if(run = '1') then
            if(count = 0) then
               done <= '1';
               run <= '0';
            end if;
            count := count - 1;
         end if;

         if(rst = '1') then
            done <= '0';
            run <= '0';
         end if;
      end if;
   end process;
end architecture;
