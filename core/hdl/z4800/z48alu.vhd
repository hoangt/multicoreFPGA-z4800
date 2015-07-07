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


entity z48alu is
   generic(
      SHIFT_TYPE:                string
   );
   port(
      clock:                     in       std_logic;
      rst:                       in       std_logic;
      op:                        in       aluop_t;
      u:                         in       std_logic;
      i0:                        in       word;
      i1:                        in       word;
      right_shift:               in       std_logic;
      o:                         buffer   word;
      v:                         buffer   std_logic;
      z:                         buffer   std_logic;
      n:                         buffer   std_logic
   );
end;

architecture z48alu of z48alu is
   signal addo:         std_logic_vector(32 downto 0);
   signal add_sub:      std_logic;
   signal logic_narith: std_logic;
   signal shifto:       word;

   signal i0ext, i1ext: std_logic_vector(32 downto 0);
begin
   assert(SHIFT_TYPE = "BSHIFT" or SHIFT_TYPE = "DSPSHIFT") report "Invalid SHIFT_TYPE" severity error;

   i0ext <= (i0(31) and not u) & i0;
   i1ext <= (i1(31) and not u) & i1;

   add_sub <= '1' when op = a_add else '0';
   addsub: lpm_add_sub generic map(
      LPM_REPRESENTATION => "SIGNED",
      LPM_WIDTH => 33
   )
   port map(
      dataa => i0ext,
      datab => i1ext,
      add_sub => add_sub,
      result => addo
   );
   v <= addo(32) xor addo(31);
   z <= '1' when addo(31 downto 0) = x"00000000" else '0';
   n <= addo(32);

   logic_narith <=   '1' when op = a_shl else
                     '0' when op = a_sha else
                     '-';
   bshift_gen: if(SHIFT_TYPE = "BSHIFT") generate
      shifter: entity work.bshift generic map(
         WIDTH => 32,
         DISTBITS => 5
      )
      port map(
         data => i0,
         dist => i1(4 downto 0),
         right_nleft => right_shift,
         logic_narith => logic_narith,
         result => shifto
      );
   end generate;
   dspshift_gen: if(SHIFT_TYPE = "DSPSHIFT") generate
      shifter: entity work.dspshift generic map(
         WIDTH => 32,
         DISTBITS => 5
      )
      port map(
         data => i0,
         dist => i1(4 downto 0),
         right_nleft => right_shift,
         logic_narith => logic_narith,
         result => shifto
      );
   end generate;

   o <=  addo(31 downto 0) when op = a_add or op = a_sub else
         shifto when op = a_shl or op = a_sha else
         i0 and i1 when op = a_and else
         i0 or i1 when op = a_or else
         i0 nor i1 when op = a_nor else
         i0 xor i1 when op = a_xor else
         i1 when op = a_nop1 else
         (31 downto 1 => '0') & n when op = a_slt else
         (others => '-');
end architecture;
