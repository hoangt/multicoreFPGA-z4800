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

entity delay_chain is
   generic(
      LENGTH                  :  natural
   );
   port(
      clk                     :  in       std_logic;
      d                       :  in       std_logic_vector;
      q                       :  out      std_logic_vector
   );
end;

architecture delay_chain of delay_chain is
   type delay_t is array(LENGTH downto 0) of std_logic_vector(d'range);
   signal delay               :  delay_t;
begin
   process(clk) is begin
      if(rising_edge(clk)) then
         for i in delay'high downto delay'low + 1 loop
            delay(i) <= delay(i - 1);
         end loop;
      end if;
   end process;
   delay(0) <= d;
   q <= delay(LENGTH);
end;
