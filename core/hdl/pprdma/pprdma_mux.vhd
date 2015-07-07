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

entity pprdma_mux is
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

      ia_clk:                 in    std_logic;
      ia_data:                in    std_logic_vector;
      ia_nstb:                in    std_logic;
      ia_sel:                 in    std_logic_vector(1 downto 0);
      ia_nrd:                 in    std_logic;
      ia_nwr:                 in    std_logic;
      ia_bp:                  in    std_logic;

      oa_clk:                 out   std_logic;
      oa_data:                out   std_logic_vector;
      oa_nstb:                out   std_logic;
      oa_sel:                 out   std_logic_vector(1 downto 0);
      oa_nrd:                 out   std_logic;
      oa_nwr:                 out   std_logic;
      oa_bp:                  out   std_logic;

      ib_clk:                 in    std_logic;
      ib_data:                in    std_logic_vector;
      ib_nstb:                in    std_logic;
      ib_sel:                 in    std_logic_vector(1 downto 0);
      ib_nrd:                 in    std_logic;
      ib_nwr:                 in    std_logic;
      ib_bp:                  in    std_logic;

      ob_clk:                 out   std_logic;
      ob_data:                out   std_logic_vector;
      ob_nstb:                out   std_logic;
      ob_sel:                 out   std_logic_vector(1 downto 0);
      ob_nrd:                 out   std_logic;
      ob_nwr:                 out   std_logic;
      ob_bp:                  out   std_logic;

      sel:                    in    std_logic
   );
end entity;

architecture pprdma_mux of pprdma_mux is
begin
   oa_clk <= o_clk;
   oa_data <= o_data;
   oa_nstb <= o_nstb when sel = '0' else '1';
   oa_sel <= o_sel;
   oa_nrd <= o_nrd when sel = '0' else '1';
   oa_nwr <= o_nwr when sel = '0' else '1';
   oa_bp <= o_bp when sel = '0' else '1';

   ob_clk <= o_clk;
   ob_data <= o_data;
   ob_nstb <= o_nstb when sel = '1' else '1';
   ob_sel <= o_sel;
   ob_nrd <= o_nrd when sel = '1' else '1';
   ob_nwr <= o_nwr when sel = '1' else '1';
   ob_bp <= o_bp when sel = '1' else '1';

   i_clk <= ia_clk when sel = '0' else ib_clk;
   i_data <= ia_data when sel = '0' else ib_data;
   i_nstb <= ia_nstb when sel = '0' else ib_nstb;
   i_sel <= ia_sel when sel = '0' else ib_sel;
   i_nrd <= ia_nrd when sel = '0' else ib_nrd;
   i_nwr <= ia_nwr when sel = '0' else ib_nwr;
   i_bp <= ia_bp when sel = '0' else ib_bp;
end architecture;
