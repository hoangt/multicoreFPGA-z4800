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
use ieee.std_logic_arith.all;
library lpm;
use lpm.lpm_components.all;
library altera_mf;
use altera_mf.altera_mf_components.all;
library z48common;
use z48common.z48common.all;

entity cop0 is
   generic(
      JTLB_SIZE:                    integer;
      JTLB_CAM_LATENCY:             integer;
      JTLB_PRECISE_FLUSH:           boolean;
      CACHEABLE_BOOT_VECTORS:       boolean;
      DCACHE_BLOCK_BITS:             integer;
      DCACHE_OFFSET_BITS:           integer;
      DCACHE_WAYS:                  integer;
      DTLB_OFFSET_BITS:             integer;
      ICACHE_BLOCK_BITS:             integer;
      ICACHE_OFFSET_BITS:           integer;
      ICACHE_WAYS:                  integer;
      ITLB_OFFSET_BITS:             integer;
      NO_LARGE_PAGES:               boolean
   );
   port(
      clock:                        in std_logic;
      rst:                          in std_logic;
      step:                         in std_logic;

      eirqs:                        in std_logic_vector(1 downto 0);

      mbox_irq:                     in std_logic;

      cpu_write:                    in std_logic;
      cpu_addr:                     in std_logic_vector(4 downto 0);
      cpu_datain:                   in word;
      cpu_dataout:                  out word;
      cpu_cop0op:                   in cop0op_t;
      cpu_stall:                    buffer std_logic;

      p0_ex:                        in exception_t;
      p1_ex:                        in exception_t;

      fetch_new_pc:                 out word;
      fetch_use_new_pc:             out std_logic;

      asid:                         buffer std_logic_vector(7 downto 0);
      mode:                         buffer mode_t;

      LLbit:                        buffer std_logic;
      LLset:                        in std_logic;
      LLclr:                        in std_logic;

      itlb_vaddr:                   in word;
      itlb_probe:                   in std_logic;
      itlb_ack:                     out std_logic;
      itlb_nack:                    out std_logic;
      itlb_ent:                     out utlb_raw_t;
      itlb_inv_addr:                out std_logic_vector(ITLB_OFFSET_BITS - 1 downto 0);
      itlb_inv:                     out std_logic;

      dtlb_vaddr:                   in word;
      dtlb_probe:                   in std_logic;
      dtlb_ack:                     out std_logic;
      dtlb_nack:                    out std_logic;
      dtlb_ent:                     out utlb_raw_t;
      dtlb_inv_addr:                out std_logic_vector(DTLB_OFFSET_BITS - 1 downto 0);
      dtlb_inv:                     out std_logic;

      cu0:                          out std_logic;
      irq:                          buffer std_logic;

      bev_out:                      out std_logic;
      refill_out:                   out std_logic;
      eret_out:                     out std_logic;
      epc_out:                      out word;
      badvaddr_out:                 out word;

      mce:                          out std_logic
   );
end entity;

architecture cop0 of cop0 is
   signal rombase:                  word;
   type cop0_regs_t is array(31 downto 0) of word;
   signal regs:                     cop0_regs_t;

   signal tlbp, tlbr, tlbw:         std_logic;
   signal jtlb_ack, jtlb_nack:      std_logic;
   signal jtlb_index, jtlb_matchindex: word;
   signal jtlb_ent:                 tlb_raw_t;
   signal irqs:                     std_logic_vector(7 downto 0);
   signal gie:                      std_logic;
   signal tlbw_done:                std_logic;
