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

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
library z48common;
use z48common.z48common.all;

entity ccdma is
   generic(
      WIDTH:                        natural := 32;
      ADDR_WIDTH:                   natural := 30;
      BLOCK_BITS:                   natural := 4;
      MAX_READS:                    natural := 16
   );
   port(
      clock:                        in std_logic;
      rst:                          in std_logic;

      m_addr:                       out std_logic_vector(31 downto 0);
      m_rd:                         buffer std_logic;
      m_wr:                         out std_logic;
      m_halt:                       in std_logic;
      m_in:                         in std_logic_vector(WIDTH - 1 downto 0);
      m_out:                        out std_logic_vector(WIDTH - 1 downto 0);
      m_be:                         out std_logic_vector((WIDTH / 8) - 1 downto 0);
      m_valid:                      in std_logic;

      s_addr:                       in std_logic_vector(ADDR_WIDTH - 1 downto 0);
      s_rd:                         in std_logic;
      s_wr:                         in std_logic;
      s_halt:                       buffer std_logic;
      s_in:                         in std_logic_vector(WIDTH - 1 downto 0);
      s_out:                        out std_logic_vector(WIDTH - 1 downto 0);
      s_be:                         in std_logic_vector((WIDTH / 8) - 1 downto 0);
      s_valid:                      out std_logic;

      s_bus_reqn:                   buffer std_logic;
      s_bus_gntn:                   in std_logic;
      s_bus_r_addr_oe:              out std_logic;
      s_bus_r_addr_out:             buffer word;
      s_bus_r_addr:                 in word;
      s_bus_r_sharen_oe:            buffer std_logic;
      s_bus_r_sharen:               in std_logic;
      s_bus_r_excln_oe:             buffer std_logic;
      s_bus_r_excln:                in std_logic;
      s_bus_a_waitn_oe:             out std_logic;
      s_bus_a_waitn:                in std_logic;
      s_bus_a_ackn_oe:              out std_logic;
      s_bus_a_ackn:                 in std_logic;
      s_bus_a_sharen_oe:            out std_logic;
      s_bus_a_sharen:               in std_logic;
      s_bus_a_excln_oe:             out std_logic;
      s_bus_a_excln:                in std_logic
   );
end entity;

architecture ccdma of ccdma is
   constant BYTE_BITS:              natural := log2c(WIDTH / 8);
   constant BL:                     natural := 0;
   constant BH:                     natural := BL + BYTE_BITS - 1;
   constant BLKL:                   natural := BH + 1;
   constant BLKH:                   natural := BLKL + BLOCK_BITS - 1;
   constant TAGL:                   natural := BLKH + 1;
   constant TAGH:                   natural := 31;

   function pad(x: std_logic_vector;l: integer) return std_logic_vector is begin
      return (l - 1 downto 0 => '0') & x;
   end function;

   signal s_addr_pad:               word;

   signal minstate:                 cache_state_t;
   signal l_attn:                   std_logic;

   signal s_bus_r_addr_r:           word;
   signal s_bus_r_sharen_r:         std_logic;
   signal s_bus_r_excln_r:          std_logic;

   signal r_active:                 std_logic;
   signal r_attn:                   std_logic;
   signal r_match, r_match_excl:    std_logic;

   signal l_state:                  cache_state_t;
   signal l_addr:                   word;

   signal read_count:               integer range 0 to MAX_READS;
   signal read_limit:               std_logic;
