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
use ieee.numeric_std.all;
library lpm;
use lpm.lpm_components.all;
library altera_mf;
use altera_mf.altera_mf_components.all;
library altera;
use altera.altera_syn_attributes.all;
library z48common;
use z48common.z48common.all;

entity z48pipe is
   generic(
      STAGES:                       integer;
      PIPE_ID:                      integer;
      SIBLING_PIPE_ID:              integer;
      DCACHE_LATENCY:               integer range 1 to 2;
      SHIFT_TYPE:                   string;
      ALLOW_CASCADE:                boolean;
      FORWARD_DCACHE_EARLY:         boolean;
      FAST_MISPREDICT:              boolean;
      FAST_PREDICTOR_FEEDBACK:      boolean;
      HAVE_RETURN_ADDR_PREDICTOR:   boolean;
      FAST_REG_WRITE:               boolean;
      NO_BRANCH:                    boolean;
      UNUSED_OPERAND_POISON:        boolean := false;
      INVALID_OPERAND_POISON:       boolean := false;
      INVALID_RESULT_POISON:        boolean := false;
      LOAD_BYTEENABLES:             boolean := true
   );
   port(
      reset:                        in std_logic;
      clock:                        in std_logic;

      d_mem_in:                     in word;
      d_mem_out:                    out word;
      d_mem_addr:                   buffer word;
      d_mem_rd:                     out std_logic;
      d_mem_wr:                     out std_logic;
      d_mem_ll:                     out std_logic;
      d_mem_sc:                     out std_logic;
      d_mem_inv:                    buffer std_logic;
      d_mem_invop:                  out std_logic_vector(4 downto 0);
      d_mem_halt:                   in std_logic;
      d_mem_valid:                  in std_logic;
      d_mem_invalid:                in std_logic;
      d_mem_scok:                   in std_logic;
      d_mem_be:                     out std_logic_vector(3 downto 0);
      d_mem_kill:                   out std_logic;
      d_mem_sync:                   out std_logic;

      dtlb_miss:                    in std_logic;
      dtlb_invalid:                 in std_logic;
      dtlb_modified:                in std_logic;
      dtlb_permerr:                 in std_logic;
      dtlb_stall:                   in std_logic;

      preg:                         in preg_t;

      new_pc:                       out word;
      use_new_pc:                   out std_logic;
      flush_in:                     in std_logic_vector(S_DG to STAGES);
      flush_out:                    out std_logic_vector(S_DG to STAGES);
      flush_queue:                  out std_logic;

      read0_ad:                     out reg_t;
      read1_ad:                     out reg_t;
      read0_data:                   in vword;
      read1_data:                   in vword;
      read_as:                      out std_logic;

      stallin:                      in std_logic_vector(S_DG to STAGES);
      stallout:                     out std_logic_vector(S_DG to STAGES);

      fwdout:                       buffer p_fwd_t;
      fwds:                         in fwds_t;

      trace_p:                      out preg_t;
      trace_r:                      out res_t;

      stats_out:                    buffer stat_flags_t;

      curpc:                        out word;
      step:                         in std_logic;
      p4valid:                      out std_logic;
      r4valid:                      out std_logic;
      btb_update:                   out std_logic;
      btb_pc:                       out word;
      btb_new_target:               out word;

      c0_write:                     out std_logic;
      c0_addr:                      out reg_t;
      c0_datain:                    in word := (others => '-');
      c0_dataout:                   out word;
      c0_op:                        out cop0op_t;
      c0_stall:                     in std_logic;

      muldiv_op:                    out aluop_t;
      muldiv_i0, muldiv_i1:         out word;
      muldiv_u:                     out std_logic;
      muldiv_op_valid:              buffer std_logic;
      muldiv_stall:                 in std_logic;
      muldiv_lo, muldiv_hi:         in word;

      cu0:                          in std_logic;

      ex:                           buffer exception_t;

      LLbit:                        in std_logic;
      LLset:                        out std_logic;
      LLclr:                        out std_logic;

      mce_p:                        out preg_t;
      mce_r:                        out res_t;

      t:                            out std_logic;
      nt:                           out std_logic;
      pred_pc:                      out word
   );
end z48pipe;