begin
   bvc: if(CACHEABLE_BOOT_VECTORS) generate
      rombase <= x"9fc00000";
   end generate;
   bvnc: if(not CACHEABLE_BOOT_VECTORS) generate
      rombase <= x"bfc00000";
   end generate;

   jtlb: entity work.jtlb generic map(
      JTLB_SIZE => JTLB_SIZE,
      CAM_LATENCY => JTLB_CAM_LATENCY,
      PRECISE_FLUSH => JTLB_PRECISE_FLUSH,
      ITLB_OFFSET_BITS => ITLB_OFFSET_BITS,
      DTLB_OFFSET_BITS => DTLB_OFFSET_BITS,
      NO_LARGE_PAGES => NO_LARGE_PAGES
   )
   port map(
      clock => clock,
      rst => rst,

      itlb_vaddr => itlb_vaddr,
      itlb_asid => asid,
      itlb_probe => itlb_probe,
      itlb_ack => itlb_ack,
      itlb_nack => itlb_nack,
      itlb_ent => itlb_ent,
      itlb_inv_addr => itlb_inv_addr,
      itlb_inv => itlb_inv,

      dtlb_vaddr => dtlb_vaddr,
      dtlb_asid => asid,
      dtlb_probe => dtlb_probe,
      dtlb_ack => dtlb_ack,
      dtlb_nack => dtlb_nack,
      dtlb_ent => dtlb_ent,
      dtlb_inv_addr => dtlb_inv_addr,
      dtlb_inv => dtlb_inv,

      r_entryhi => regs(EntryHi),
      r_pagemask => regs(PageMask),
      r_entrylo0 => regs(EntryLo0),
      r_entrylo1 => regs(EntryLo1),
      r_index => jtlb_index,

      tlbp => tlbp,
      tlbw => tlbw,
      tlbr => tlbr,

      cop_ack => jtlb_ack,
      cop_nack => jtlb_nack,
      cop_index => jtlb_matchindex,
      cop_ent => jtlb_ent,
      tlbw_done => tlbw_done,

      mce => mce
   );

   process(clock) is
      variable vector: std_logic_vector(11 downto 0);

      procedure handle_exception(x: exception_t) is begin
         if(regs(Status)(STATUS_EXL) = '0') then
            regs(Cause)(CAUSE_BD) <= x.bd;
            if(x.bd = '1') then
               regs(EPC) <= x.epc - 4;
            else
               regs(EPC) <= x.epc;
            end if;
            if(x.refill = '1') then
               vector := x"000";
               refill_out <= '1';
            else
               vector := x"180";
            end if;
         else
            vector := x"180";
         end if;
         regs(Cause)(CAUSE_EXC_H downto CAUSE_EXC_L) <= vec(x.code, 5);
         regs(Status)(STATUS_EXL) <= '1';
         if(regs(Status)(STATUS_BEV) = '1') then
            fetch_new_pc <= rombase + x"200" + vector;
         else
            fetch_new_pc <= x"80000000" + vector;
         end if;
         fetch_use_new_pc <= '1';
         if(x.badvaddr = '1') then
            regs(BadVAddr) <= x.vaddr;
            regs(Context)(22 downto 4) <= x.vaddr(31 downto 13);
            regs(EntryHi)(31 downto 13) <= x.vaddr(31 downto 13);
         end if;
         regs(Cause)(CAUSE_CE_H downto CAUSE_CE_L) <= vec(x.ce, 2);
      end procedure;
   begin
      if(rising_edge(clock)) then
         fetch_use_new_pc <= '0';
         tlbp <= '0';
         tlbr <= '0';
         tlbw <= '0';
         refill_out <= '0';
         eret_out <= '0';

         regs(Cause)(CAUSE_IP3) <= mbox_irq;
         regs(Cause)(CAUSE_IP4) <= eirqs(0);
         regs(Cause)(CAUSE_IP5) <= eirqs(1);

         if(cpu_cop0op = c0_eret) then
            fetch_new_pc <= regs(EPC);
            fetch_use_new_pc <= '1';
            regs(Status)(STATUS_EXL) <= '0';
            eret_out <= '1';
         end if;

         if(p0_ex.raise = '1') then
            handle_exception(p0_ex);
         elsif(p1_ex.raise = '1') then
            handle_exception(p1_ex);
         end if;

         if(step = '1') then
            regs(Count) <= regs(Count) + 1;
         end if;
         if(regs(Count) = regs(Compare)) then
            regs(Cause)(CAUSE_IP7) <= '1';
         end if;
         if(cpu_write = '1' and int(cpu_addr) = Compare) then
            regs(Cause)(CAUSE_IP7) <= '0';
         end if;

         if((cpu_write = '1' and int(cpu_addr) = Random) or (regs(Random) = regs(Wired)) or (cpu_write = '1' and int(cpu_addr) = Wired)) then
            regs(Random) <= conv_std_logic_vector(JTLB_SIZE - 1, 32);
         else
            regs(Random) <= regs(Random) - 1;
         end if;

         if(cpu_cop0op = c0_tlbwi) then
            jtlb_index <= regs(Index);
            tlbw <= '1';
            if(tlbw_done = '1') then
               tlbw <= '0';
            end if;
         elsif(cpu_cop0op = c0_tlbwr) then
            jtlb_index <= regs(Random);
            tlbw <= '1';
            if(tlbw_done = '1') then
               tlbw <= '0';
            end if;
         elsif(cpu_cop0op = c0_tlbr) then
            jtlb_index <= regs(Index);
            tlbr <= '1';
            if(jtlb_ack = '1') then
               tlbr <= '0';
               regs(PageMask) <= jtlb_ent(127 downto 96);
               regs(PageMask)(12 downto 0) <= (others => '0');
               regs(EntryHi) <= jtlb_ent(95 downto 64);
               regs(EntryHi)(11 downto 8) <= (others => '0');
               regs(EntryLo1) <= jtlb_ent(63 downto 32);
               regs(EntryLo1)(31 downto 26) <= (others => '0');
               regs(EntryLo0) <= jtlb_ent(31 downto 0);
               regs(EntryLo0)(31 downto 26) <= (others => '0');
            end if;
         elsif(cpu_cop0op = c0_tlbp) then
            tlbp <= '1';
            if(jtlb_ack = '1') then
               tlbp <= '0';
               regs(Index) <= jtlb_matchindex;
               regs(Index)(31) <= '0';
            elsif(jtlb_nack = '1') then
               tlbp <= '0';
               regs(Index)(31) <= '1';
            end if;
         end if;

         if(cpu_write = '1') then
            regs(int(cpu_addr)) <= cpu_datain;
         end if;

         bev_out <= regs(Status)(STATUS_BEV);
         epc_out <= regs(EPC);
         badvaddr_out <= regs(BadVAddr);

         if(LLset = '1') then
            LLbit <= '1';
         end if;
         if(LLclr = '1') then
            LLbit <= '0';
         end if;

         -- synch reset
         if(rst = '1') then
            for i in regs'range loop
               regs(i) <= (others => '0');
            end loop;
            regs(Status)(STATUS_TS) <= '0';
            regs(Status)(STATUS_ERL) <= '1';
            regs(Status)(STATUS_BEV) <= '1';
            regs(Status)(STATUS_IM7 downto STATUS_IM0) <= (others => '0');
            regs(Status)(STATUS_IE) <= '0';
            fetch_use_new_pc <= '0';
            tlbw <= '0';
            tlbp <= '0';
            tlbr <= '0';
            regs(Random) <= conv_std_logic_vector(JTLB_SIZE - 1, 32);
            bev_out <= '0';
            refill_out <= '0';
            eret_out <= '0';
            LLbit <= '1';
         end if;
      end if;

      for i in regs'range loop
         if(RegImpl(i) = '0') then
            regs(i) <= (others => '-');
         end if;
      end loop;
      regs(Random)(31 downto 8) <= (others => '0');
      regs(Wired)(31 downto 8) <= (others => '0');
      regs(PRId) <= x"00004800";

      regs(Config) <= (others => '0');
      regs(Config)(4 downto 0) <= vec(DCACHE_BLOCK_BITS, 5);
      regs(Config)(9 downto 5) <= vec(DCACHE_OFFSET_BITS, 5);
      regs(Config)(12 downto 10) <= vec(DCACHE_WAYS - 1, 3);
      regs(Config)(17 downto 13) <= vec(ICACHE_BLOCK_BITS, 5);
      regs(Config)(22 downto 18) <= vec(ICACHE_OFFSET_BITS, 5);
      regs(Config)(25 downto 23) <= vec(ICACHE_WAYS - 1, 3);
   end process;

   mode <=  M_USER when regs(Status)(STATUS_KSU_H downto STATUS_KSU_L) = "10" and regs(Status)(STATUS_EXL) = '0' and regs(Status)(STATUS_ERL) = '0' else
            M_SUPERVISOR when regs(Status)(STATUS_KSU_H downto STATUS_KSU_L) = "01" and regs(Status)(STATUS_EXL) = '0' and regs(Status)(STATUS_ERL) = '0' else
            M_KERNEL;
   asid <= regs(EntryHi)(7 downto 0);
   cpu_stall <=   '1' when cpu_cop0op = c0_tlbp and (jtlb_ack = '0' and jtlb_nack = '0') else 
                  '1' when cpu_cop0op = c0_tlbr and jtlb_ack = '0' else
                  '1' when (cpu_cop0op = c0_tlbwr or cpu_cop0op = c0_tlbwi) and tlbw_done = '0' else
                  '0';
   cu0 <= '1' when mode = M_KERNEL else regs(Status)(STATUS_CU0);
   irqs <= regs(Cause)(CAUSE_IP7 downto CAUSE_IP0) and regs(Status)(STATUS_IM7 downto STATUS_IM0);
   gie <= regs(Status)(STATUS_IE) and not regs(Status)(STATUS_EXL) and not regs(Status)(STATUS_ERL);
   irq <= gie when irqs /= "00000000" else '0';
   cpu_dataout <= regs(int(cpu_addr));
end architecture;
