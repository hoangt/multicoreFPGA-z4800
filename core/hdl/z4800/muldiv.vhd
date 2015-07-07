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

entity muldiv is
   generic(
      HAVE_MULTIPLY:             boolean;
      MULTIPLY_TYPE:             string;
      COMB_MULTIPLY_CYCLES:      natural;
      HAVE_DIVIDE:               boolean;
      DIVIDE_TYPE:               string;
      COMB_DIVIDE_CYCLES:        natural
   );
   port(
      clock:                     in       std_logic;
      rst:                       in       std_logic;
      op:                        in       aluop_t;
      op_valid:                  in       std_logic;
      i0:                        in       word;
      i1:                        in       word;
      u:                         in       std_logic;
      lo:                        out      word;
      hi:                        out      word;
      stall:                     out      std_logic;
      fault:                     out      std_logic
   );
end;

architecture muldiv of muldiv is
   signal i0ext, i1ext: std_logic_vector(32 downto 0);

   signal mula, mulb:   std_logic_vector(32 downto 0);
   signal mulhi, mullo: std_logic_vector(31 downto 0);
   signal mul_start:    std_logic;
   signal mul_done:     std_logic;

   signal divn, divd:   std_logic_vector(32 downto 0);
   signal divhi, divlo: std_logic_vector(31 downto 0);
   signal div_start:    std_logic;
   signal div_done:     std_logic;

   signal done:         std_logic;
begin
   i0ext <= (not u and i0(31)) & i0;
   i1ext <= (not u and i1(31)) & i1;

   multicycle: process(clock) is
      type state_t is (s_idle, s_mul, s_div);
      variable state: state_t;
   begin
      if(rising_edge(clock)) then
         mul_start <= '0';
         div_start <= '0';

         case state is
            when s_idle =>
               if(op_valid = '1' and done = '1') then
                  case op is
                     when a_mul =>
                        mula <= i0ext;
                        mulb <= i1ext;
                        mul_start <= '1';
                        done <= '0';
                        state := s_mul;
                     when a_div =>
                        divn <= i0ext;
                        divd <= i1ext;
                        div_start <= '1';
                        done <= '0';
                        state := s_div;
                     when a_mthi =>
                        hi <= i0;
                     when a_mtlo =>
                        lo <= i0;
                     when others =>
                        null;
                  end case;
               end if;
            when s_mul =>
               if(mul_done = '1') then
                  lo <= mullo;
                  hi <= mulhi;
                  done <= '1';
                  state := s_idle;
               end if;
            when s_div =>
               if(div_done = '1') then
                  lo <= divlo;
                  hi <= divhi;
                  done <= '1';
                  state := s_idle;
               end if;
            when others =>
               null;
         end case;

         -- synch reset
         if(rst = '1') then
            done <= '1';
            state := s_idle;
         end if;
      end if;
   end process;

   stall <= op_valid and not done;

   div: if(HAVE_DIVIDE) generate
      assert(DIVIDE_TYPE = "COMB" or DIVIDE_TYPE = "SEQ" or DIVIDE_TYPE = "TEST") report "unknown divider type" severity error;

      comb_div: if(DIVIDE_TYPE = "COMB") generate
         divider: entity work.div_comb generic map(
            BITS => 33,
            CYCLES => COMB_DIVIDE_CYCLES
         )
         port map(
            clock => clock,
            rst => rst,

            start => div_start,
            done => div_done,

            divisor => divd,
            dividend => divn,
            quotient(31 downto 0) => divlo,
            remainder(31 downto 0) => divhi
         );
         fault <= '0';
      end generate;

      seq_div: if(DIVIDE_TYPE = "SEQ") generate
         divider: entity work.div_seq generic map(
            BITS => 33
         )
         port map(
            clock => clock,
            rst => rst,

            start => div_start,
            done => div_done,

            divisor => divd,
            dividend => divn,
            quotient(31 downto 0) => divlo,
            remainder(31 downto 0) => divhi
         );
         fault <= '0';
      end generate;

      test_div: if(DIVIDE_TYPE = "TEST") generate
         divider: entity work.div_test generic map(
            BITS => 33,
            CYCLES => COMB_DIVIDE_CYCLES
         )
         port map(
            clock => clock,
            rst => rst,

            start => div_start,
            done => div_done,

            divisor => divd,
            dividend => divn,
            quotient(31 downto 0) => divlo,
            remainder(31 downto 0) => divhi,

            mismatch => fault
         );
      end generate;
   end generate;
   no_div: if(not HAVE_DIVIDE) generate
      div_done <= '1';
      divlo <= (others => '-');
      divhi <= (others => '-');
   end generate;

   mult: if(HAVE_MULTIPLY) generate
      assert(MULTIPLY_TYPE = "COMB") report "unknown multiplier type" severity error;

      comb_mul: if(MULTIPLY_TYPE = "COMB") generate
         multiplier: entity work.mul_comb generic map(
            BITS => 33,
            CYCLES => COMB_MULTIPLY_CYCLES
         )
         port map(
            clock => clock,
            rst => rst,

            start => mul_start,
            done => mul_done,

            a => mula,
            b => mulb,
            o(31 downto 0) => mullo,
            o(63 downto 32) => mulhi
         );
      end generate;
   end generate;
   no_mult: if(not HAVE_MULTIPLY) generate
      mul_done <= '1';
      mullo <= (others => '-');
      mulhi <= (others => '-');
   end generate;
end architecture;
