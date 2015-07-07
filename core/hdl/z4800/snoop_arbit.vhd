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
use ieee.std_logic_arith.all;
library altera_mf;
use altera_mf.altera_mf_components.all;
library z48common;
use z48common.z48common.all;

entity snoop_arbit is
   generic(
      NAGENTS                    :  natural
   );
   port(
      clk                        :  in       std_logic;
      rst                        :  in       std_logic;

      s_bus_a_waitn              :  in       std_logic;

      reqn                       :  in       std_logic_vector(NAGENTS - 1 downto 0);
      gntn                       :  buffer   std_logic_vector(NAGENTS - 1 downto 0)
   );
end;

architecture snoop_arbit of snoop_arbit is
   signal gntn_reg               :  std_logic_vector(NAGENTS - 1 downto 0);
   signal use_gntn_reg           :  std_logic;
   signal rotor                  :  integer range 0 to NAGENTS - 1;
   signal rotvec                 :  std_logic_vector(NAGENTS - 1 downto 0);
   signal reqs_shift             :  std_logic_vector((2 * NAGENTS) - 1 downto 0);
   signal reqs_rot               :  std_logic_vector(NAGENTS - 1 downto 0);
   signal winner                 :  integer range 0 to NAGENTS - 1;
begin
   reqs_shift <= unsigned(reqn) * unsigned(rotvec);
   reqs_rot <= reqs_shift(reqs_shift'high downto NAGENTS) or reqs_shift(NAGENTS - 1 downto 0);
   winner <= ffc(reqs_rot);
   process(winner, rotor, reqn, gntn_reg, use_gntn_reg) is begin
      gntn <= (others => '1');
      if(any_bit_clear(reqn)) then
         gntn(winner - rotor) <= '0';
      end if;
      if(use_gntn_reg = '1') then
         gntn <= gntn_reg;
      end if;
   end process;
   
   process(clk) is begin
      if(rising_edge(clk)) then
         if(s_bus_a_waitn = '1') then
            rotor <= rotor + 1;
            rotvec <= rotvec(rotvec'high - 1 downto rotvec'low) & rotvec(rotvec'high);
         end if;
         gntn_reg <= gntn;
         use_gntn_reg <= not s_bus_a_waitn;

         if(rst = '1') then
            use_gntn_reg <= '0';
            rotor <= 0;
            rotvec <= (0 => '1', others => '0');
         end if;
      end if;
   end process;
end architecture;