begin
   s_addr_pad <= pad(s_addr, 32 - BYTE_BITS - s_addr'length) & (BH downto BL => '0');

   minstate <= T_STATE_EXCLUSIVE when s_wr = '1' else
               T_STATE_SHARED when s_rd = '1' else
               T_STATE_INVALID;

   l_attn <=
      '0' when s_rd = '0' and s_wr = '0' else
      '1' when compare_ne(s_addr_pad(TAGH downto TAGL), l_addr(TAGH downto TAGL)) else
      '1' when cache_state_test_less_than(l_state, minstate) else
      '0';

   s_halt <= l_attn or m_halt or read_limit;

   m_addr <= s_addr_pad;
   m_rd <= s_rd and not l_attn and not read_limit;
   m_wr <= s_wr and not l_attn and not read_limit;
   m_out <= s_in;
   m_be <= s_be;

   s_out <= m_in;
   s_valid <= m_valid;

   process(clock) is
      variable new_count:           integer range read_count'range;
   begin
      if(rising_edge(clock)) then
         new_count := read_count;
         if(m_rd = '1' and m_halt = '0') then
            new_count := new_count + 1;
         end if;
         if(m_valid = '1') then
            new_count := new_count - 1;
         end if;
         read_count <= new_count;
         if(new_count = MAX_READS) then
            read_limit <= '1';
         else
            read_limit <= '0';
         end if;

         if(rst = '1') then
            read_count <= 0;
         end if;
      end if;
   end process;

   process(clock) is begin
      if(rising_edge(clock)) then
         if(s_bus_a_waitn = '1') then
            s_bus_r_addr_r <= s_bus_r_addr;
            s_bus_r_sharen_r <= s_bus_r_sharen or s_bus_r_sharen_oe;
            s_bus_r_excln_r <= s_bus_r_excln or s_bus_r_excln_oe;
         end if;

         if(rst = '1') then
            s_bus_r_sharen_r <= '1';
            s_bus_r_excln_r <= '1';
         end if;
      end if;
   end process;

   r_active <=
      '1' when s_bus_r_sharen_r = '0' else
      '1' when s_bus_r_excln_r = '0' else
      '0';

   r_match <=
      '0' when compare_ne(s_bus_r_addr_r(TAGH downto TAGL), l_addr(TAGH downto TAGL)) else
      '1' when cache_state_test_at_least(l_state, T_STATE_SHARED) else
      '0';

   r_match_excl <=
      r_match when cache_state_test_at_least(l_state, T_STATE_EXCLUSIVE) else
      '0';

   r_attn <=
      '0' when r_active = '0' else
      '0' when r_match = '0' else
      '1' when r_match_excl = '1' else
      '1' when s_bus_r_excln_r = '0' else
      '0';

   s_bus_a_waitn_oe <= r_active and r_attn;
   s_bus_a_ackn_oe <= r_active;
   s_bus_a_sharen_oe <= r_active and r_match;
   s_bus_a_excln_oe <= r_active and r_match_excl;

   process(clock) is
      type state_t is (s_idle, s_lsnoop1, s_lsnoop2, s_lsnoop3, s_rsnoop1, s_return1);
      variable state:               state_t;
   begin
      if(rising_edge(clock)) then
         s_bus_r_addr_oe <= '0';
         s_bus_r_sharen_oe <= '0';
         s_bus_r_excln_oe <= '0';

         case state is
            when s_idle =>
               if(r_attn = '1') then
                  state := s_rsnoop1;
               elsif(l_attn = '1') then
                  s_bus_reqn <= '0';
                  state := s_lsnoop1;
               else
                  s_bus_reqn <= '1';
               end if;

            when s_lsnoop1 =>
               if(r_attn = '1') then
                  state := s_rsnoop1;
               elsif(s_bus_gntn = '0' and s_bus_a_waitn = '1') then
                  s_bus_reqn <= '1';
                  s_bus_r_addr_oe <= '1';
                  s_bus_r_addr_out <= s_addr_pad;
                  if(cache_state_test_at_least(minstate, T_STATE_EXCLUSIVE)) then
                     s_bus_r_excln_oe <= '1';
                     s_bus_r_sharen_oe <= '0';
                  else
                     s_bus_r_excln_oe <= '0';
                     s_bus_r_sharen_oe <= '1';
                  end if;
                  state := s_lsnoop2;
               end if;

            when s_lsnoop2 =>
               if(r_attn = '1') then
                  state := s_rsnoop1;
               elsif(s_bus_a_waitn = '1') then
                  state := s_lsnoop3;
               end if;

            when s_lsnoop3 =>
               if(s_bus_a_waitn = '1') then
                  l_addr <= s_bus_r_addr_out;
                  if(s_bus_a_sharen = '0') then
                     l_state <= T_STATE_SHARED;
                  else
                     l_state <= T_STATE_EXCLUSIVE;
                  end if;
                  state := s_return1;
               end if;

            when s_rsnoop1 =>
               if(m_halt = '0') then
                  if(s_bus_r_excln_r = '0') then
                     l_state <= T_STATE_INVALID;
                  else
                     l_state <= T_STATE_SHARED;
                  end if;
                  state := s_return1;
               end if;

            when s_return1 =>
               state := s_idle;

            when others =>
               null;
         end case;
         
         if(rst = '1') then
            s_bus_reqn <= '1';
            s_bus_r_addr_oe <= '0';
            s_bus_r_sharen_oe <= '0';
            s_bus_r_excln_oe <= '0';
            l_state <= T_STATE_INVALID;
            state := s_idle;
         end if;
      end if;
   end process;
end architecture;
