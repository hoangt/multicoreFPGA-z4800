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

library ieee, lpm, altera_mf; use ieee.std_logic_1164.all, ieee.std_logic_unsigned.all, ieee.std_logic_arith.all, lpm.lpm_components.all, altera_mf.altera_mf_components.all;


entity cam is
   generic(
      SIZE:                      integer;
      IN_LENGTH:                 integer;
      OUT_LENGTH:                integer;
      DETECT_MULTIPLE_MATCH:     boolean := false
   );
   port(
      clock:                     in std_logic;
      rst:                       in std_logic;

      pattern:                   in std_logic_vector(IN_LENGTH - 1 downto 0);
      mask:                      in std_logic_vector(IN_LENGTH - 1 downto 0);
      index:                     in std_logic_vector(OUT_LENGTH - 1 downto 0);
      write:                     in std_logic;
      match:                     out std_logic;
      match_index:               out std_logic_vector(OUT_LENGTH - 1 downto 0);
      multimatch:                out std_logic
   );
end entity;

architecture cam of cam is
   signal writes, matches:       std_logic_vector(SIZE - 1 downto 0);
begin
   cells: for i in 0 to SIZE - 1 generate
      cell: entity work.camcell generic map(
         IN_LENGTH => IN_LENGTH
      )
      port map(
         clock => clock,
         rst => rst,
         pattern => pattern,
         mask => mask,
         write => writes(i),
         match => matches(i)
      );
      writes(i) <= write when conv_integer(unsigned(index)) = i else '0';
   end generate;

   process(matches) is
      variable match_count: integer range 0 to SIZE;
   begin
      match <= '0';
      match_index <= (others => '-');
      match_count := 0;
      for i in SIZE - 1 downto 0 loop
         if(matches(i) = '1') then
            match <= '1';
            match_index <= conv_std_logic_vector(i, OUT_LENGTH);
            match_count := match_count + 1;
         end if;
      end loop;
      multimatch <= '0';
      if(DETECT_MULTIPLE_MATCH and match_count > 1) then
         multimatch <= '1';
      end if;
   end process;
end architecture;
