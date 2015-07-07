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

entity z48debug is
   generic(
      AUTOBOOT:                     boolean
   );
   port( 
      reset:                        in std_logic;
      clock:                        in std_logic;

      mem_addr:                     in std_logic_vector(5 downto 0);
      mem_in:                       in word;
      mem_out:                      out word;
      mem_be:                       in std_logic_vector(3 downto 0);
      mem_rd:                       in std_logic;
      mem_wr:                       in std_logic;
      mem_halt:                     out std_logic;

      step:                         buffer std_logic;
      break_hit:                    buffer std_logic;
      any_mce:                      in std_logic;
      intreset:                     out std_logic;
      cinv:                         out std_logic;
      signaltap_trigger:            in std_logic;
      iqueue_gate:                  out std_logic;
      dcache_bypass:                out std_logic;

      reg_snoop_ad:                 out reg_t;
      reg_snoop_data:               in word;
      snoopin:                      in snoop_t;

      stats_in0:                    in stat_flags_t;
      stats_in1:                    in stat_flags_t
   );
end entity;

architecture z48debug of z48debug is
   type regs_t is array(1 downto 0) of word;
   type regs8_t is array(7 downto 0) of word;
   signal regs                :  regs_t;
   signal snoop_out           :  regs8_t;
   signal single_step         :  std_logic;
   signal mem_addr_r          :  std_logic_vector(5 downto 0);
   signal snoop               :  snoop_t;
   signal break_on_trigger    :  std_logic;
   signal signaltap_trigger_r :  std_logic;

   function pc_equals(x: word; y: word) return boolean is begin
      return x(31 downto 2) = y(31 downto 2);
   end function;
begin
   mem_out <=  reg_snoop_data when mem_addr_r(5) = '1' else
               regs(conv_integer(mem_addr_r(2 downto 0))) when mem_addr_r(5 downto 3) = "000" and conv_integer(mem_addr_r(2 downto 0)) <= regs'high else
               x"0c0ffee0" when mem_addr_r(5 downto 3) = "000" else
               snoop_out(conv_integer(mem_addr_r(2 downto 0))) when mem_addr_r(5 downto 3) = "001" else
               x"deadbeef";
   reg_snoop_ad <= mem_addr(4 downto 0);

   snoop_out(0) <= snoop.pc;
   snoop_out(1) <= snoop.next_pc;
   --snoop_out(2) <= snoop.decode_pc0;
   --snoop_out(3) <= snoop.decode_pc1;
   snoop_out(4) <= snoop.curpc0;
   snoop_out(5) <= snoop.curpc1;
   snoop_out(6) <= (
      0 => snoop.p4valid0,
      1 => snoop.p4valid1,
      2 => snoop.r4valid0,
      3 => snoop.r4valid1,
      others => '0'
   );
   --snoop_out(7) <= conv_std_logic_vector(HZ, 32);

   step <= (regs(0)(0) and not break_hit) or single_step;
   cinv <= regs(0)(5);
   break_on_trigger <= regs(0)(6);
   iqueue_gate <= regs(0)(7);
   dcache_bypass <= regs(0)(8);

   break_hit <=   regs(0)(3) when pc_equals(snoopin.curpc0, regs(1)) and snoopin.p4valid0 = '1' else
                  regs(0)(3) when pc_equals(snoopin.curpc1, regs(1)) and snoopin.p4valid1 = '1' else
                  break_on_trigger when signaltap_trigger_r = '1' else
                  '0';

   mem_halt <= '0';

   reset_reg: process(clock) is begin
      if(rising_edge(clock)) then
         intreset <= regs(0)(2);
      end if;
   end process;

   process(clock, reset) is
      variable tmp_cs: std_logic;
   begin
      -- asynch reset (to provide cpu power-on reset)
      if(reset = '1') then
         regs(0)(2) <= '1';
         if(AUTOBOOT) then
            regs(0)(1 downto 0) <= "11";
         else
            regs(0)(1 downto 0) <= "00";
         end if;
      elsif(rising_edge(clock)) then
         signaltap_trigger_r <= signaltap_trigger;
         snoop <= snoopin;
         single_step <= '0';
         if(regs(0)(1) = '0' or break_hit = '1' or any_mce = '1') then
            regs(0)(1) <= '0';
            regs(0)(0) <= '0';
         end if;
         regs(0)(2) <= '0';
         regs(0)(4) <= '0';
         regs(0)(5) <= '0';
         mem_addr_r <= mem_addr;
         if(mem_wr = '1' and mem_be /= "0000" and mem_addr(5 downto 3) = "000") then
            if(conv_integer(mem_addr(2 downto 0)) <= regs'high) then
               regs(conv_integer(mem_addr(2 downto 0))) <= mem_in;
               if(mem_addr(2 downto 0) = "000" and mem_in(0) = '1') then
                  single_step <= '1';
               end if;
            end if;
         end if;
         snoop <= snoopin;

         -- synch reset
         if(reset = '1') then
            for i in regs'range loop
               regs(i) <= (others => '0');
            end loop;
            regs(0)(2) <= '1';
            single_step <= '0';
            signaltap_trigger_r <= '0';
            if(AUTOBOOT) then
               regs(0)(1 downto 0) <= "11";
            else
               regs(0)(1 downto 0) <= "00";
            end if;
         end if;
      end if;
   end process;
end architecture;
