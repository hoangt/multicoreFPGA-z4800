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

entity dspshift is
   generic(
      WIDTH:                     integer;
      DISTBITS:                  integer
   );
   port(
      data:                      in       std_logic_vector(WIDTH - 1 downto 0);
      dist:                      in       std_logic_vector(DISTBITS - 1 downto 0);
      right_nleft:               in       std_logic;
      logic_narith:              in       std_logic;
      result:                    out      std_logic_vector(WIDTH - 1 downto 0)
   );
end entity;

architecture dspshift of dspshift is
   signal dist_pow:              std_logic_vector(WIDTH - 1 downto 0);
   signal mula, mulb:            std_logic_vector(WIDTH + 1 - 1 downto 0);
   signal mulr:                  std_logic_vector((WIDTH + 1) * 2 - 1 downto 0);
begin
   process(dist, right_nleft) is begin
      dist_pow <= (others => '0');
      if(right_nleft = '1') then
         dist_pow(WIDTH - int(dist)) <= '1';
      else
         dist_pow(int(dist)) <= '1';
      end if;
   end process;

   mula <=  '0' & data when logic_narith = '1' else
            data(data'high) & data;
   mulb <=  '0' & dist_pow;
   mult: lpm_mult generic map(
      LPM_WIDTHA => WIDTH + 1,
      LPM_WIDTHB => WIDTH + 1,
      LPM_WIDTHP => (WIDTH + 1) * 2,
      LPM_REPRESENTATION => "SIGNED"
   )
   port map(
      dataa => mula,
      datab => mulb,
      result => mulr
   );
   result <=   mulr((WIDTH * 2) - 1 downto WIDTH) when right_nleft = '1' else
               mulr(WIDTH - 1 downto 0);
end architecture;
