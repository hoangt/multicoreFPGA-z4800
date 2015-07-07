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
library altera;
use altera.altera_syn_attributes.all;

entity dm9000_turbo is
   generic(
      EXTRA_SETUP_WS          :  boolean := false;
      EXTRA_READ_WS           :  boolean := false;
      EXTRA_WRITE_WS          :  boolean := false;
      EXTRA_INACTIVE_WS       :  integer range 0 to 10 := 0;
      ALWAYS_ASSERT_CS        :  boolean := false;
      INT_SYNCH               :  integer range 0 to 5 := 2;
      KICK_DEAD_HORSE         :  boolean := true;
      KICK_DEAD_CYCLES        :  integer := 25 * 1000 * 1000
   );
   port(
      sysclk                  :  in       std_logic;
      clk50                   :  in       std_logic;
      rst                     :  in       std_logic;
      rst50                   :  in       std_logic;

      s_addr                  :  in       std_logic_vector(0 downto 0);
      s_rd                    :  in       std_logic;
      s_wr                    :  in       std_logic;
      s_in                    :  in       std_logic_vector(31 downto 0);
      s_out                   :  out      std_logic_vector(31 downto 0);
      s_halt                  :  out      std_logic;
      s_int                   :  out      std_logic;
      s_valid                 :  out      std_logic;

      enet_clk                :  buffer   std_logic;
      enet_cmd                :  buffer   std_logic;
      enet_cs_n               :  out      std_logic;
      enet_data               :  inout    std_logic_vector(15 downto 0);
      enet_int                :  in       std_logic;
      enet_rd_n               :  out      std_logic;
      enet_rst_n              :  out      std_logic;
      enet_wr_n               :  out      std_logic;

      on_crack                :  out      std_logic
   );
end;

architecture dm9000_turbo of dm9000_turbo is
   signal idle                :  std_logic;
   signal laddr               :  std_logic_vector(7 downto 0);
   signal int_synch_chain     :  std_logic_vector(INT_SYNCH downto 0);
   signal dead_cycles         :  integer range 0 to KICK_DEAD_CYCLES;

   attribute altera_attribute of enet_clk, enet_cmd, enet_cs_n, enet_data, enet_int, enet_rd_n, enet_rst_n, enet_wr_n: signal is "FAST_OUTPUT_REGISTER=ON";
begin
   s_halt <= (s_rd or s_wr) and not idle;
   
   process(sysclk) is
      type state_t is (s_idle, s_rdsetup, s_rd0, s_rd1, s_rd2, s_wrsetup, s_wr0, s_wr1, s_wr2, s_wr3);
      variable state: state_t;
      variable count: integer range 0 to 15;
   begin
      if(rising_edge(sysclk)) then
         s_out <= (31 downto 16 => '0') & enet_data;
         s_valid <= '0';

         case state is
            when s_idle =>
               enet_data <= (others => 'Z');
               if(s_rd = '1') then
                  enet_cs_n <= '0';
                  enet_cmd <= s_addr(0);
                  if(EXTRA_SETUP_WS) then state := s_rdsetup;
                  elsif(EXTRA_READ_WS) then
                     enet_rd_n <= '0';
                     state := s_rd0;
                  else
                     enet_rd_n <= '0';
                     state := s_rd1;
                  end if;
               elsif(s_wr = '1') then
                  enet_cs_n <= '0';
                  enet_cmd <= s_addr(0);
                  enet_data <= s_in(15 downto 0);
                  if(s_addr(0) = '0') then
                     laddr <= s_in(7 downto 0);
                  end if;
                  if(EXTRA_SETUP_WS) then state := s_wrsetup;
                  elsif(EXTRA_WRITE_WS) then
                     enet_wr_n <= '0';
                     state := s_wr1;
                  else
                     enet_wr_n <= '0';
                     state := s_wr2;
                  end if;
               end if;
            when s_rdsetup =>
               enet_rd_n <= '0';
               if(EXTRA_READ_WS) then state := s_rd0;
               else state := s_rd1; end if;
            when s_rd0 =>
               state := s_rd1;
            when s_rd1 =>
               s_valid <= '1';
               enet_rd_n <= '1';
               if(laddr = x"f0") then
                  count := 4;
               elsif(laddr = x"f2") then
                  count := 1;
               else
                  count := 2;
               end if;
               count := count + EXTRA_INACTIVE_WS;
               state := s_rd2;
            when s_rd2 =>
               enet_cs_n <= '1';
               count := count - 1;
               if(count = 0) then
                  state := s_idle;
               end if;
            when s_wrsetup =>
               enet_wr_n <= '0';
               if(EXTRA_WRITE_WS) then state := s_wr1;
               else state := s_wr2; end if;
            when s_wr1 =>
               state := s_wr2;
            when s_wr2 =>
               enet_wr_n <= '1';
               if(enet_cmd = '0') then
                  count := 1;
               else
                  count := 2;
               end if;
               count := count + EXTRA_INACTIVE_WS;
               state := s_wr3;
            when s_wr3 =>
               enet_data <= (others => 'Z');
               enet_cs_n <= '1';
               count := count - 1;
               if(count = 0) then
                  state := s_idle;
               end if;
            when others =>
               state := s_idle;
         end case;

         if(state = s_idle) then
            idle <= '1';
         else
            idle <= '0';
         end if;

         if(rst = '1') then
            state := s_idle;
            enet_cs_n <= '1';
            enet_rd_n <= '1';
            enet_wr_n <= '1';
            enet_data <= (others => 'Z');
            laddr <= x"f0"; -- worst case
            s_valid <= '0';
            idle <= '1';
         end if;

         if(ALWAYS_ASSERT_CS) then
            enet_cs_n <= '0';
         end if;
      end if;
   end process;

   process(clk50) is
      variable rst_count: integer range 0 to 15;
   begin
      if(rising_edge(clk50)) then
         if(KICK_DEAD_HORSE) then
            if(enet_int = '1') then
               dead_cycles <= dead_cycles + 1;
            else
               dead_cycles <= 0;
            end if;
            if(dead_cycles = dead_cycles'high) then
               on_crack <= '1';
               enet_rst_n <= '0';
               rst_count := 15;
               dead_cycles <= 0;
            end if;
         end if;
            
         if(rst_count = 0) then
            enet_rst_n <= '1';
         end if;
         rst_count := rst_count - 1;

         enet_clk <= not enet_clk;

         if(rst50 = '1') then
            on_crack <= '0';
            enet_rst_n <= '0';
            rst_count := 15;
            dead_cycles <= 0;
         end if;
      end if;
   end process;

   int_synch_chain(0) <= enet_int;
   process(sysclk) is begin
      if(rising_edge(sysclk)) then
         int_synch_chain(int_synch_chain'high downto int_synch_chain'low + 1) <= int_synch_chain(int_synch_chain'high - 1 downto int_synch_chain'low);
      end if;
   end process;
   s_int <= int_synch_chain(int_synch_chain'high);
end;
