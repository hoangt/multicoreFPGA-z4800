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

library ieee, lpm, z48common;
use ieee.std_logic_1164.all, ieee.std_logic_unsigned.all, ieee.std_logic_arith.all, lpm.lpm_components.all, z48common.z48common.all;

entity mcheck is
   port( 
      reset:                        in std_logic;
      clock:                        in std_logic;

      p0p, p1p:                     in preg_t;
      p0r, p1r:                     in res_t;

      bev:                          in std_logic;
      refill:                       in std_logic;
      eret:                         in std_logic;
      epc:                          in word;

      d_mem_halt:                   in std_logic;
      cop0_stall:                   in std_logic;
      muldiv_stall:                 in std_logic;

      mce:                          buffer std_logic
   );
end entity;

architecture mcheck of mcheck is
   type pa_t is array(1 downto 0) of preg_t;
   type ra_t is array(1 downto 0) of res_t;
   signal p:                        pa_t;
   signal r:                        ra_t;

   signal expc, nexpc:              word;

   signal branch:                   std_logic;
   signal target:                   word;
   signal exec1, exec2:             std_logic;
   signal exception:                std_logic;

   signal p1_must_commit:           std_logic;
   signal p1_must_not_commit:       std_logic;

   signal multistall:               std_logic;

   signal mce_latch:                std_logic;

   attribute keep:                  boolean;
   attribute keep of expc:          signal is true;
   attribute keep of nexpc:         signal is true;
   attribute keep of mce:           signal is true;
   attribute keep of p1_must_commit: signal is true;
   attribute keep of p1_must_not_commit: signal is true;
begin
   p(0) <= p0p;
   p(1) <= p1p;
   r(0) <= p0r;
   r(1) <= p1r;

   nexpc <= x"9fc00000" when reset = '1' else
            x"9fc00200" when bev = '1' and exception = '1' and refill = '1' else
            x"9fc00380" when bev = '1' and exception = '1' else
            x"80000000" when exception = '1' and refill = '1' else
            x"80000180" when exception = '1' else
            epc when eret = '1' else
            target when branch = '1' and r(0).t = '1' else
            p(0).pc + 8 when branch = '1' and r(0).nt = '1' else
            p(0).pc + 8 when exec2 = '1' else
            p(0).pc + 4 when exec1 = '1' else
            expc;

   target <=   p(0).new_pc when p(0).i.op = i_br else
               r(0).operand0 when p(0).i.op = i_jr else
               p(0).pc + 4 when p(0).i.op = i_pflush else
               x"deadbeef";

   branch <=   '0' when p(0).i.valid = '0' else
               '1' when p(0).i.op = i_br else
               '1' when p(0).i.op = i_jr else
               '1' when p(0).i.op = i_pflush else
               '0';

   p1_must_not_commit <=
      '1' when r(0).except = '1' else
      '1' when p(0).i.valid = '1' and p(0).i.likely = '1' and r(0).nt = '1' else
      '1' when eret = '1' else
      '0';

   p1_must_commit <=
      '0' when p1_must_not_commit = '1' else
      '1' when p(0).i.valid = '1' and p(0).i.has_delay_slot = '1' and
               (p(0).i.likely = '0' or
                  (p(0).i.likely = '1' and r(0).t = '1')) else
      '0';

   multistall <=  '1' when d_mem_halt = '1' and cop0_stall = '1' else
                  '1' when d_mem_halt = '1' and muldiv_stall = '1' else
                  '1' when cop0_stall = '1' and muldiv_stall = '1' else
                  '0';

   mce <=   
            --'1' when r(0).except = '1' and p(0).i.valid = '1' else
            --'1' when r(1).except = '1' and p(1).i.valid = '1' else
            --'1' when (p(1).i.valid = '1' or r(1).except = '1') and p1_must_not_commit = '1' else
            --'1' when (p(1).i.valid = '0' and r(1).except = '0') and p1_must_commit = '1' else
            --'1' when (p(0).i.valid = '1' or r(0).except = '1') and p(0).pc /= expc else
            --'1' when (p(1).i.valid = '1' or r(1).except = '1') and p(1).pc /= expc + 4 else
            --'1' when (p(0).i.valid = '1' and p(0).i.cop0op = c0_eret) xor eret = '1' else
            '1' when r(0).valid = '1' and p(0).i.valid = '0' else
            '1' when r(1).valid = '1' and p(1).i.valid = '0' else
            '1' when p(0).i.valid = '1' and r(0).valid = '1' and r(0).result(32) = '0' and p(0).i.late = '0' else
            '1' when p(1).i.valid = '1' and r(1).valid = '1' and r(1).result(32) = '0' and p(1).i.late = '0' else
            '1' when multistall = '1' else
            '1' when mce_latch = '1' else
            '0';

   exec1 <= '1' when p(0).i.valid = '1' and p(1).i.valid = '0' else '0';
   exec2 <= '1' when p(0).i.valid = '1' and p(1).i.valid = '1' else
            '1' when p(0).i.valid = '1' and p(0).i.likely = '1' else
            '0';

   exception <= r(0).except or r(1).except;

   process(clock) is begin
      if(rising_edge(clock)) then
         expc <= nexpc;
         mce_latch <= mce;

         if(reset = '1') then
            mce_latch <= '0';
         end if;
      end if;
   end process;
end architecture;
