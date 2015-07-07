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

library ieee, z48common;
use ieee.std_logic_1164.all, ieee.std_logic_unsigned.all, ieee.numeric_std.all, z48common.z48common.all;

entity mbox is
   port(
      clock                   :  in       std_logic;
      reset                   :  in       std_logic;

      mem_adr                 :  in       std_logic_vector(0 downto 0);
      mem_out                 :  out      std_logic_vector(31 downto 0);
      mem_in                  :  in       std_logic_vector(31 downto 0);
      mem_rd                  :  in       std_logic;
      mem_wr                  :  in       std_logic;

      irq                     :  out      std_logic
   );
end;

architecture mbox of mbox is
   signal flags               :  std_logic_vector(31 downto 0);
begin
   irq <= '1' when any_bit_set(flags) else '0';

   process(clock) is begin
      if(rising_edge(clock)) then
         if(mem_wr = '1') then
            for i in flags'range loop
               if(mem_in(i) = '1') then
                  flags(i) <= not mem_adr(0);
               end if;
            end loop;
         end if;

         mem_out <= flags;
         if(mem_adr(0) = '1' and mem_rd = '1') then
            flags <= (others => '0');
         end if;

         if(reset = '1') then
            flags <= (others => '0');
         end if;
      end if;
   end process;
end;
