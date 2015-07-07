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

entity pprdma_map_de2 is
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

      io:                     inout std_logic_vector(35 downto 0)
   );
end entity;

architecture pprdma_map_de2 of pprdma_map_de2 is
   type pprdma_pinmap_t is array(natural range <>) of natural;
   constant pprdma_pinmap_32to36: pprdma_pinmap_t := (
      0  => 1,
      1  => 3,
      2  => 4,
      3  => 5,
      4  => 6,
      5  => 7,
      6  => 8,
      7  => 9,
      8  => 10,
      9  => 11,
      10 => 12,
      11 => 13,
      12 => 14,
      13 => 15,
      14 => 17,
      15 => 19,
      16 => 20,
      17 => 21,
      18 => 22,
      19 => 23,
      20 => 24,
      21 => 25,
      22 => 26,
      23 => 27,
      24 => 28,
      25 => 29,
      26 => 30,
      27 => 31,
      28 => 32,
      29 => 33,
      30 => 34,
      31 => 35,

      -- these get wired to the dedicated clock pins when
      -- this board is a DE2 that gets connected to a DE2-70
      -- they should be always tristated
      32 => 0,
      33 => 2,
      34 => 16,
      35 => 18
   );
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
            when INCTL_LOW + 0 => i_bp <= io(pprdma_pinmap_32to36(i));
            when INCTL_LOW + 1 => i_clk <= io(pprdma_pinmap_32to36(i));
            when INCTL_LOW + 2 => i_nrd <= io(pprdma_pinmap_32to36(i));
            when INCTL_LOW + 3 => i_nstb <= io(pprdma_pinmap_32to36(i));
            when INCTL_LOW + 4 => i_nwr <= io(pprdma_pinmap_32to36(i));
            when INCTL_LOW + 5 => i_sel(0) <= io(pprdma_pinmap_32to36(i));
            when INCTL_LOW + 6 => i_sel(1) <= io(pprdma_pinmap_32to36(i));
            when others =>
               if(i >= INDATA_LOW and i <= INDATA_HIGH) then
                  i_data(i - INDATA_LOW) <= io(pprdma_pinmap_32to36(i));
               end if;
         end case;

         -- OUTPUTS --
         case i is
            when OUTCTL_LOW + 0 => io(pprdma_pinmap_32to36(i)) <= o_bp;
            when OUTCTL_LOW + 1 => io(pprdma_pinmap_32to36(i)) <= o_clk;
            when OUTCTL_LOW + 2 => io(pprdma_pinmap_32to36(i)) <= o_nrd;
            when OUTCTL_LOW + 3 => io(pprdma_pinmap_32to36(i)) <= o_nstb;
            when OUTCTL_LOW + 4 => io(pprdma_pinmap_32to36(i)) <= o_nwr;
            when OUTCTL_LOW + 5 => io(pprdma_pinmap_32to36(i)) <= o_sel(0);
            when OUTCTL_LOW + 6 => io(pprdma_pinmap_32to36(i)) <= o_sel(1);
            when others =>
               if(i >= OUTDATA_LOW and i <= OUTDATA_HIGH) then
                  io(pprdma_pinmap_32to36(i)) <= o_data(i - OUTDATA_LOW);
               else
                  -- tristate anything that isn't a known output
                  io(pprdma_pinmap_32to36(i)) <= 'Z';
               end if;
         end case;
      end loop;
   end process;
end architecture;
