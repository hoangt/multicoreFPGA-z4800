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

library ieee, altera_mf;
use ieee.std_logic_1164.all;
use altera_mf.altera_mf_components.all;

entity ramwrap is
   generic(
      WIDTH_A:                      natural;
      WIDTHAD_A:                    natural;
      NUMWORDS_A:                   natural := 0;
      WIDTH_B:                      natural;
      WIDTHAD_B:                    natural;
      NUMWORDS_B:                   natural := 0;
      WIDTH_BYTEENA_A:              natural := 0;
      WIDTH_BYTEENA_B:              natural := 0;
      OPERATION_MODE:               string := "BIDIR_DUAL_PORT";
      MIXED_PORT_FORWARDING:        boolean := false
   );
   port(
      clock0, clock1:               in    std_logic;
      address_a:                    in    std_logic_vector(WIDTHAD_A - 1 downto 0);
      address_b:                    in    std_logic_vector(WIDTHAD_B - 1 downto 0);
      data_a:                       in    std_logic_vector(WIDTH_A - 1 downto 0) := (others => '-');
      data_b:                       in    std_logic_vector(WIDTH_B - 1 downto 0) := (others => '-');
      q_a:                          out   std_logic_vector(WIDTH_A - 1 downto 0);
      q_b:                          out   std_logic_vector(WIDTH_B - 1 downto 0);
      wren_a, wren_b:               in    std_logic := '0';
      byteena_a:                    in    std_logic_vector(WIDTH_BYTEENA_A - 1 downto 0) := (others => '1');
      byteena_b:                    in    std_logic_vector(WIDTH_BYTEENA_B - 1 downto 0) := (others => '1');
      addressstall_a, addressstall_b: in  std_logic := '0'
   );
end entity;

architecture ramwrap of ramwrap is
   impure function getwords_a return natural is begin
      if(NUMWORDS_A > 0) then
         return NUMWORDS_A;
      end if;
      return 2 ** WIDTHAD_A;
   end function;

   impure function getwords_b return natural is begin
      if(NUMWORDS_B > 0) then
         return NUMWORDS_B;
      end if;
      return 2 ** WIDTHAD_B;
   end function;

   constant WORDS_A:                natural := getwords_a;
   constant WORDS_B:                natural := getwords_b;

   signal q_a_int:                  std_logic_vector(WIDTH_A - 1 downto 0);
   signal q_b_int:                  std_logic_vector(WIDTH_B - 1 downto 0);

   signal wrdata_a:                 std_logic_vector(WIDTH_A - 1 downto 0);
   signal wr_a:                     std_logic;
   signal wad_a:                    std_logic_vector(WIDTHAD_A - 1 downto 0);
   signal wrdata_b:                 std_logic_vector(WIDTH_B - 1 downto 0);
   signal wr_b:                     std_logic;
   signal wad_b:                    std_logic_vector(WIDTHAD_B - 1 downto 0);
