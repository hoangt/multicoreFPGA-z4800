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


entity bshift is
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

architecture bshift of bshift is
   type intermed_t is array(DISTBITS downto 0) of std_logic_vector(WIDTH - 1 downto 0);
   signal intermed:              intermed_t;
begin
   intermed(DISTBITS) <= data;
   stages: for i in DISTBITS - 1 downto 0 generate
      stage: entity work.bshift_stage generic map(
         WIDTH => WIDTH,
         AMOUNT => 2 ** i
      )
      port map(
         data => intermed(i + 1),
         shift => dist(i),
         right_nleft => right_nleft,
         logic_narith => logic_narith,
         result => intermed(i)
      );
   end generate;
   result <= intermed(0);
end architecture;
