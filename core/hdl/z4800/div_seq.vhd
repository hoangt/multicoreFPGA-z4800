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

entity div_seq is
   generic(
      BITS:                      natural
   );
   port(
      clock:                     in       std_logic;
      rst:                       in       std_logic;

      start:                     in       std_logic;
      done:                      out      std_logic;

      divisor:                   in       std_logic_vector(BITS - 1 downto 0);
      dividend:                  in       std_logic_vector(BITS - 1 downto 0);
      quotient:                  out      std_logic_vector(BITS - 1 downto 0);
      remainder:                 out      std_logic_vector(BITS - 1 downto 0)
   );
end;

architecture div_seq of div_seq is
   -- see: Computer Organization & Architecture, Stallings, 6th edition,
   -- pp, 306-307
   --
   -- this is a 2's complement signed restoring divider; for unsigned
   -- values just add an extra bit and mux between signed/zero-extended inputs

   signal count:                 integer range 0 to BITS - 1;
   signal m, a, q:               std_logic_vector(BITS - 1 downto 0);
   signal a_shl, q_shl:          std_logic_vector(BITS - 1 downto 0);
   
   signal new_a:                 std_logic_vector(BITS - 1 downto 0);
   signal q0:                    std_logic;
   signal flip_sign:             std_logic;
begin
   a_shl <= a(a'high - 1 downto a'low) & q(q'high);
   q_shl <= q(q'high - 1 downto q'low) & q0;

   new_a <=
      a_shl - m when a_shl(a_shl'high) = m(m'high) else
      a_shl + m;

   q0 <=
      '1' when new_a(new_a'high) = a_shl(a_shl'high) else
      '1' when new_a = (new_a'range => '0') else
      '0';

   process(clock) is
      type state_t is            (s_idle, s_run, s_end);
      variable state:            state_t;
   begin
      if(rising_edge(clock)) then
         done <= '0';

         if(start = '1') then
            state := s_idle;
         end if;

         case state is
            when s_idle =>
               if(start = '1') then
                  count <= count'high;
                  m <= divisor;
                  a <= (others => dividend(dividend'high));
                  q <= dividend;
                  flip_sign <= divisor(divisor'high) xor dividend(dividend'high);
                  state := s_run;
               end if;
            when s_run =>
               if(q0 = '1') then
                  a <= new_a;
               else
                  a <= a_shl; -- restore
               end if;
               q <= q_shl;
               count <= count - 1;
               if(count = 0) then
                  state := s_end;
               end if;
            when s_end =>
               if(flip_sign = '0') then
                  quotient <= q;
               else
                  quotient <= (not q) + 1;
               end if;
               remainder <= a;
               done <= '1';
               state := s_idle;
            when others =>
               state := s_idle;
         end case;

         if(rst = '1') then
            state := s_idle;
            done <= '0';
         end if;
      end if;
   end process;
end architecture;
