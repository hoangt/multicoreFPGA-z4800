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
use ieee.std_logic_1164.all, ieee.std_logic_unsigned.all, ieee.numeric_std.all;
library z48common;
use z48common.z48common.all;

entity zirqrouter is
   generic(
      NCPUS                   :  natural := 1
   );
   port(
      clock                   :  in       std_logic;
      reset                   :  in       std_logic;

      s_addr                  :  in       std_logic_vector(log2c(NCPUS) - 1 downto 0);
      s_rd                    :  in       std_logic;
      s_wr                    :  in       std_logic;
      s_in                    :  in       std_logic_vector(31 downto 0);
      s_out                   :  out      std_logic_vector(31 downto 0);

      irqs_out                :  buffer   std_logic_vector(NCPUS - 1 downto 0);
      irqs_in                 :  in       std_logic_vector(31 downto 0);

      -- dummy master for irq interface
      m_addr                  :  out      std_logic_vector(31 downto 0);
      m_rd                    :  out      std_logic;
      m_in                    :  in       std_logic_vector(31 downto 0);
      m_halt                  :  in       std_logic
   );
end;

architecture zirqrouter of zirqrouter is
   signal irq_mask            :  std_logic_vector(31 downto 0);

   type percpu_irq_flag_t is array(NCPUS - 1 downto 0) of std_logic_vector(31 downto 0);
   signal percpu_irq_flags    :  percpu_irq_flag_t;
begin
   perirq_state_mach: for i in irqs_in'range generate
      process(clock) is
         type state_t is (s_idle, s_dispatched);
         variable state       :  state_t;
         variable cpu         :  integer range irqs_out'range;

         procedure clear_flags is begin
            for j in percpu_irq_flags'range loop
               percpu_irq_flags(j)(i) <= '0';
            end loop;
         end procedure;
      begin
         if(rising_edge(clock)) then
            case state is
               when s_idle =>
                  if(irqs_in(i) = '1' and irq_mask(i) = '1') then
                     if(irqs_out(cpu) = '1') then
                        -- cpu is busy, pick another (may race but that's OK)
                        cpu := cpu + 1;
                     else
                        percpu_irq_flags(cpu)(i) <= '1';
                        state := s_dispatched;
                     end if;
                  end if;
               when s_dispatched =>
                  if(irqs_in(i) = '0' or irq_mask(i) = '0') then
                     clear_flags;
                     state := s_idle;
                  end if;
               when others =>
                  null;
            end case;

            if(reset = '1') then
               clear_flags;
               state := s_idle;
               cpu := 0;
            end if;
         end if;
      end process;
   end generate;

   percpu_output: process(percpu_irq_flags) is begin
      for cpu in percpu_irq_flags'range loop
         if(any_bit_set(percpu_irq_flags(cpu))) then
            irqs_out(cpu) <= '1';
         else
            irqs_out(cpu) <= '0';
         end if;
      end loop;
   end process;

   process(clock) is begin
      if(rising_edge(clock)) then
         if(s_wr = '1') then
            irq_mask <= s_in;
         end if;
         s_out <= percpu_irq_flags(int(s_addr));

         if(reset = '1') then
            irq_mask <= (others => '0');
         end if;
      end if;
   end process;
end;
