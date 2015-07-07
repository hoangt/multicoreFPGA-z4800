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

library ieee; use ieee.std_logic_1164.all, ieee.std_logic_arith.all;

entity pprdma_map_de2_70 is
   generic(
      PHY_WIDTH:              natural;
      INDATA_LOW:             natural;
      INCTL_LOW:              natural;
      OUTDATA_LOW:            natural;
      OUTCTL_LOW:             natural
   );
   port(
      i_clk:                  out   std_logic;
      i_data:                 out   std_logic_vector;
      i_nstb:                 out   std_logic;
      i_sel:                  out   std_logic_vector(1 downto 0);
      i_nrd:                  out   std_logic;
      i_nwr:                  out   std_logic;
      i_bp:                   out   std_logic;

      o_clk:                  in    std_logic;
      o_data:                 in    std_logic_vector;
      o_nstb:                 in    std_logic;
      o_sel:                  in    std_logic_vector(1 downto 0);
      o_nrd:                  in    std_logic;
      o_nwr:                  in    std_logic;
      o_bp:                   in    std_logic;

      io:                     inout std_logic_vector(31 downto 0)
   );
end entity;

architecture pprdma_map_de2_70 of pprdma_map_de2_70 is
   constant CTL_WIDTH:        natural := 7;
   constant INDATA_HIGH:      natural := INDATA_LOW + PHY_WIDTH - 1;
   constant INCTL_HIGH:       natural := INCTL_LOW + CTL_WIDTH - 1;
   constant OUTDATA_HIGH:     natural := OUTDATA_LOW + PHY_WIDTH - 1;
   constant OUTCTL_HIGH:      natural := OUTCTL_LOW + CTL_WIDTH - 1;
begin
   process(o_clk, o_data, o_nstb, o_sel, o_nrd, o_nwr, o_bp, io) is begin
      for i in io'range loop
         -- INPUTS --
         case i is
            when INCTL_LOW + 0 => i_bp <= io(i);
            when INCTL_LOW + 1 => i_clk <= io(i);
            when INCTL_LOW + 2 => i_nrd <= io(i);
            when INCTL_LOW + 3 => i_nstb <= io(i);
            when INCTL_LOW + 4 => i_nwr <= io(i);
            when INCTL_LOW + 5 => i_sel(0) <= io(i);
            when INCTL_LOW + 6 => i_sel(1) <= io(i);
            when others =>
               if(i >= INDATA_LOW and i <= INDATA_HIGH) then
                  i_data(i - INDATA_LOW) <= io(i);
               end if;
         end case;

         -- OUTPUTS --
         case i is
            when OUTCTL_LOW + 0 => io(i) <= o_bp;
            when OUTCTL_LOW + 1 => io(i) <= o_clk;
            when OUTCTL_LOW + 2 => io(i) <= o_nrd;
            when OUTCTL_LOW + 3 => io(i) <= o_nstb;
            when OUTCTL_LOW + 4 => io(i) <= o_nwr;
            when OUTCTL_LOW + 5 => io(i) <= o_sel(0);
            when OUTCTL_LOW + 6 => io(i) <= o_sel(1);
            when others =>
               if(i >= OUTDATA_LOW and i <= OUTDATA_HIGH) then
                  io(i) <= o_data(i - OUTDATA_LOW);
               else
                  -- tristate anything that isn't a known output
                  io(i) <= 'Z';
               end if;
         end case;
      end loop;
   end process;
end architecture;
