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
library z48common;
use z48common.z48common.all;

entity lfsr is
   generic(
      BITS:                         natural;
      TAPS:                         intarray_t -- see Xilinx xapp052 for list
   );
   port(
      clock:                        in std_logic;
      rst:                          in std_logic;

      q:                            buffer std_logic_vector(BITS - 1 downto 0)
   );
end entity;

architecture lfsr of lfsr is
   signal d:                        std_logic_vector(q'range);
begin
   next_state: process(q) is
      variable new_bit:             std_logic;
   begin
      new_bit := '1'; -- XNOR-form input
      for i in TAPS'range loop
         new_bit := new_bit xor q(TAPS(i) - 1);
      end loop;
      d <= q(q'high - 1 downto q'low) & new_bit;
   end process;

   process(clock) is begin
      if(rising_edge(clock)) then
         q <= d;
         if(rst = '1') then
            q <= (others => '0');
         end if;
      end if;
   end process;
end architecture;
