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

entity div_comb is
   generic(
      BITS:                      natural;
      CYCLES:                    natural
   );
   port(
      clock:                     in       std_logic;
      rst:                       in       std_logic;

      start:                     in       std_logic;
      done:                      out      std_logic;

      divisor:                   in       std_logic_vector(BITS - 1 downto 0);
      dividend:                  in       std_logic_vector(BITS - 1 downto 0);
      quotient:                  out      std_logic_vector(BITS - 1 downto 0);
      remainder:                 out      std_logic_vector(BITS - 1 downto 0)
   );
end;

architecture div_comb of div_comb is
   attribute altera_attribute:   string;
   attribute altera_attribute of quotient: signal is sdc_multicycle_voodoo("*|div_comb:*|quotient*", CYCLES);
   attribute altera_attribute of remainder: signal is sdc_multicycle_voodoo("*|div_comb:*|remainder*", CYCLES);

   signal divq, divr:            std_logic_vector(BITS - 1 downto 0);

   signal run:                   std_logic;
begin
   divider: lpm_divide generic map(
      LPM_WIDTHN => BITS,
      LPM_WIDTHD => BITS,
      LPM_NREPRESENTATION => "SIGNED",
      LPM_DREPRESENTATION => "SIGNED",
      LPM_HINT => "LPM_REMAINDERPOSITIVE=FALSE"
   )
   port map(
      numer => dividend,
      denom => divisor,
      quotient => divq,
      remain => divr
   );

   div_timer: process(clock) is
      variable count:         integer range 0 to CYCLES - 1;
   begin
      if(rising_edge(clock)) then
         remainder <= divr;
         quotient <= divq;

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
