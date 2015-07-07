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

entity perf is
   generic(
      NR_COUNTERS_LOG2:             natural := 4
   );
   port(
      clock:                        in std_logic;            
      rst:                          in std_logic;
      clr:                          in std_logic;

      m_addr:                       in std_logic_vector(NR_COUNTERS_LOG2 - 1 downto 0);
      m_in:                         in std_logic_vector(31 downto 0);
      m_out:                        out std_logic_vector(31 downto 0);
      m_be:                         in std_logic_vector(3 downto 0);
      m_rd:                         in std_logic;
      m_wr:                         in std_logic;

      perf_inc:                     in std_logic_vector((2 ** NR_COUNTERS_LOG2) - 1 downto 0)
   );
end entity;

architecture perf of perf is
   type perf_array_t is array((2 ** NR_COUNTERS_LOG2) - 1 downto 0) of std_logic_vector(31 downto 0);
   signal perf_array:               perf_array_t;
   signal run:                      std_logic;
   signal perf_inc_r:               std_logic_vector(perf_inc'range);
begin
   process(clock) is begin
      if(rising_edge(clock)) then
         m_out <= perf_array(to_integer(unsigned(m_addr)));
         for i in perf_inc_r'range loop
            if(run = '1' and perf_inc_r(i) = '1') then
               perf_array(i) <= perf_array(i) + 1;
            end if;
         end loop;
         if(m_wr = '1' and m_addr = (m_addr'range => '0') and m_be /= "0000") then
            run <= m_in(0);
            if(m_in(1) = '1') then
               for i in perf_array'range loop
                  perf_array(i) <= (others => '0');
               end loop;
            end if;
         end if;

         perf_inc_r <= perf_inc;

         -- synch reset
         if(rst = '1' or clr = '1') then
            for i in perf_array'range loop
               perf_array(i) <= (others => '0');
            end loop;
            perf_inc_r <= (others => '0');
         end if;
      end if;
   end process;
end architecture;
