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


entity bshift_stage is
   generic(
      WIDTH:                     integer;
      AMOUNT:                    integer
   );
   port(
      data:                      in       std_logic_vector(WIDTH - 1 downto 0);
      shift:                     in       std_logic;
      right_nleft:               in       std_logic;
      logic_narith:              in       std_logic;
      result:                    out      std_logic_vector(WIDTH - 1 downto 0)
   );
end entity;

architecture bshift_stage of bshift_stage is
   constant RWIDTH: integer := WIDTH - AMOUNT;
   signal right_shifted, left_shifted: std_logic_vector(RWIDTH - 1 downto 0);

   signal rfill, lfill: std_logic_vector(AMOUNT - 1 downto 0);
begin
   rfill <= (others => '0') when logic_narith = '1' else (others => data(data'high));
   lfill <= (others => '0');
   right_shifted <= data(data'high downto data'low + AMOUNT);
   left_shifted <= data(data'high - AMOUNT downto data'low);
   result <=   data when shift = '0' else
               rfill & right_shifted when right_nleft = '1' else
               left_shifted & lfill;
end architecture;
