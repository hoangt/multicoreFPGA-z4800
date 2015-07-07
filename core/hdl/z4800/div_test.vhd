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

entity div_test is
   generic(
      BITS:                      natural;
      CYCLES:                    natural
   );
   port(
      clock:                     in       std_logic;
      rst:                       in       std_logic;

      start:                     in       std_logic;
      done:                      out      std_logic;

      divisor:                   in       std_logic_vector(BITS - 1 downto 0);
      dividend:                  in       std_logic_vector(BITS - 1 downto 0);
      quotient:                  out      std_logic_vector(BITS - 1 downto 0);
      remainder:                 out      std_logic_vector(BITS - 1 downto 0);

      mismatch:                  out      std_logic
   );
end;

architecture div_test of div_test is
   signal seq_quot, seq_rem:     std_logic_vector(BITS - 1 downto 0);
   signal seq_quot_r, seq_rem_r: std_logic_vector(BITS - 1 downto 0);
   signal seq_done, seq_done_r:  std_logic;

   signal comb_quot, comb_rem:   std_logic_vector(BITS - 1 downto 0);
   signal comb_quot_r, comb_rem_r: std_logic_vector(BITS - 1 downto 0);
   signal comb_done, comb_done_r: std_logic;
begin
   comb: entity work.div_comb generic map(
      BITS => BITS,
      CYCLES => CYCLES
   )
   port map(
      clock => clock,
      rst => rst,
      
      start => start,
      done => comb_done,

      divisor => divisor,
      dividend => dividend,
      quotient => comb_quot,
      remainder => comb_rem
   );

   seq: entity work.div_seq generic map(
      BITS => BITS
   )
   port map(
      clock => clock,
      rst => rst,
      
      start => start,
      done => seq_done,

      divisor => divisor,
      dividend => dividend,
      quotient => seq_quot,
      remainder => seq_rem
   );

   quotient <= comb_quot_r;
   remainder <= comb_rem_r;

   process(clock) is
      type state_t is            (s_idle, s_wait, s_done);
      variable state:            state_t;
   begin
      if(rising_edge(clock)) then
         if(start = '1') then
            state := s_idle;
            done <= '0';
         end if;

         case state is
            when s_idle =>
               comb_done_r <= '0';
               seq_done_r <= '0';
               if(start = '1') then
                  state := s_wait;
               end if;
            when s_wait =>
               if(comb_done = '1') then
                  comb_quot_r <= comb_quot;
                  comb_rem_r <= comb_rem;
                  comb_done_r <= '1';
               end if;
               if(seq_done = '1') then
                  seq_quot_r <= seq_quot;
                  seq_rem_r <= seq_rem;
                  seq_done_r <= '1';
               end if;
               if(comb_done_r = '1' and seq_done_r = '1') then
                  done <= '1';
                  state := s_done;
               end if;
            when s_done =>
               done <= '0';
               if((comb_quot_r /= seq_quot_r) or (comb_rem_r /= seq_rem_r)) then
                  mismatch <= '1';
               end if;
               state := s_idle;
            when others =>
               state := s_idle;
         end case;

         if(rst = '1') then
            state := s_idle;
            done <= '0';
            comb_done_r <= '0';
            seq_done_r <= '0';
            mismatch <= '0';
         end if;
      end if;
   end process;
end architecture;
