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

entity dummy_master is
   generic(
      WIDTH                   :  natural := 32
   );
   port(
      clk                     :  in       std_logic;
      rst                     :  in       std_logic;

      m_addr                  :  out      std_logic_vector(31 downto 0);
      m_rd                    :  out      std_logic;
      m_wr                    :  out      std_logic;
      m_in                    :  in       std_logic_vector(WIDTH - 1 downto 0);
      m_out                   :  out      std_logic_vector(WIDTH - 1 downto 0);
      m_halt                  :  in       std_logic
   );
end;

architecture dummy_master of dummy_master is begin
   m_addr <= (others => '-');
   m_rd <= '0';
   m_wr <= '0';
   m_out <= (others => '-');
end;
