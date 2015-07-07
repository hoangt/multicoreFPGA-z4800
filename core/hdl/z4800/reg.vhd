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

entity reg is
   generic(
      FORCE_CKE:                    boolean := true
   );
   port(
      clock:                        in std_logic;
      rst:                          in std_logic := '0';
      cke:                          in std_logic := '1';

      d:                            in std_logic_vector;
      q:                            out std_logic_vector
   );
end entity;

library altera;
use altera.altera_syn_attributes.all;

architecture reg of reg is
   signal q_int:                    std_logic_vector(d'range);

   -- force cke to be mapped as clock-enable
   attribute direct_enable of cke:  signal is FORCE_CKE;
begin
   process(clock) is begin
      if(rising_edge(clock)) then
         if(rst = '1') then
            q_int <= (others => '0');
         elsif(cke = '1') then
            q_int <= d;
         end if;
      end if;
   end process;

   q <= q_int;
end architecture;