architecture z48pipe of z48pipe is
   function get_rw_stage return integer is
      variable n: integer range 5 to MAX_STAGES;
   begin
      n := 4 + DCACHE_LATENCY;
      if(not FORWARD_DCACHE_EARLY) then
         n := n + 1;
      end if;
      if(not FAST_REG_WRITE) then
         n := n + 1;
      end if;
      return n;
   end function;
   constant S_M1:                   integer := 5;
   constant S_M2:                   integer := 6;
   constant S_RW:                   integer := get_rw_stage;
   constant S_BP:                   integer := get_rw_stage + 1;

   function get_mispred_stage return integer is begin
      if(FAST_MISPREDICT) then
         return S_EX;
      else
         return S_M1;
      end if;
   end function;
   constant MISPRED_STAGE:          integer range S_EX to S_M1 := get_mispred_stage;
   function get_pred_fb_stage return integer is begin
      if(FAST_PREDICTOR_FEEDBACK) then
         return S_EX;
      else
         return S_M1;
      end if;
   end function;
   constant PRED_FB_STAGE:          integer range S_EX to S_M1 := get_pred_fb_stage;
   constant S_DC:                   integer range S_M1 to S_M2 := S_EX + DCACHE_LATENCY;

   signal p, p_next:                pregs_t;
   signal r, r_next:                ress_t;
   signal p_cke, p_stall, p_annul:  std_logic_vector(p'range);

   signal stall:                    std_logic_vector(stallout'range);
   signal reg_read0, reg_read1:     vword;
   signal aluout:                   word;
   signal is_branch:                std_logic;
   signal fwd_hazard:               std_logic;
   signal eaddr:                    word;
   signal next_pc:                  word;
   signal d_mem_sh:                 word;
   signal d_mem_sext:               word;
   signal d_mem_mask4:              std_logic_vector(3 downto 0);
   signal d_mem_mask32:             word;
   signal d_mem_masked:             word;
   signal predict, mispredict:      std_logic;
   signal branch_exec:              std_logic;
   signal jr_taken:                 std_logic;
   signal jr_badtarget:             std_logic;
   signal ldstall:                  std_logic;
   signal rr_operand0, rr_operand1: word;
   signal rr_operand0_r, rr_operand1_r: word;
   signal flush_stage, flush_local: std_logic_vector(S_DG to STAGES);
   signal eret:                     std_logic;
   signal sc_failed:                std_logic;
   signal d_mem_killable:           std_logic;

   constant KEEP_FLUSH:             boolean := false;
   attribute keep:                  boolean;
   attribute keep of flush_stage:   signal is KEEP_FLUSH;
   attribute keep of flush_local:   signal is KEEP_FLUSH;
   attribute keep of flush_in:      signal is KEEP_FLUSH;
   attribute keep of flush_out:     signal is KEEP_FLUSH;

   constant KEEP_STALL:             boolean := false;
   attribute keep of stall:         signal is KEEP_STALL;
   attribute keep of stallin:       signal is KEEP_STALL;

   attribute direct_enable of p_cke: signal is true;
begin
   p(S_DG) <= preg;

   -- pre-RR: send operand addresses to register file
   read0_ad <= p(S_RR - 1).i.source(0);
   read1_ad <= p(S_RR - 1).i.source(1);
   read_as <= stall(S_RR - 1) or stallin(S_RR - 1);
   flush_queue <= flush_local(S_RR - 1);

   -- RR stage: read operands and forward recently modified operands
   -- main forwarding muxes
   rr_forwarding: process(fwds, p, read0_data, read1_data) is
      variable operand0_hazard, operand1_hazard: std_logic;
   begin
      -- default to snarfing register file outputs
      rr_operand0 <= read0_data(31 downto 0);
      operand0_hazard := not read0_data(32);
      rr_operand1 <= read1_data(31 downto 0);
      operand1_hazard := not read1_data(32);

      -- bypass pipeline as needed and check for hazards
      for j in S_BP + 1 downto S_RR + 1 loop -- careful about order and limits
         for i in fwds'low to fwds'high loop
            if(fwds(i)(j).enable = '1') then
               if(fwds(i)(j).dreg = p(S_RR).i.source(0)) then
                  operand0_hazard := not fwds(i)(j).data(32);
                  rr_operand0 <= fwds(i)(j).data(31 downto 0);
               end if;
               if(fwds(i)(j).dreg = p(S_RR).i.source(1)) then
                  operand1_hazard := not fwds(i)(j).data(32);
                  rr_operand1 <= fwds(i)(j).data(31 downto 0);
               end if;
            end if;
         end loop;
      end loop;

      -- poison unused operands
      if(UNUSED_OPERAND_POISON) then
         if(p(S_RR).i.reads(0) = '0') then
            rr_operand0 <= x"1badcafe";
            operand0_hazard := '0';
         end if;
         if(p(S_RR).i.reads(1) = '0') then
            rr_operand1 <= x"1badcafe";
            operand1_hazard := '0';
         end if;
      end if;

      -- override for immediate values
      if(p(S_RR).i.use_immed = '1') then
         rr_operand1 <= p(S_RR).i.immed;
         operand1_hazard := '0';
      end if;

      -- poison invalid operands
      if(INVALID_OPERAND_POISON) then
         if(operand0_hazard = '1') then
            rr_operand0 <= x"0badca5e";
         end if;
         if(operand1_hazard = '1') then
            rr_operand1 <= x"0badca5e";
         end if;
      end if;

      -- r0 ($zero) is always valid
      if(p(S_RR).i.source(0) = "00000") then
         operand0_hazard := '0';
      end if;
      if(p(S_RR).i.source(1) = "00000") then
         operand1_hazard := '0';
      end if;

      fwd_hazard <= p(S_RR).i.valid and (operand0_hazard or operand1_hazard);
   end process;

   -- EX stage: execute
   -- late fowarding muxes
   ex_forwarding: process(p, fwds, rr_operand0_r, rr_operand1_r) is begin
      -- grab pre-forwarded operands from RR stage
      r(S_EX).operand0 <= rr_operand0_r;
      r(S_EX).operand1 <= rr_operand1_r;
      
      -- overrides for cascading
      if(ALLOW_CASCADE and (SIBLING_PIPE_ID < PIPE_ID)) then
         if(p(S_EX).i.cascade0 = '1') then
            r(S_EX).operand0 <= fwds(SIBLING_PIPE_ID)(S_EX).data(31 downto 0);
         end if;
         if(p(S_EX).i.cascade1 = '1') then
            r(S_EX).operand1 <= fwds(SIBLING_PIPE_ID)(S_EX).data(31 downto 0);
         end if;
      end if;
   end process;

   alu: entity work.z48alu generic map(
      SHIFT_TYPE => SHIFT_TYPE
   )
   port map(
      clock => clock,
      rst => reset,
      op => p(S_EX).i.aluop,
      u => p(S_EX).i.u,
      i0 => r(S_EX).operand0,
      i1 => r(S_EX).operand1,
      right_shift => p(S_EX).i.right_shift,
      o => aluout,
      v => r(S_EX).v,
      z => r(S_EX).z,
      n => r(S_EX).n
   );

   r(S_EX).result(32) <=
      '0' when p(S_EX).i.late = '1' else
      '0' when not FAST_MISPREDICT and p(S_EX).i.in_annul_slot = '1' else
      '1';
   r(S_EX).result(31 downto 0) <=   next_pc when p(S_EX).i.op = i_br else
                                    next_pc when p(S_EX).i.op = i_jr else
                                    aluout;

   r(S_EX).valid <=
      '0' when p(S_EX).i.valid = '0' else
      '1' when p(S_EX).i.cond = c_true else
      '1' when p(S_EX).i.cond = c_ne and r(S_EX).z = '0' else
      '1' when p(S_EX).i.cond = c_eq and r(S_EX).z = '1' else
      '1' when p(S_EX).i.cond = c_ge and r(S_EX).n = '0' else
      '1' when p(S_EX).i.cond = c_lt and r(S_EX).n = '1' else
      '1' when p(S_EX).i.cond = c_gt and
         (r(S_EX).n = '0' and r(S_EX).z = '0') else
      '1' when p(S_EX).i.cond = c_le and
         (r(S_EX).n = '1' or r(S_EX).z = '1') else
      '0';

   is_branch <=   '0' when NO_BRANCH else
                  '0' when p(S_EX).i.valid = '0' else
                  '1' when p(S_EX).i.op = i_br else
                  '1' when p(S_EX).i.op = i_jr else
                  '1' when p(S_EX).i.op = i_pflush else
                  '0';

   jr_taken <= '1' when p(S_EX).i.op = i_jr and r(S_EX).valid = '1' else '0';
   jr_badtarget <= '1' when jr_taken = '1' and p(S_EX).pred = '1' and r(S_EX).operand0 /= p(S_EX).new_pc else '0';

   branch_exec <= is_branch and not (stall(S_EX) or stallin(S_EX));
   r(S_EX).t <= is_branch and r(S_EX).valid;
   r(S_EX).nt <= is_branch and not r(S_EX).valid;
   predict <= is_branch and not ((p(S_EX).pred xor r(S_EX).valid) or jr_badtarget);
   mispredict <= is_branch and ((p(S_EX).pred xor r(S_EX).valid) or jr_badtarget);

   stats_out.predict <= branch_exec and predict;
   stats_out.mispredict <= branch_exec and mispredict;
   stats_out.clever_flush <= branch_exec and p(S_EX).i.noflush;

   next_pc <= p(S_EX).pc + 8;
   r(S_EX).new_pc <= p(S_EX).pc + 4 when p(S_EX).i.op = i_pflush else
                     next_pc when r(S_EX).valid = '0' else
                     r(S_EX).operand0 when p(S_EX).i.op = i_jr else
                     p(S_EX).new_pc;
   r(S_EX).use_new_pc <= mispredict and not flush_local(S_EX) and not p(S_EX).i.noflush;
   r(S_EX).predict <= predict and not flush_local(S_EX) and not p(S_EX).i.noflush;
   r(S_EX).mispredict <= mispredict and not flush_local(S_EX) and not p(S_EX).i.noflush;

   new_pc <= r(MISPRED_STAGE).new_pc;
   use_new_pc <= p(MISPRED_STAGE).i.valid and r(MISPRED_STAGE).use_new_pc and not flush_local(MISPRED_STAGE);

   btb_pc <= p(PRED_FB_STAGE).pc;
   btb_update <=  '0' when p(PRED_FB_STAGE).i.valid = '0' else
                  '0' when p(PRED_FB_STAGE).i.op /= i_jr else
                  '0' when HAVE_RETURN_ADDR_PREDICTOR and
                           p(PRED_FB_STAGE).i.source(0) = "11111" else
                  '1';
   btb_new_target <= r(PRED_FB_STAGE).operand0;
   t <= r(PRED_FB_STAGE).t;
   nt <= r(PRED_FB_STAGE).nt;
   pred_pc <= p(PRED_FB_STAGE).pc;

   curpc <= p(S_EX).pc;
   p4valid <= p(S_EX).i.valid and not flush_local(S_EX);
   r4valid <= r(S_EX).valid and not flush_local(S_EX);

   -- drive all pipeline flush signals
   pipe_flush: process(p, r, ex) is
      variable flush: std_logic_vector(S_DG to STAGES);
   begin
      eret <= '0';
      flush := (others => '0');

      -- eret in stage M1 flushes later insns
      if(r(S_M1).valid = '1' and p(S_M1).i.cop0op = c0_eret) then
         eret <= '1';
         flush(S_M1 - 1) := '1';
      end if;
      -- exception in stage M1 flushes current & later insns
      if(ex.raise = '1') then
         flush(S_M1) := '1';
      end if;
      -- mispredict flushes later insns
      if(p(MISPRED_STAGE).i.valid = '1' and r(MISPRED_STAGE).mispredict = '1') then
         flush(MISPRED_STAGE - 1) := '1';
      end if;

      -- drive local flush signals
      for i in flush'high - 1 downto flush'low loop
         flush(i) := flush(i) or flush(i + 1);
      end loop;
      flush_stage <= flush;

      -- drive sibling flush signals
      if(PIPE_ID < SIBLING_PIPE_ID) then
         flush_out <= flush;
      else
         flush_out <= flush(flush'low + 1 to flush'high) & '0';
      end if;
      -- a not-taken branch-likely flushes the sibling's delay slot instruction
      if(p(MISPRED_STAGE).i.valid = '1' and p(MISPRED_STAGE).i.likely = '1' and r(MISPRED_STAGE).nt = '1') then
         flush_out(MISPRED_STAGE) <= '1';
      end if;
   end process;
   flush_local <= flush_in or flush_stage;

   -- stall logic
   stall(S_DG) <= stall(S_RR);
   stall(S_RR) <= stall(S_EX) or fwd_hazard;
   stall(S_EX) <= stall(S_M1) or not step;
   stall(S_M1) <= stall(S_M2) or c0_stall or muldiv_stall or d_mem_halt;
   -- stages after S_M1 cannot stall; it complicates exceptions and dcache
   -- access dramatically
   stall(S_M2 to STAGES) <= (others => '0');
   stallout <= stall;

   stats_out.not_stalled <= not stall(stall'low);
   stats_out.fwd_hazard <= fwd_hazard and not (stall(S_EX) or stallin(S_EX));
   stats_out.d_mem_halt <= d_mem_halt;
   stats_out.exec <= '1' when p(S_EX).i.valid = '1' and flush_local(S_EX) = '0' and p(S_EX).i.op /= i_nop and stall(S_EX) = '0' and stallin(S_EX) = '0' else '0';
   stats_out.alustall <= muldiv_stall;
   stats_out.uncond_branch <= '1' when branch_exec = '1' and p(S_EX).i.cond = c_true else '0';
   stats_out.compute_branch <= '1' when branch_exec = '1' and p(S_EX).i.op = i_jr else '0';

   -- dcache interface glue
   d_mem_rd <= '0' when p(S_M1 - 1).i.valid = '0' else
               '0' when stall(S_M1 - 1) = '1' or stallin(S_M1 - 1) = '1' else
               '0' when flush_local(S_M1 - 1) = '1' else
               '1' when p(S_M1 - 1).i.op = i_ld else
               '0';

   d_mem_wr <= '0' when p(S_M1 - 1).i.valid = '0' else
               '0' when stall(S_M1 - 1) = '1' or stallin(S_M1 - 1) = '1' else
               '0' when flush_local(S_M1 - 1) = '1' else
               '1' when p(S_M1 - 1).i.op = i_st else
               '0';

   d_mem_ll <= '0' when p(S_M1 - 1).i.valid = '0' else
               '0' when stall(S_M1 - 1) = '1' or stallin(S_M1 - 1) = '1' else
               '0' when flush_local(S_M1 - 1) = '1' else
               '1' when p(S_M1 - 1).i.ll = '1' else
               '0';

   d_mem_sc <= '0' when p(S_M1 - 1).i.valid = '0' else
               '0' when stall(S_M1 - 1) = '1' or stallin(S_M1 - 1) = '1' else
               '0' when flush_local(S_M1 - 1) = '1' else
               '1' when p(S_M1 - 1).i.sc = '1' else
               '0';

   d_mem_inv <=   '0' when p(S_M1 - 1).i.valid = '0' else
                  '0' when stall(S_M1 - 1) = '1' or stallin(S_M1 - 1) = '1' else
                  '0' when flush_local(S_M1 - 1) = '1' else
                  '1' when p(S_M1 - 1).i.op = i_cache else
                  '0';

   d_mem_invop <= p(S_M1 - 1).i.source(0);

   d_mem_sync <=  '0' when p(S_M1 - 1).i.valid = '0' else
                  '0' when stall(S_M1 - 1) = '1' or stallin(S_M1 - 1) = '1' else
                  '0' when flush_local(S_M1 - 1) = '1' else
                  '1' when p(S_M1 - 1).i.op = i_sync else
                  '0';

   d_mem_killable <= '0' when p(S_M1).i.valid = '0' else
                     '1' when p(S_M1).i.op = i_ld else
                     '1' when p(S_M1).i.op = i_st else
                     '1' when p(S_M1).i.op = i_cache else
                     '1' when p(S_M1).i.op = i_sync else
                     '0';
   sc_failed <= p(S_M1).i.valid and p(S_M1).i.sc and not (LLbit and d_mem_scok);
   d_mem_kill <= d_mem_killable and (flush_local(S_M1) or sc_failed);

   eaddr <= r(S_EX).operand1 + ((31 downto 16 => p(S_EX).i.immed(15)) & p(S_EX).i.immed(15 downto 0));
   r(S_EX).eaddr <= eaddr;
   d_mem_addr <= eaddr and x"fffffffc";
   d_mem_out <=
      shr(r(S_EX).operand0, (not eaddr(1 downto 0)) & "000") when p(S_EX).i.mem = m_swl else
      shl(r(S_EX).operand0, eaddr(1 downto 0) & "000");
   d_mem_be <=
      "0001" when p(S_EX).i.mem = m_sb and eaddr(1 downto 0) = "00" else
      "0010" when p(S_EX).i.mem = m_sb and eaddr(1 downto 0) = "01" else
      "0100" when p(S_EX).i.mem = m_sb and eaddr(1 downto 0) = "10" else
      "1000" when p(S_EX).i.mem = m_sb and eaddr(1 downto 0) = "11" else
      "0011" when p(S_EX).i.mem = m_sh and eaddr(1) = '0' else
      "1100" when p(S_EX).i.mem = m_sh and eaddr(1) = '1' else
      "0001" when p(S_EX).i.mem = m_swl and eaddr(1 downto 0) = "00" else
      "0011" when p(S_EX).i.mem = m_swl and eaddr(1 downto 0) = "01" else
      "0111" when p(S_EX).i.mem = m_swl and eaddr(1 downto 0) = "10" else
      "1111" when p(S_EX).i.mem = m_swl and eaddr(1 downto 0) = "11" else
      "1111" when p(S_EX).i.mem = m_swr and eaddr(1 downto 0) = "00" else
      "1110" when p(S_EX).i.mem = m_swr and eaddr(1 downto 0) = "01" else
      "1100" when p(S_EX).i.mem = m_swr and eaddr(1 downto 0) = "10" else
      "1000" when p(S_EX).i.mem = m_swr and eaddr(1 downto 0) = "11" else
      "1111" when not LOAD_BYTEENABLES else
      "0001" when p(S_EX).i.mem = m_lb and eaddr(1 downto 0) = "00" else
      "0010" when p(S_EX).i.mem = m_lb and eaddr(1 downto 0) = "01" else
      "0100" when p(S_EX).i.mem = m_lb and eaddr(1 downto 0) = "10" else
      "1000" when p(S_EX).i.mem = m_lb and eaddr(1 downto 0) = "11" else
      "0011" when p(S_EX).i.mem = m_lh and eaddr(1) = '0' else
      "1100" when p(S_EX).i.mem = m_lh and eaddr(1) = '1' else
      "1111";

   r(S_EX).d_unaligned <=
      '1' when p(S_EX).i.mem = m_lw and eaddr(1 downto 0) /= "00" else
      '1' when p(S_EX).i.mem = m_lh and eaddr(0) /= '0' else
      '1' when p(S_EX).i.mem = m_sw and eaddr(1 downto 0) /= "00" else
      '1' when p(S_EX).i.mem = m_sh and eaddr(0) /= '0' else
      '0';

   r(S_EX).m_shr <=
      '1' when p(S_EX).i.mem = m_lwr else
      '1' when p(S_EX).i.mem = m_lh and eaddr(1 downto 0) /= "00" else
      '1' when p(S_EX).i.mem = m_lb and eaddr(1 downto 0) /= "00" else
      '0';
   r(S_EX).m_shl <= '1' when p(S_EX).i.mem = m_lwl else '0';
   r(S_EX).m_dist <=
      eaddr(1 downto 0) when p(S_EX).i.mem = m_lb else
      eaddr(1 downto 0) when p(S_EX).i.mem = m_lh else
      eaddr(1 downto 0) when p(S_EX).i.mem = m_lwr else
      not eaddr(1 downto 0) when p(S_EX).i.mem = m_lwl else
      "00";
   d_mem_sh <=
      shl(d_mem_in, r(S_DC).m_dist & "000") when r(S_DC).m_shl = '1' else
      shr(d_mem_in, r(S_DC).m_dist & "000") when r(S_DC).m_shr = '1' else
      d_mem_in;
   d_mem_sext <=
      (31 downto 16 => '0') & d_mem_sh(15 downto 0) when p(S_DC).i.mem = m_lh and p(S_DC).i.u = '1' else
      (31 downto 8 => '0') & d_mem_sh(7 downto 0) when p(S_DC).i.mem = m_lb and p(S_DC).i.u = '1' else
      (31 downto 16 => d_mem_sh(15)) & d_mem_sh(15 downto 0) when p(S_DC).i.mem = m_lh else
      (31 downto 8 => d_mem_sh(7)) & d_mem_sh(7 downto 0) when p(S_DC).i.mem = m_lb else
      d_mem_sh;
   d_mem_mask4 <=
      "1000" when p(S_DC).i.mem = m_lwl and r(S_DC).eaddr(1 downto 0) = "00" else
      "1100" when p(S_DC).i.mem = m_lwl and r(S_DC).eaddr(1 downto 0) = "01" else
      "1110" when p(S_DC).i.mem = m_lwl and r(S_DC).eaddr(1 downto 0) = "10" else
      "1111" when p(S_DC).i.mem = m_lwl and r(S_DC).eaddr(1 downto 0) = "11" else
      "0001" when p(S_DC).i.mem = m_lwr and r(S_DC).eaddr(1 downto 0) = "11" else
      "0011" when p(S_DC).i.mem = m_lwr and r(S_DC).eaddr(1 downto 0) = "10" else
      "0111" when p(S_DC).i.mem = m_lwr and r(S_DC).eaddr(1 downto 0) = "01" else
      "1111" when p(S_DC).i.mem = m_lwr and r(S_DC).eaddr(1 downto 0) = "00" else
      "1111";
   d_mem_mask32 <= (
      31 downto 24 => d_mem_mask4(3),
      23 downto 16 => d_mem_mask4(2),
      15 downto 8 => d_mem_mask4(1),
      7 downto 0 => d_mem_mask4(0)
   );
   d_mem_masked <= (d_mem_sext and d_mem_mask32) or (r(S_DC).operand0 and not d_mem_mask32);

   -- M1 stage coprocessor & mul/div glue
   c0_write <= '0' when flush_local(S_M1) = '1' else
               p(S_M1).i.valid when p(S_M1).i.cop0op = c0_mtc and cu0 = '1' else
               '0';
   c0_addr <= p(S_M1).i.source(0);
   c0_dataout <= r(S_M1).result(31 downto 0);
   c0_op <= c0_nop when flush_local(S_M1) = '1' else
            p(S_M1).i.cop0op when p(S_M1).i.valid = '1' and cu0 = '1' else
            c0_nop;  -- abort current cop0 operation if raising an exception
                     -- (in other pipe)
   LLset <= p(S_M1).i.valid and p(S_M1).i.ll and not flush_local(S_M1);
   LLclr <= eret;

   muldiv_i0 <= r(S_M1).operand0;
   muldiv_i1 <= r(S_M1).operand1;
   muldiv_op <= p(S_M1).i.aluop;
   muldiv_op_valid <=
      '0' when flush_local(S_M1) = '1' else
      p(S_M1).i.valid when p(S_M1).i.op = i_muldiv else
      '0';  -- abort current mul/div instruction if raising an exception
            -- (in other pipe)
   muldiv_u <= p(S_M1).i.u;

   -- forwarding path output driver
   fwds_out: process(p, r, c0_datain, muldiv_lo, muldiv_hi, d_mem_valid, d_mem_masked, flush_local) is begin
      for i in S_EX to STAGES loop
         fwdout(i).dreg <= p(i).i.dest;
         fwdout(i).data <= r(i).result;
         fwdout(i).enable <= p(i).i.writes_reg and p(i).i.valid;
         if(INVALID_RESULT_POISON and r(i).result(32) = '0') then
            fwdout(i).data(31 downto 0) <= x"badc0fee";
         end if;
         -- probably want this on since it reduces load->use by 1 cycle
         if(FORWARD_DCACHE_EARLY and (i = S_DC) and p(i).i.op = i_ld) then
            fwdout(i).data <= d_mem_valid & d_mem_masked;
            if(INVALID_RESULT_POISON and d_mem_valid = '0') then
               fwdout(i).data(31 downto 0) <= x"badc0fee";
            end if;
         end if;
         -- if current instruction is being flushed, do not forward result
         if(flush_local(i) = '1') then
            fwdout(i).enable <= '0';
         end if;
      end loop;
      for i in STAGES + 1 to MAX_STAGES loop
         fwdout(i).enable <= '0';
      end loop;
   end process;

   -- exception glue
   r(S_M1 - 1).except <= '0';
   r(S_M1 - 1).exc <= (others => '0');
   r(S_M1 - 1).except_under_stall <= '0';

   -- M1 stage exception detection & throwing
   process(p, r, dtlb_miss, dtlb_invalid, dtlb_modified, dtlb_permerr, cu0, flush_in(S_M1), dtlb_stall) is begin
      ex.code <= 0;
      ex.epc <= p(S_M1).pc;
      ex.bd <= p(S_M1).i.in_delay_slot;
      ex.raise <= '0';
      ex.vaddr <= r(S_M1).eaddr;
      ex.refill <= '0';
      ex.badvaddr <= '0';
      ex.ce <= 0;

      if(r(S_M1).valid = '1') then
         if(p(S_M1).i.op = i_trap and p(S_M1).i.trap = t_int) then
            ex.code <= EXC_INT;
            ex.raise <= '1';
         elsif(p(S_M1).i.trap_ov = '1' and r(S_M1).v = '1') then
            ex.code <= EXC_OV;
            ex.raise <= '1';
         elsif(p(S_M1).i.op = i_trap and p(S_M1).i.trap = t_trap) then
            ex.code <= EXC_TR;
            ex.raise <= '1';
         elsif(p(S_M1).i.op = i_trap and p(S_M1).i.trap = t_syscall) then
            ex.code <= EXC_SYS;
            ex.raise <= '1';
         elsif(p(S_M1).i.op = i_trap and p(S_M1).i.trap = t_break) then
            ex.code <= EXC_BP;
            ex.raise <= '1';
         elsif(p(S_M1).i.op = i_trap and p(S_M1).i.trap = t_invalid) then
            ex.code <= EXC_RI;
            ex.raise <= '1';
         elsif((p(S_M1).i.op = i_cop0 and cu0 = '0') or
               (p(S_M1).i.op = i_cop1) or
               (p(S_M1).i.op = i_cop2) or
               (p(S_M1).i.op = i_cop3)) then
            ex.code <= EXC_CPU;
            ex.raise <= '1';
            case p(S_M1).i.op is
               when i_cop0 => ex.ce <= 0;
               when i_cop1 => ex.ce <= 1;
               when i_cop2 => ex.ce <= 2;
               when i_cop3 => ex.ce <= 3;
               when others => null;
            end case;
         elsif(p(S_M1).i.op = i_cache and cu0 = '0') then
            ex.code <= EXC_CPU;
            ex.ce <= 0;
            ex.raise <= '1';
         elsif(p(S_M1).i.op = i_trap and p(S_M1).i.trap = t_itlb_refill) then
            ex.code <= EXC_TLBL;
            ex.vaddr <= p(S_M1).pc;
            ex.badvaddr <= '1';
            ex.refill <= '1';
            ex.raise <= '1';
         elsif(p(S_M1).i.op = i_trap and p(S_M1).i.trap = t_itlb_tlbl) then
            ex.code <= EXC_TLBL;
            ex.vaddr <= p(S_M1).pc;
            ex.badvaddr <= '1';
            ex.raise <= '1';
         elsif(p(S_M1).i.op = i_trap and p(S_M1).i.trap = t_itlb_adel) then
            ex.code <= EXC_ADEL;
            ex.vaddr <= p(S_M1).pc;
            ex.badvaddr <= '1';
            ex.raise <= '1';
         elsif(r(S_M1).d_unaligned = '1' or dtlb_permerr = '1') then
            if(p(S_M1).i.op = i_st) then
               ex.code <= EXC_ADES;
               ex.badvaddr <= '1';
               ex.raise <= '1';
            elsif(p(S_M1).i.op = i_ld) then
               ex.code <= EXC_ADEL;
               ex.badvaddr <= '1';
               ex.raise <= '1';
            elsif(p(S_M1).i.op = i_cache) then
               ex.code <= EXC_ADEL;
               ex.badvaddr <= '1';
               ex.raise <= '1';
            end if;
         elsif(dtlb_miss = '1' or dtlb_invalid = '1') then
            if(p(S_M1).i.op = i_st) then
               ex.code <= EXC_TLBS;
               ex.refill <= dtlb_miss;
               ex.badvaddr <= '1';
               ex.raise <= '1';
            elsif(p(S_M1).i.op = i_ld) then
               ex.code <= EXC_TLBL;
               ex.refill <= dtlb_miss;
               ex.badvaddr <= '1';
               ex.raise <= '1';
            elsif(p(S_M1).i.op = i_cache) then
               ex.code <= EXC_TLBL;
               ex.refill <= dtlb_miss;
               ex.badvaddr <= '1';
               ex.raise <= '1';
            end if;
         elsif(dtlb_modified = '1') then
            if(p(S_M1).i.op = i_st) then
               ex.code <= EXC_MOD;
               ex.badvaddr <= '1';
               ex.raise <= '1';
            end if;
         end if;
      end if;
      if(flush_in(S_M1) = '1' or dtlb_stall = '1') then
         ex.raise <= '0';
      end if;
   end process;

   mce_p <= p(S_M1 + 1);
   mce_r <= r(S_M1 + 1);
   trace_p <= p(STAGES);
   trace_r <= r(STAGES);

   -- input and clock-enable logic for all pipeline registers
   p_reg_control: for i in p'low + 1 to STAGES generate
      p_stall(i) <= stall(i) or stallin(i);
      p_annul(i) <= flush_local(i) when p_stall(i) = '1' else flush_local(i - 1);
      p_cke(i) <= (not p_stall(i)) or p_annul(i);
   end generate;
   p_reg_data: process(p, p_stall, p_annul) is begin
      for i in p'low + 1 to STAGES loop
         p_next(i) <= p(i - 1);
         if(p_stall(i - 1) = '1' or p_annul(i) = '1') then
            p_next(i).i.valid <= '0';
         end if;
      end loop;
   end process;
   r_reg_data: process(r, p_stall, p_annul) is begin
      for i in r'low + 1 to STAGES loop
         r_next(i) <= r(i - 1);
         if(p_stall(i - 1) = '1' or p_annul(i) = '1') then
            r_next(i).valid <= '0';
         end if;
      end loop;
   end process;

   -- pipeline registers
   process(clock) is begin
      if(rising_edge(clock)) then
         for i in p'low + 1 to STAGES loop
            if(p_cke(i) = '1') then
               p(i) <= p_next(i);
            end if;
         end loop;
         for i in r'low + 1 to STAGES loop
            if(p_cke(i) = '1') then
               r(i) <= r_next(i);
            end if;
         end loop;

         -- tag instructions moving out of M1 with exception info
         r(S_M1 + 1).exc <= vec(ex.code, 5);
         r(S_M1 + 1).except <= ex.raise;
         if(stall(S_M1) = '1' or stallin(S_M1) = '1') then
            r(S_M1 + 1).except_under_stall <= ex.raise;
         end if;

         -- complete late-result type instructions
         if(p(S_M1).i.cop0op = c0_mfc) then
            r(S_M1 + 1).result <= '1' & c0_datain;
         end if;
         if(p(S_M1).i.aluop = a_mflo) then
            r(S_M1 + 1).result <= '1' & muldiv_lo;
         end if;
         if(p(S_M1).i.aluop = a_mfhi) then
            r(S_M1 + 1).result <= '1' & muldiv_hi;
         end if;
         if(p(S_M1).i.sc = '1') then
            r(S_M1 + 1).result <= (32 => '1', 31 downto 1 => '0', 0 => (LLbit and d_mem_scok));
         end if;
         if(p(S_DC).i.op = i_ld) then
            r(S_DC + 1).result <= d_mem_valid & d_mem_masked;
         end if;
         if(not FAST_MISPREDICT and p(S_M1).i.in_annul_slot = '1' and p(S_M1).i.late = '0') then
            r(S_M1 + 1).result(32) <= '1';
         end if;

         if(stall(S_EX) = '0' and stallin(S_EX) = '0') then
            rr_operand0_r <= rr_operand0;
            rr_operand1_r <= rr_operand1;
         end if;

         -- synch reset
         if(reset = '1') then
            for i in p'low + 1 to p'high loop
               p(i).i.valid <= '0';
            end loop;
            for i in r'low + 1 to r'high loop
               r(i).valid <= '0';
               r(i).except <= '0';
            end loop;
         end if;
      end if;
   end process;
end;
