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

library ieee, lpm, z48common; use ieee.std_logic_1164.all, ieee.std_logic_unsigned.all, ieee.std_logic_arith.all, lpm.lpm_components.all, z48common.z48common.all;


entity z48group is
   generic(
      ALLOW_CASCADE:             boolean;
      AVOID_ISSUE_AFTER_TRAP:    boolean;
      AVOID_DUAL_ISSUE:          boolean
   );
   port(
      i0, i1:                    in       preg_t;
      o0, o1:                    out      preg_t;
      valid:                     in       std_logic_vector(1 downto 0);
      issue:                     buffer   std_logic_vector(1 downto 0);

      stats_raw:                 out      std_logic;
      stats_cascade:             out      std_logic
   );
end entity;

architecture z48group of z48group is
   signal raw:                   std_logic;
   signal brpair:                std_logic;
   signal m1pair:                std_logic;
   signal cascade:               std_logic;
   signal cascade0, cascade1:    std_logic;
   signal can_issue:             std_logic_vector(1 downto 0);
   signal nop_bypass:            std_logic;

   function is_m1(i: preg_t) return boolean is begin
      return
         (i.i.op = i_muldiv) or
         (i.i.op = i_cop0) or
         (i.i.op = i_ld or i.i.op = i_st or i.i.op = i_cache) or
         (i.i.op = i_sync);
   end function;
begin
   stats_raw <= raw;
   stats_cascade <= cascade;

   raw <=
      '0' when i0.i.dest = "00000" else
      '1' when i0.i.writes_reg = '1' and i1.i.reads(0) = '1' and i1.i.source(0) = i0.i.dest else
      '1' when i0.i.writes_reg = '1' and i1.i.reads(1) = '1' and i1.i.source(1) = i0.i.dest else
      '0';
   cascade <= '1' when ALLOW_CASCADE and valid(1) = '1' and raw = '1' and i0.i.late = '0' else '0';
   cascade0 <= '1' when cascade = '1' and i1.i.reads(0) = '1' and i1.i.source(0) = i0.i.dest else '0';
   cascade1 <= '1' when cascade = '1' and i1.i.reads(1) = '1' and i1.i.source(1) = i0.i.dest else '0';

   -- one branch at a time (shouldn't really happen since branches are delayed)
   brpair <=      '1' when
                     (i0.i.op = i_br or i0.i.op = i_jr) and
                     (i1.i.op = i_br or i1.i.op = i_jr) else
                  '0';

   -- it's problematic to combine loads/stores, mflo/mfhi, or cop0 ops because
   -- the other units can get out of sync with the main pipe when it stalls
   -- this restriction guarantees that stall(5) in the pipeline will be
   -- asserted for at most 1 reason at a time
   m1pair <= '1' when is_m1(i0) and is_m1(i1) else '0';

   -- don't bother applying special properties of ssnop/pflush if they are
   -- in a delay slot
   nop_bypass <= '1' when i0.i.has_delay_slot = '1' and valid(1) = '1' and (i1.i.op = i_ssnop or i1.i.op = i_pflush) else '0';
               
   can_issue(0) <=   '0' when valid(0) = '0' else
                     '1' when nop_bypass = '1' else
                     '0' when i0.i.has_delay_slot = '1' and can_issue(1) = '0' else
                     '1';
   can_issue(1) <=   '0' when valid(1) = '0' else
                     '1' when nop_bypass = '1' else
                     '0' when AVOID_ISSUE_AFTER_TRAP and i0.i.op = i_trap else
                     '0' when i0.i.op = i_ssnop or i1.i.op = i_ssnop else
                     '0' when i0.i.op = i_pflush or i1.i.op = i_pflush else
                     '0' when i0.i.cop0op = c0_eret else
                     '0' when i1.i.cop0op = c0_eret else
                     '0' when raw = '1' and cascade = '0' else
                     '0' when brpair = '1' else
                     '0' when m1pair = '1' else
                     '0' when i1.i.op = i_cop0 else
                     '0' when i1.i.has_delay_slot = '1' else
                     i0.i.has_delay_slot when AVOID_DUAL_ISSUE else
                     '1';
   issue(0) <= can_issue(0);
   issue(1) <= can_issue(1) and can_issue(0);

   process(i0, i1, issue, cascade0, cascade1) is begin
      o0 <= i0;
      o1 <= i1;
      o1.i.cascade0 <= cascade0;
      o1.i.cascade1 <= cascade1;
      if(cascade0 = '1') then
         o1.i.reads(0) <= '0';
      end if;
      if(cascade1 = '1') then
         o1.i.reads(1) <= '0';
      end if;
      if(i0.i.has_delay_slot = '1') then
         o1.i.in_delay_slot <= '1';
      end if;
      if(i0.i.likely = '1') then
         o1.i.in_annul_slot <= '1';
      end if;
      if(i0.i.writes_reg = '1' and i0.i.dest = "00000") then
         o0.i.writes_reg <= '0';
      end if;
      if(i1.i.writes_reg = '1' and i1.i.dest = "00000") then
         o1.i.writes_reg <= '0';
      end if;

      -- rewrite ssnop/pflush back to normal aluop
      if(i0.i.op = i_ssnop) then
         o0.i.op <= i_alu;
      end if;
      if(i1.i.op = i_ssnop) then
         o1.i.op <= i_alu;
      end if;
      if(i1.i.op = i_pflush) then
         o1.i.op <= i_alu;
      end if;

      -- mark non-issuing instructions as invalid
      if(issue(0) = '0') then
         o0.i.valid <= '0';
      end if;
      if(issue(1) = '0') then
         o1.i.valid <= '0';
      end if;
   end process;
end architecture;
