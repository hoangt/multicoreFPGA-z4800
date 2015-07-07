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

entity fifo is
   generic(
      WIDTH:                        integer;
      LENGTH:                       integer;
      EARLY_FULL:                   boolean := false
   );
   port(
      clock, rst:                   in std_logic;
      empty, full:                  out std_logic;
      read, write:                  in std_logic;
      d:                            in std_logic_vector(WIDTH - 1 downto 0);
      q:                            out std_logic_vector(WIDTH - 1 downto 0)
   );
end fifo;

architecture fifo of fifo is
   type fifo_t is array(LENGTH - 1 downto 0) of std_logic_vector(WIDTH - 1 downto 0);
   signal fifo: fifo_t;

   signal inp, outp: integer range LENGTH - 1 downto 0;
   signal count: integer range LENGTH downto 0;
begin
   q <= fifo(outp);
   empty <= '1' when count = 0 else '0';
   full <=  '1' when count = LENGTH else
            '1' when count = LENGTH - 1 and EARLY_FULL else
            '0';

   process(clock) is begin
      if(rising_edge(clock)) then
         if(write = '1') then
            fifo(inp) <= d;
            inp <= inp + 1;
            count <= count + 1;
         end if;
         if(read = '1') then
            outp <= outp + 1;
            count <= count - 1;
         end if;
         if(read = '1' and write = '1') then
            count <= count;
         end if;

         -- synch reset
         if(rst = '1') then
            inp <= 0;
            outp <= 0;
            count <= 0;
         end if;
      end if;
   end process;
end architecture fifo;
