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

library ieee, lpm, altera_mf, z48common; use ieee.std_logic_1164.all, ieee.std_logic_unsigned.all, ieee.std_logic_arith.all, lpm.lpm_components.all, altera_mf.altera_mf_components.all, z48common.z48common.all;

entity btb is
   generic(
      TABLE_SIZE:                   natural;
      TAGGED:                       boolean;
      VALID_BIT:                    boolean
   );
   port(
      clk:                          in    std_logic;
      rst:                          in    std_logic;

      update:                       in    std_logic;
      update_pc:                    in    word;
      update_target:                in    word;

      a_next_pc:                    in    word;
      a_target:                     out   word;
      a_valid:                      out   std_logic;
      b_next_pc:                    in    word;
      b_target:                     out   word;
      b_valid:                      out   std_logic
   );
end entity;

architecture btb of btb is
   constant ADDRBITS:               natural := log2c(TABLE_SIZE);

   function get_tagbits return integer is begin
      if(not TAGGED) then
         return 0;
      end if;
      return 32 - (ADDRBITS + 3);
   end function;
   constant TAGBITS:                natural := get_tagbits;

   signal d, q_a, q_b:              std_logic_vector(1 + TAGBITS + 32 - 1 downto 0);
   signal cur_pc_a, cur_pc_b:       word;
begin
   ram_a: altsyncram generic map(
      WIDTH_A => 1 + TAGBITS + 32,
      WIDTHAD_A => ADDRBITS,
      WIDTH_B => 1 + TAGBITS + 32,
      WIDTHAD_B => ADDRBITS,
      OPERATION_MODE => "DUAL_PORT"
   )
   port map(
      clock0 => clk,
      clock1 => clk,
      address_a => update_pc(ADDRBITS + 3 - 1 downto 3),
      address_b => a_next_pc(ADDRBITS + 3 - 1 downto 3),
      data_a => d,
      wren_a => update,
      q_b => q_a
   );
   ram_b: altsyncram generic map(
      WIDTH_A => 1 + TAGBITS + 32,
      WIDTHAD_A => ADDRBITS,
      WIDTH_B => 1 + TAGBITS + 32,
      WIDTHAD_B => ADDRBITS,
      OPERATION_MODE => "DUAL_PORT"
   )
   port map(
      clock0 => clk,
      clock1 => clk,
      address_a => update_pc(ADDRBITS + 3 - 1 downto 3),
      address_b => b_next_pc(ADDRBITS + 3 - 1 downto 3),
      data_a => d,
      wren_a => update,
      q_b => q_b
   );
   d <= '1' & update_pc(31 downto 32 - TAGBITS) & update_target;
   a_target <= q_a(31 downto 0);
   a_valid <=
      '1' when TAGGED = false and VALID_BIT = false else
       q_a(32) when TAGGED = false and VALID_BIT = true else
       '1' when TAGGED = true and VALID_BIT = false and q_a(32 + TAGBITS - 1 downto 32) = cur_pc_a(31 downto 32 - TAGBITS) else
       q_a(32) when TAGGED = true and VALID_BIT = true and q_a(32 + TAGBITS - 1 downto 32) = cur_pc_a(31 downto 32 - TAGBITS) else
       '0';
   b_target <= q_b(31 downto 0);
   b_valid <=
      '1' when TAGGED = false and VALID_BIT = false else
       q_b(32) when TAGGED = false and VALID_BIT = true else
       '1' when TAGGED = true and VALID_BIT = false and q_b(32 + TAGBITS - 1 downto 32) = cur_pc_b(31 downto 32 - TAGBITS) else
       q_b(32) when TAGGED = true and VALID_BIT = true and q_b(32 + TAGBITS - 1 downto 32) = cur_pc_b(31 downto 32 - TAGBITS) else
       '0';
            
   process(clk) is begin
      if(rising_edge(clk)) then
         cur_pc_a <= a_next_pc;
         cur_pc_b <= b_next_pc;
      end if;
   end process;
end architecture;