begin
   assert(not MIXED_PORT_FORWARDING or (WIDTH_A = WIDTH_B)) report "MIXED_PORT_FORWARDING not supported unless WIDTH_A = WIDTH_B" severity error;

   no_be: if(WIDTH_BYTEENA_A = 0 and WIDTH_BYTEENA_B = 0) generate
      ram: altsyncram generic map(
         WIDTH_A => WIDTH_A,
         WIDTHAD_A => WIDTHAD_A,
         NUMWORDS_A => WORDS_A,
         WIDTH_B => WIDTH_B,
         WIDTHAD_B => WIDTHAD_B,
         NUMWORDS_B => WORDS_B,
         OPERATION_MODE => OPERATION_MODE
      )
      port map(
         clock0 => clock0,
         clock1 => clock1,
         address_a => address_a,
         addressstall_a => addressstall_a,
         address_b => address_b,
         addressstall_b => addressstall_b,
         q_a => q_a_int,
         q_b => q_b_int,
         data_a => data_a,
         data_b => data_b,
         wren_a => wren_a,
         wren_b => wren_b
      );
   end generate;
   a_be: if(WIDTH_BYTEENA_A > 0 and WIDTH_BYTEENA_B = 0) generate
      ram: altsyncram generic map(
         WIDTH_A => WIDTH_A,
         WIDTHAD_A => WIDTHAD_A,
         NUMWORDS_A => WORDS_A,
         WIDTH_B => WIDTH_B,
         WIDTHAD_B => WIDTHAD_B,
         NUMWORDS_B => WORDS_B,
         WIDTH_BYTEENA_A => WIDTH_BYTEENA_A,
         OPERATION_MODE => OPERATION_MODE
      )
      port map(
         clock0 => clock0,
         clock1 => clock1,
         address_a => address_a,
         addressstall_a => addressstall_a,
         address_b => address_b,
         addressstall_b => addressstall_b,
         q_a => q_a_int,
         q_b => q_b_int,
         data_a => data_a,
         data_b => data_b,
         wren_a => wren_a,
         wren_b => wren_b,
         byteena_a => byteena_a
      );
   end generate;
   b_be: if(WIDTH_BYTEENA_A = 0 and WIDTH_BYTEENA_B > 0) generate
      ram: altsyncram generic map(
         WIDTH_A => WIDTH_A,
         WIDTHAD_A => WIDTHAD_A,
         NUMWORDS_A => WORDS_A,
         WIDTH_B => WIDTH_B,
         WIDTHAD_B => WIDTHAD_B,
         NUMWORDS_B => WORDS_B,
         WIDTH_BYTEENA_B => WIDTH_BYTEENA_B,
         OPERATION_MODE => OPERATION_MODE
      )
      port map(
         clock0 => clock0,
         clock1 => clock1,
         address_a => address_a,
         addressstall_a => addressstall_a,
         address_b => address_b,
         addressstall_b => addressstall_b,
         q_a => q_a_int,
         q_b => q_b_int,
         data_a => data_a,
         data_b => data_b,
         wren_a => wren_a,
         wren_b => wren_b,
         byteena_b => byteena_b
      );
   end generate;
   ab_be: if(WIDTH_BYTEENA_A > 0 and WIDTH_BYTEENA_B > 0) generate
      ram: altsyncram generic map(
         WIDTH_A => WIDTH_A,
         WIDTHAD_A => WIDTHAD_A,
         NUMWORDS_A => WORDS_A,
         WIDTH_B => WIDTH_B,
         WIDTHAD_B => WIDTHAD_B,
         NUMWORDS_B => WORDS_B,
         WIDTH_BYTEENA_A => WIDTH_BYTEENA_A,
         WIDTH_BYTEENA_B => WIDTH_BYTEENA_B,
         OPERATION_MODE => OPERATION_MODE
      )
      port map(
         clock0 => clock0,
         clock1 => clock1,
         address_a => address_a,
         addressstall_a => addressstall_a,
         address_b => address_b,
         addressstall_b => addressstall_b,
         q_a => q_a_int,
         q_b => q_b_int,
         data_a => data_a,
         data_b => data_b,
         wren_a => wren_a,
         wren_b => wren_b,
         byteena_a => byteena_a,
         byteena_b => byteena_b
      );
   end generate;

   q_a <= wrdata_b when MIXED_PORT_FORWARDING and wr_b = '1' and wad_b = wad_a else q_a_int;
   q_b <= wrdata_a when MIXED_PORT_FORWARDING and wr_a = '1' and wad_a = wad_b else q_b_int;

   process(clock0) is begin
      if(rising_edge(clock0)) then
         wrdata_a <= data_a;
         wr_a <= wren_a;
         if(addressstall_a = '0') then
            wad_a <= address_a;
         end if;
      end if;
   end process;
   process(clock1) is begin
      if(rising_edge(clock1)) then
         wrdata_b <= data_b;
         wr_b <= wren_b;
         if(addressstall_b = '0') then
            wad_b <= address_b;
         end if;
      end if;
   end process;
end architecture;
