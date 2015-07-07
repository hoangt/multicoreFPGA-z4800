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

entity dummy_slave is
   generic(
      ADDRWIDTH               :  natural := 6;
      WIDTH                   :  natural := 32
   );
   port(
      clk                     :  in       std_logic;
      rst                     :  in       std_logic;

      s_addr                  :  in       std_logic_vector(ADDRWIDTH - 1 downto 0);
      s_rd                    :  in       std_logic;
      s_wr                    :  in       std_logic;
      s_be                    :  in       std_logic_vector((WIDTH / 8) - 1 downto 0);
      s_in                    :  in       std_logic_vector(WIDTH - 1 downto 0);
      s_out                   :  out      std_logic_vector(WIDTH - 1 downto 0)
   );
end;

architecture dummy_slave of dummy_slave is begin
   s_out <= (others => '-');
end;
