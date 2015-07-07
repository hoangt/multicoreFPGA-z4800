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

entity sevenseg is
   port(
      ain                           : in std_logic_vector(3 downto 0);
      aout                          : out std_logic_vector(6 downto 0);
      blank                         : in std_logic := '0'
   );
end entity;

architecture decoder of sevenseg is 
begin
  aout <= "1111111" when blank = '1' else
          "1000000" when ain="0000" else
          "1111001" when ain="0001" else
          "0100100" when ain="0010" else
          "0110000" when ain="0011" else
          "0011001" when ain="0100" else
          "0010010" when ain="0101" else
          "0000010" when ain="0110" else
          "1111000" when ain="0111" else
          "0000000" when ain="1000" else
          "0011000" when ain="1001" else
          "0001000" when ain="1010" else
          "0000011" when ain="1011" else
          "1000110" when ain="1100" else
          "0100001" when ain="1101" else
          "0000110" when ain="1110" else
          "0001110" when ain="1111" else
          "1111111";
end architecture;
