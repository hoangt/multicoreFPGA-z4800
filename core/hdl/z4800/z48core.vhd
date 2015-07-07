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
library z48common;
use z48common.z48common.all;

entity z48core is
   generic(
      CACHEABLE_BOOT_VECTORS:                boolean := true;

      -- alu options
      HAVE_MULTIPLY:                         boolean;
      MULTIPLY_TYPE:                         string;
      COMB_MULTIPLY_CYCLES:                  natural;
      HAVE_DIVIDE:                           boolean;
      DIVIDE_TYPE:                           string;
      COMB_DIVIDE_CYCLES:                    natural;
      SHIFT_TYPE:                            string;

      -- grouper options
      ALLOW_CASCADE:                         boolean;
      AVOID_ISSUE_AFTER_TRAP:                boolean := false;
      AVOID_DUAL_ISSUE:                      boolean := false;

      -- pipeline latency options
      FORWARD_DCACHE_EARLY:                  boolean;
      FAST_MISPREDICT:                       boolean;
      FAST_PREDICTOR_FEEDBACK:               boolean;
      FAST_REG_WRITE:                        boolean;

      -- fetch/decode/prediction options
      IQUEUE_LENGTH:                         integer;
      IQUEUE_GATE_CYCLES:                    integer := 4;
      FETCH_MISS_DELAYED:                    boolean;
      FETCH_ABORT_MISS:                      boolean;
      FETCH_BRANCH_PREDICTOR:                boolean;
      FETCH_STATIC_PREDICTOR:                boolean;
      FETCH_DYNAMIC_PREDICTOR:               boolean;
      FETCH_HAVE_BTB:                        boolean;
      FETCH_RETURN_ADDR_PREDICTOR:           boolean;
      FETCH_UNALIGNED_DELAY_SLOT:            boolean;
      FETCH_BRANCH_NOHINT:                   boolean;
      BRANCH_PREDICTOR:                      boolean;
      BRANCH_NOHINT:                         boolean;
      STATIC_BRANCH_PREDICTOR:               boolean;
      DYNAMIC_BRANCH_PREDICTOR:              boolean;
      DYNAMIC_BRANCH_BITS:                   integer := 2;
      DYNAMIC_BRANCH_SIZE:                   integer;
      DYNAMIC_BRANCH_INIT_STATE:             std_logic_vector := "10";
      CLEVER_FLUSH:                          boolean;
      HAVE_RASTACK:                          boolean;
      RASTACK_ENTRIES:                       integer;
      HAVE_BTB:                              boolean;
      BTB_TAGGED:                            boolean;
      BTB_VALID_BIT:                         boolean;
      BTB_SIZE:                              integer;

      DEBUG_ON:                              boolean;
      DEBUG_AUTOBOOT:                        boolean;
      DEBUG_DEADLOCK_DETECT:                 boolean := false;
      DEBUG_DEADLOCK_CYCLES:                 integer := 16;
      TRACE_ON:                              boolean;
      TRACE_LENGTH:                          integer;
      MCHECK_ON:                             boolean;

      JTLB_SIZE:                             integer;
      JTLB_CAM_LATENCY:                      integer;
      JTLB_PRECISE_FLUSH:                    boolean;
      NO_LARGE_PAGES:                        boolean;

      ITLB_OFFSET_BITS:                      natural;
      ITLB_WAYS:                             natural;
      ITLB_REPLACE_TYPE:                     string;
      ITLB_SUB_REPLACE_TYPE:                 string;
      ITLB_HYBRID_BLOCK_FACTOR:              natural;
      ICACHE_BLOCK_BITS:                     natural;
      ICACHE_OFFSET_BITS:                    natural;
      ICACHE_WAYS:                           natural;
      ICACHE_REPLACE_TYPE:                   string;
      ICACHE_SUB_REPLACE_TYPE:               string;
      ICACHE_HYBRID_BLOCK_FACTOR:            natural;
      ICACHE_EARLY_RESTART:                  boolean;

      DTLB_OFFSET_BITS:                      natural;
      DTLB_WAYS:                             natural;
      DTLB_REPLACE_TYPE:                     string;
      DTLB_SUB_REPLACE_TYPE:                 string;
      DTLB_HYBRID_BLOCK_FACTOR:              natural;
      DCACHE_BLOCK_BITS:                     natural;
      DCACHE_OFFSET_BITS:                    natural;
      DCACHE_WAYS:                           natural;
      DCACHE_REPLACE_TYPE:                   string;
      DCACHE_SUB_REPLACE_TYPE:               string;
      DCACHE_HYBRID_BLOCK_FACTOR:            natural;
      DCACHE_EARLY_RESTART:                  boolean;
      DCACHE_LATENCY:                        integer range 1 to 2;

      DEBUG_SDATA:                           boolean := false;
      CACHE_CLOCK_DOUBLING:                  boolean;
      CACHE_WIDTH:                           natural;
      CACHE_BLOCK_BITS:                      natural;
      CACHE_CRITICAL_WORD_FIRST:             boolean;
      CACHE_HINT_ICACHE_SHARE:               boolean;
      L2_OFFSET_BITS:                        natural;
      L2_WAYS:                               natural;
      L2_REPLACE_TYPE:                       string;
      L2_SUB_REPLACE_TYPE:                   string;
      L2_HYBRID_BLOCK_FACTOR:                natural;
      L2_ENABLE_SNOOPING:                    boolean
   );
   port(
      reset:                        in std_logic;
      clock:                        in std_logic;
      dclock:                       in std_logic;

      eirqs:                        in std_logic_vector(1 downto 0);

      iu_mem_in:                    in dword;
      iu_mem_addr:                  buffer word;
      iu_mem_rd:                    buffer std_logic;
      iu_mem_halt:                  in std_logic;
      iu_mem_valid:                 in std_logic;

      u_mem_in:                     in word;
      u_mem_out:                    buffer word;
      u_mem_addr:                   buffer word;
      u_mem_rd:                     buffer std_logic;
      u_mem_wr:                     out std_logic;
      u_mem_halt:                   in std_logic;
      u_mem_valid:                  in std_logic;
      u_mem_be:                     out std_logic_vector(3 downto 0);

      m_addr:                       out word;
      m_out:                        out std_logic_vector(CACHE_WIDTH - 1 downto 0);
      m_burstcount:                 out std_logic_vector(CACHE_BLOCK_BITS downto 0);
      m_rd:                         out std_logic;
      m_wr:                         out std_logic;
      m_halt:                       in std_logic;
      m_valid:                      in std_logic;
      m_in:                         in std_logic_vector(CACHE_WIDTH - 1 downto 0);

      s_bus_reqn:                   out std_logic;
      s_bus_gntn:                   in std_logic;
      s_bus_r_addr_oe:              out std_logic;
      s_bus_r_addr_out:             out word;
      s_bus_r_addr:                 in word;
      s_bus_r_sharen_oe:            out std_logic;
      s_bus_r_sharen:               in std_logic;
      s_bus_r_excln_oe:             out std_logic;
      s_bus_r_excln:                in std_logic;
      s_bus_a_waitn_oe:             out std_logic;
      s_bus_a_waitn:                in std_logic;
      s_bus_a_ackn_oe:              out std_logic;
      s_bus_a_ackn:                 in std_logic;
      s_bus_a_sharen_oe:            out std_logic;
      s_bus_a_sharen:               in std_logic;
      s_bus_a_excln_oe:             out std_logic;
      s_bus_a_excln:                in std_logic;

      mbox_irq:                     in std_logic;

      debug_mem_addr:               in std_logic_vector(5 downto 0) := (others => '-');
      debug_mem_in:                 in word := (others => '-');
      debug_mem_out:                out word;
      debug_mem_be:                 in std_logic_vector(3 downto 0) := "1111";
      debug_mem_rd:                 in std_logic := '0';
      debug_mem_wr:                 in std_logic := '0';
      debug_mem_halt:               out std_logic;

      trace_mem_addr:               in std_logic_vector(15 downto 0) := (others => '-');
      trace_mem_in:                 in word := (others => '-');
      trace_mem_out:                out word;
      trace_mem_be:                 in std_logic_vector(3 downto 0) := "1111";
      trace_mem_rd:                 in std_logic := '0';
      trace_mem_wr:                 in std_logic := '0';
      trace_mem_halt:               out std_logic;

      blinkenlights:                out std_logic_vector(7 downto 0);
      blinkenlights2:               out std_logic_vector(7 downto 0);

      triggermask:                  in std_logic_vector(17 downto 0);
      signaltap_trigger:            buffer std_logic;
      blinkentriggers:              out std_logic_vector(17 downto 0);

      mce_code:                     out std_logic_vector(8 downto 0);

      perf:                         out std_logic_vector(71 downto 0)
   );
end z48core;

architecture z48core of z48core is
   constant POISON_EXPC:            boolean := false;

   function get_stages return integer is
      variable n: integer range 4 to MAX_STAGES;
   begin
      n := 4 + DCACHE_LATENCY;
      if(not FORWARD_DCACHE_EARLY) then
         n := n + 1;
      end if;
      if(not FAST_REG_WRITE) then
         n := n + 1;
      end if;
      n := n + 2;
      return n;
   end function;
   constant STAGES:                 integer := get_stages;

   function get_l1_offset_bits return integer is begin
      if(DCACHE_OFFSET_BITS > ICACHE_OFFSET_BITS) then
         return DCACHE_OFFSET_BITS;
      else
         return ICACHE_OFFSET_BITS;
      end if;
   end function;

   signal intreset:                 std_logic;
   signal intreset_synch:           std_logic_vector(3 downto 0);

   signal pc, next_pc, next_ppc:    word;
   signal fetch_delay_slot:         std_logic;
   signal fetch_btb_target:         word;
   signal fetch_btb_valid:          std_logic;
   signal fetch_dbp_pred:           std_logic;
   signal expc, nexpc:              word;
   signal expc_cke:                 std_logic;
   signal expc0, expc1:             word;
   signal expc_match:               std_logic_vector(1 downto 0);
   signal flush_pipe:               std_logic;
   signal p0_new_pc, p1_new_pc:     word;
   signal p0_use_new_pc, p1_use_new_pc: std_logic;
   signal p0_flush, p1_flush:       std_logic_vector(S_DG to STAGES);
   signal p0_flush_queue, p1_flush_queue: std_logic;
   signal p0_stall, p1_stall:       std_logic_vector(S_DG to STAGES);
   signal p0_empty, p1_empty:       std_logic;
   signal p0_t, p0_nt:              std_logic;
   signal p1_t, p1_nt:              std_logic;
   signal p0_pred_pc, p1_pred_pc:   word;
   signal pred_pc:                  word;

   signal read0_ad, read1_ad, read2_ad, read3_ad, dbg_ad: reg_t;
   signal write0_ad, write1_ad:     reg_t;
   signal read0_data, read1_data, read2_data, read3_data, dbg_data: vword;
   signal write0_data, write1_data: vword;
   signal write0_en, write1_en:     std_logic;
   signal read_as0, read_as1:       std_logic;

   signal fwds:                     fwds_t;

   signal d_mem_in0, d_mem_in1, d_mem_out0, d_mem_out1: word;
   signal d_mem_addr0, d_mem_addr1:   word;
   signal d_mem_rd0, d_mem_rd1, d_mem_wr0, d_mem_wr1, d_mem_inv0, d_mem_inv1, d_mem_ll0, d_mem_ll1, d_mem_sc0, d_mem_sc1: std_logic;
   signal d_mem_halt0, d_mem_halt1: std_logic;
   signal d_mem_valid0, d_mem_valid1: std_logic;
   signal d_mem_invalid0, d_mem_invalid1: std_logic;
   signal d_mem_scok0, d_mem_scok1: std_logic;
   signal d_mem_be0, d_mem_be1:     std_logic_vector(3 downto 0);
   signal d_mem_invop0, d_mem_invop1: std_logic_vector(4 downto 0);
   signal d_mem_kill0, d_mem_kill1: std_logic;
   signal d_mem_sync0, d_mem_sync1: std_logic;
   signal c_mem_in, c_mem_out:      word;
   signal c_mem_addr:               word;
   signal c_mem_rd, c_mem_wr:       std_logic;
   signal c_mem_ll:                 std_logic;
   signal c_mem_sc:                 std_logic;
   signal c_mem_inv:                std_logic;
   signal c_mem_invop:              std_logic_vector(4 downto 0);
   signal c_inv:                    std_logic;
   signal cc_inv:                   std_logic;
   signal cc_inv_addr:              word;
   signal cc_inv_op:                std_logic_vector(2 downto 0);
   signal cc_inv_done:              std_logic;
   signal c_paddrout:               word;
   signal c_paddroutv:              std_logic;
   signal c_inv_op:                 std_logic_vector(4 downto 0);
   signal c_inv_halt:               std_logic;
   signal c_mem_halt:               std_logic;
   signal c_mem_valid:              std_logic;
   signal c_mem_invalid:            std_logic;
   signal c_mem_scok:               std_logic;
   signal c_mem_be:                 std_logic_vector(3 downto 0);
   signal c_mem_kill:               std_logic;
   signal c_mem_sync:               std_logic;
   signal stats0, stats1:           stat_flags_t;
   signal dcache_bypass:            std_logic;

   signal step, break_hit:          std_logic;
   signal snoop:                    snoop_t;

   signal p0_mem, p1_mem:           std_logic;

   signal icache_addr:              word;
   signal icache_addrout:           word;
   signal icache_data:              dword;
   signal icache_stall:             std_logic;
   signal icache_valid:             std_logic;
   signal icache_invalid:           std_logic;
   signal icache_in_valid:          std_logic_vector(1 downto 0);
   signal fetch_stall:              std_logic;
   signal icache_kill:              std_logic;

   signal iqueue_full, iqueue_empty: std_logic;
   signal icache_pcs:               dword;
   signal iqueue_out:               dworda;
   signal iqueue_pcs_out:           dworda;
   signal iqueue_out_valid:         std_logic_vector(1 downto 0);
   signal iqueue_flush:             std_logic;
   signal iqueue_miss:              std_logic;
   signal iqueue_missaddr:          word;
   signal iqueue_miss_d:            std_logic;
   signal iqueue_missaddr_d:        word;
   signal iqueue_ok:                std_logic_vector(1 downto 0);
   signal iqueue_gate:              std_logic;

   signal group_issue:              std_logic_vector(1 downto 0);
   signal p0_preg2d, p1_preg2d:     preg_t;
   signal p0_preg2g, p1_preg2g:     preg_t;
   signal idec0_new_pc, idec1_new_pc: word;
   signal idec0_use_new_pc, idec1_use_new_pc: std_logic;
   signal dec_new_pc:               word;
   signal dec_use_new_pc:           std_logic;
   signal ra_in, ra_out:            word;
   signal ra_push, ra_pop:          std_logic;
   signal idec0_pop, idec1_pop:     std_logic;
   signal p0_call, p1_call:         std_logic;
   signal p0_ra, p1_ra:             word;
   signal curpc0, curpc1:           word;
   signal p0_p4valid, p1_p4valid:   std_logic;
   signal p0_r4valid, p1_r4valid:   std_logic;

   signal cop0_write:               std_logic;
   signal cop0_addr:                std_logic_vector(4 downto 0);
   signal cop0_datain:              word;
   signal cop0_dataout:             word;
   signal cop0_op:                  cop0op_t;
   signal cop0_stall:               std_logic;
   signal p0_ex, p1_ex:             exception_t;
   signal cop0_new_pc:              word;
   signal cop0_use_new_pc:          std_logic;
   signal blinkenlights_raw:        std_logic_vector(7 downto 0);
   signal blinkenlights2_raw:        std_logic_vector(7 downto 0);
   signal asid:                     std_logic_vector(7 downto 0);
   signal mode:                     mode_t;
   signal itlb_vaddr, dtlb_vaddr:   word;
   signal itlb_probe, dtlb_probe:   std_logic;
   signal itlb_ack, dtlb_ack:       std_logic;
   signal itlb_nack, dtlb_nack:     std_logic;
   signal itlb_ent, dtlb_ent:       utlb_raw_t;
   signal itlb_inv_addr:            std_logic_vector(ITLB_OFFSET_BITS - 1 downto 0);
   signal dtlb_inv_addr:            std_logic_vector(DTLB_OFFSET_BITS - 1 downto 0);
   signal itlb_inv, dtlb_inv:       std_logic;
   signal itlb_miss, itlb_invalid, itlb_permerr:  std_logic;
   signal dtlb_miss, dtlb_invalid, dtlb_modified, dtlb_permerr:  std_logic;
   signal dtlb_miss0, dtlb_invalid0, dtlb_modified0, dtlb_permerr0:  std_logic;
   signal dtlb_miss1, dtlb_invalid1, dtlb_modified1, dtlb_permerr1:  std_logic;
   signal dtlb_stall:               std_logic;
   signal cu0:                      std_logic;
   signal irq:                      std_logic;
   signal icache_flags, iqueue_flags_out: icache_flags_t;
   signal i_unaligned:              std_logic;
   signal triggers:                 std_logic_vector(17 downto 0);
   signal first_cycle:              std_logic;
   signal deadlock:                 std_logic;
   signal deadlock_count:           integer range 0 to DEBUG_DEADLOCK_CYCLES;
   signal dbp_pred:                 std_logic;

   signal i_perf_req:               std_logic;
   signal i_perf_stall:             std_logic;
   signal i_perf_hit:               std_logic;
   signal i_perf_miss_stall:        std_logic;
   signal i_perf_tlb_stall:         std_logic;
   signal i_perf_tlb_hit:           std_logic;
   signal i_perf_tlb_miss:          std_logic;

   signal d_perf_req:               std_logic;
   signal d_perf_stall:             std_logic;
   signal d_perf_hit:               std_logic;
   signal d_perf_miss_stall:        std_logic;
   signal d_perf_promote_miss_stall:std_logic;
   signal d_perf_tlb_stall:         std_logic;
   signal d_perf_tlb_hit:           std_logic;
   signal d_perf_tlb_miss:          std_logic;
   signal d_perf_sc_success:        std_logic;
   signal d_perf_sc_failure:        std_logic;
   signal d_perf_sc_flushed:        std_logic;
   signal d_perf_turnaround_stall:  std_logic;
   signal d_perf_inv_tlb_fault:     std_logic;

   signal cc_perf_miss:             std_logic;
   signal cc_perf_fill_miss:        std_logic;
   signal cc_perf_promote_miss:     std_logic;
   signal cc_perf_dirty:            std_logic;
   signal cc_perf_fill_excl:        std_logic;
   signal cc_perf_wb:               std_logic;
   signal cc_perf_l2_hit:           std_logic;
   signal cc_perf_l2_miss:          std_logic;
   signal cc_perf_lsnoop_arbit:     std_logic;
   signal cc_perf_lsnoop_wait:      std_logic;
   signal cc_perf_rsnoop:           std_logic;
   signal cc_perf_rsnoop_S:         std_logic;
   signal cc_perf_rsnoop_E:         std_logic;
   signal cc_perf_reenter:          std_logic;
   signal cc_perf_unlock:           std_logic;
   signal cc_perf_l2_alias:         std_logic;
   signal cc_perf_l2_nonalias:      std_logic;

   signal g_perf_raw, g_perf_cascade: std_logic;

   signal btb_update, btb_valid:    std_logic;
   signal btb_target, btb_new_target: word;
   signal btb_pc:                   word;
   signal p0p, p1p:                 preg_t;
   signal p0r, p1r:                 res_t;

   signal muldiv_op:                aluop_t;
   signal muldiv_i0, muldiv_i1:     word;
   signal muldiv_u:                 std_logic;
   signal muldiv_lo, muldiv_hi:     word;
   signal muldiv_stall:             std_logic;
   signal muldiv_op_valid:          std_logic;
   signal muldiv_fault:             std_logic;

   signal p0_muldiv_op:             aluop_t;
   signal p0_muldiv_i0, p0_muldiv_i1: word;
   signal p0_muldiv_u:              std_logic;
   signal p0_muldiv_op_valid:       std_logic;
   signal p1_muldiv_op:             aluop_t;
   signal p1_muldiv_i0, p1_muldiv_i1: word;
   signal p1_muldiv_u:              std_logic;
   signal p1_muldiv_op_valid:       std_logic;

   signal special_trig:             std_logic;
   signal special_trig2:            std_logic;

   signal cop0_mce:                 std_logic;
   signal pipe_stall:               std_logic;

   signal p0_mcheck_p, p1_mcheck_p: preg_t;
   signal p0_mcheck_r, p1_mcheck_r: res_t;
   signal cop0_bev, cop0_refill:    std_logic;
   signal cop0_eret:                std_logic;
   signal cop0_epc:                 word;
   signal cop0_badvaddr:            word;
   signal mce:                      std_logic;
   signal i_mce, d_mce:             std_logic;

   signal LLbit:                    std_logic;
   signal p0_LLset, p0_LLclr:       std_logic;
   signal p1_LLset, p1_LLclr:       std_logic;

   constant ICACHE_WAY_BITS:        natural := log2c(ICACHE_WAYS);
   constant DCACHE_WAY_BITS:        natural := log2c(DCACHE_WAYS);
   constant CACHE_WAYS:             natural := DCACHE_WAYS + ICACHE_WAYS;
   constant CACHE_WAY_BITS:         natural := log2c(CACHE_WAYS);

   signal i_miss_addr:              word;
   signal i_miss_valid:             std_logic;
   signal i_miss_minstate:          cache_state_t;
   signal i_miss_curstate:          cache_state_t;
   signal i_miss_way:               std_logic_vector(ICACHE_WAY_BITS - 1 downto 0);
   signal i_tag_addr:               word;
   signal i_tag_as:                 std_logic;
   signal i_tag_match:              std_logic_vector(ICACHE_WAYS - 1 downto 0);
   signal i_tag_dirty:              std_logic_vector(ICACHE_WAYS - 1 downto 0);
   signal i_tag_oe:                 std_logic_vector(ICACHE_WAYS - 1 downto 0);
   signal i_tag_we:                 std_logic_vector(ICACHE_WAYS - 1 downto 0);
   signal i_data_addr:              word;
   signal i_data_as:                std_logic;
   signal i_data_data:              std_logic_vector(CACHE_WIDTH - 1 downto 0);
   signal i_data_oe:                std_logic_vector(ICACHE_WAYS - 1 downto 0);
   signal i_data_we:                std_logic_vector(ICACHE_WAYS - 1 downto 0);
   signal i_stag_addr:              word;
   signal i_stag_as:                std_logic;
   signal i_stag_match:             std_logic_vector(ICACHE_WAYS - 1 downto 0);
   signal i_stag_excl:              std_logic_vector(ICACHE_WAYS - 1 downto 0);

   signal d_miss_addr:              word;
   signal d_miss_valid:             std_logic;
   signal d_miss_minstate:          cache_state_t;
   signal d_miss_curstate:          cache_state_t;
   signal d_miss_way:               std_logic_vector(DCACHE_WAY_BITS - 1 downto 0);
   signal d_tag_addr:               word;
   signal d_tag_as:                 std_logic;
   signal d_tag_match:              std_logic_vector(DCACHE_WAYS - 1 downto 0);
   signal d_tag_dirty:              std_logic_vector(DCACHE_WAYS - 1 downto 0);
   signal d_tag_oe:                 std_logic_vector(DCACHE_WAYS - 1 downto 0);
   signal d_tag_we:                 std_logic_vector(DCACHE_WAYS - 1 downto 0);
   signal d_data_addr:              word;
   signal d_data_as:                std_logic;
   signal d_data_data:              std_logic_vector(CACHE_WIDTH - 1 downto 0);
   signal d_data_oe:                std_logic_vector(DCACHE_WAYS - 1 downto 0);
   signal d_data_we:                std_logic_vector(DCACHE_WAYS - 1 downto 0);
   signal d_stag_addr:              word;
   signal d_stag_as:                std_logic;
   signal d_stag_match:             std_logic_vector(DCACHE_WAYS - 1 downto 0);
   signal d_stag_excl:              std_logic_vector(DCACHE_WAYS - 1 downto 0);

   signal l1_miss_addr:             word;
   signal l1_miss_valid:            std_logic;
   signal l1_miss_minstate:         cache_state_t;
   signal l1_miss_curstate:         cache_state_t;
   signal l1_miss_way:              std_logic_vector(CACHE_WAY_BITS - 1 downto 0);
   signal l1_hint_share:            std_logic;

   signal l1_tag_addr:              word;
   signal l1_way_mask:              std_logic_vector(CACHE_WAYS - 1 downto 0);
   signal l1_tag_as:                std_logic;
   signal l1_data_addr:             word;
   signal l1_data_as:               std_logic;
   signal l1_stag_addr:             word;
   signal l1_stag_as:               std_logic;

   signal l1_u_data:                std_logic_vector(CACHE_WIDTH - 1 downto 0);
   signal l1_u_data_we:             std_logic_vector(CACHE_WAYS - 1 downto 0);
   signal l1_u_tag:                 std_logic_vector(CACHE_STATE_BITS + 32 - 1 downto 0);
   signal l1_u_tag_we:              std_logic_vector(CACHE_WAYS - 1 downto 0);
   signal l1_u_sdata:               word;
   signal l1_u_stag:                std_logic_vector(CACHE_STATE_BITS + 32 - 1 downto 0);

   signal l1_d_data:                std_logic_vector(CACHE_WIDTH - 1 downto 0);
   signal l1_d_tag:                 std_logic_vector(CACHE_STATE_BITS + 32 - 1 downto 0);
   signal l1_d_tag_match:           std_logic_vector(CACHE_WAYS - 1 downto 0);
   signal l1_d_tag_dirty:           std_logic_vector(CACHE_WAYS - 1 downto 0);
   signal l1_d_sdata:               word;
   signal l1_d_stag_match:          std_logic_vector(CACHE_WAYS - 1 downto 0);
   signal l1_d_stag_excl:           std_logic_vector(CACHE_WAYS - 1 downto 0);
   
   signal l2_mce:                   std_logic;
   signal cc_init_wait:             std_logic;
   signal cc_synched:               std_logic;

   signal cc_mshr_addr:             word;
   signal cc_mshr_valid:            std_logic;
   signal cc_mshr_insstate:         cache_state_t;

   signal cc_mce_code:              std_logic_vector(5 downto 0);
begin
   assert(STAGES <= MAX_STAGES) report "STAGES above MAX_STAGES?" severity error;
   l1i: entity work.l1 generic map(
      CLOCK_DOUBLING => CACHE_CLOCK_DOUBLING,
      CPU_WIDTH => 64,
      CPU_BLOCK_BITS => ICACHE_BLOCK_BITS,
      REFILL_WIDTH => CACHE_WIDTH,
      REFILL_BLOCK_BITS => CACHE_BLOCK_BITS,
      OFFSET_BITS => ICACHE_OFFSET_BITS,
      WAYS => ICACHE_WAYS,
      TLB_OFFSET_BITS => ITLB_OFFSET_BITS,
      TLB_WAYS => ITLB_WAYS,
      TLB_REPLACE_TYPE => ITLB_REPLACE_TYPE,
      TLB_SUB_REPLACE_TYPE => ITLB_SUB_REPLACE_TYPE,
      TLB_HYBRID_BLOCK_FACTOR => ITLB_HYBRID_BLOCK_FACTOR,
      REPLACE_TYPE => ICACHE_REPLACE_TYPE,
      SUB_REPLACE_TYPE => ICACHE_SUB_REPLACE_TYPE,
      HYBRID_BLOCK_FACTOR => ICACHE_HYBRID_BLOCK_FACTOR,
      LATENCY => 1,
      ENABLE_STAGS => L2_ENABLE_SNOOPING,
      READ_ONLY => true,
      EARLY_RESTART => ICACHE_EARLY_RESTART,
      DEBUG_SDATA => DEBUG_SDATA
   )
   port map(
      clock => clock,
      dclock => dclock,
      rst => intreset,

      c_asid => asid,
      c_mode => mode,
      c_addr => icache_addr,
      c_in => (others => '-'),
      c_out => icache_data,
      c_addrout => icache_addrout,
      c_rd => not intreset and (not iqueue_full or iqueue_miss),
      c_wr => '0',
      c_ll => '0',
      c_inv => '0',
      c_kill => icache_kill,
      c_halt => icache_stall,
      c_valid => icache_valid,
      c_invalid => icache_invalid,
      c_be => (others => '1'),
      c_sync => '0',

      tlb_miss => itlb_miss,
      tlb_invalid => itlb_invalid,
      tlb_permerr => itlb_permerr,

      tlb_vaddr => itlb_vaddr,
      tlb_probe => itlb_probe,
      tlb_ack => itlb_ack,
      tlb_nack => itlb_nack,
      tlb_ent => itlb_ent,
      tlb_inv_addr => itlb_inv_addr,
      tlb_inv => itlb_inv,

      u_addr => iu_mem_addr,
      u_rd => iu_mem_rd,
      u_halt => iu_mem_halt,
      u_valid => iu_mem_valid,
      u_in => iu_mem_in,

      miss_addr => i_miss_addr,
      miss_valid => i_miss_valid,
      miss_minstate => i_miss_minstate,
      miss_curstate => i_miss_curstate,
      miss_way => i_miss_way,

      cc_init_wait => cc_init_wait,
      cc_synched => cc_synched,

      cc_mshr_addr => cc_mshr_addr,
      cc_mshr_valid => cc_mshr_valid,
      cc_mshr_insstate => cc_mshr_insstate,

      tag_addr => i_tag_addr,
      tag_as => i_tag_as,
      tag_data => l1_u_tag,
      tag_q => l1_d_tag,
      tag_match => i_tag_match,
      tag_dirty => i_tag_dirty,
      tag_oe => i_tag_oe,
      tag_we => i_tag_we,
      data_addr => i_data_addr,
      data_as => i_data_as,
      data_data => i_data_data,
      data_q => l1_d_data,
      data_oe => i_data_oe,
      data_we => i_data_we,
      sdata_data => l1_u_sdata,
      sdata_q => l1_d_sdata,
      stag_addr => i_stag_addr,
      stag_as => i_stag_as,
      stag_data => l1_u_stag,
      stag_match => i_stag_match,
      stag_excl => i_stag_excl,

      perf_req => i_perf_req,
      perf_stall => i_perf_stall,
      perf_hit => i_perf_hit,
      perf_miss_stall => i_perf_miss_stall,
      perf_tlb_stall => i_perf_tlb_stall,
      perf_tlb_hit => i_perf_tlb_hit,
      perf_tlb_miss => i_perf_tlb_miss,

      mce => i_mce
   );

   fetchpredict: entity work.fetchpredict generic map(
      BRANCH_PREDICTOR => FETCH_BRANCH_PREDICTOR,
      STATIC_PREDICTOR => FETCH_STATIC_PREDICTOR,
      DYNAMIC_PREDICTOR => FETCH_DYNAMIC_PREDICTOR,
      BTB => FETCH_HAVE_BTB,
      BRANCH_NOHINT => FETCH_BRANCH_NOHINT,
      UNALIGNED_DELAY_SLOT => FETCH_UNALIGNED_DELAY_SLOT,
      RETURN_ADDR_PREDICTOR => FETCH_RETURN_ADDR_PREDICTOR
   )
   port map(
      clk => clock,
      rst => intreset,
      pc => icache_addrout,
      cache_in => (
         0 => icache_data(31 downto 0),
         1 => icache_data(63 downto 32)
      ),
      cache_kill => icache_kill,
      v => icache_in_valid,
      nextaddr => next_ppc,
      delay_slot => fetch_delay_slot,
      ras_top => ra_out,
      btb_target => fetch_btb_target,
      btb_valid => fetch_btb_valid,
      dbp_in => fetch_dbp_pred
   );

   next_pc <=  iqueue_missaddr when (not FETCH_MISS_DELAYED) and iqueue_miss = '1' else
               iqueue_missaddr_d when FETCH_MISS_DELAYED and iqueue_miss_d = '1' else
               pc when iqueue_full = '1' else
               next_ppc;   -- next_ppc may be garbage but we rely on iqueue
                           -- mis-speculation recovery to clean up for us
   icache_addr <= next_pc;
   icache_kill <= '0' when not FETCH_ABORT_MISS else
                  iqueue_miss when not FETCH_MISS_DELAYED else
                  iqueue_miss_d;
   icache_pcs <=
      icache_addrout(31 downto 3) & '1' & icache_addrout(1 downto 0) &
      icache_addrout(31 downto 3) & '0' & icache_addrout(1 downto 0);
   i_unaligned <= '1' when icache_addrout(1 downto 0) /= "00" else '0';
   fetch_stall <= icache_stall or iqueue_full;
   icache_in_valid <= (
      0 => (icache_valid or icache_invalid) and not icache_addrout(2),
      1 => (icache_valid or icache_invalid) and not (fetch_delay_slot and not icache_addrout(2))
   );
   icache_flags(1 downto 0) <= (others => (
      itlb_miss => itlb_miss,
      itlb_invalid => itlb_invalid,
      itlb_permerr => itlb_permerr,
      i_unaligned => i_unaligned
   ));

   blinkenlights_raw <= not icache_valid & iqueue_full & iqueue_empty & (p0_stall(3 to 6) or p1_stall(3 to 6)) & '0';
   blinkenlights2_raw <= (7 downto 2 => '0') & fwds(1)(STAGES).enable & fwds(0)(STAGES).enable;

   -- decode stage
   iqueue: entity work.z48iqueue generic map(
      QUEUE_LENGTH => IQUEUE_LENGTH,
      GATE_CYCLES => IQUEUE_GATE_CYCLES
   )
   port map(
      clock => clock,
      reset => intreset,

      icache_in => icache_data,
      icache_pcs => icache_pcs,
      icache_flags => icache_flags,
      icache_in_valid => icache_in_valid,
      full => iqueue_full,
      empty => iqueue_empty,

      iqueue_out => iqueue_out,
      iqueue_pcs_out => iqueue_pcs_out,
      iqueue_flags_out => iqueue_flags_out,
      iqueue_out_valid => iqueue_out_valid,
      issue => group_issue,
      stall => pipe_stall,
      flush => iqueue_flush,

      gate_stall => pipe_stall,
      gate => triggermask(17) or iqueue_gate
   );

   pipe_stall <= p0_stall(2) or p1_stall(2);

   -- explicitly instantiate a register with a clock-enable; improves
   -- synthesis/timing results
   expc_reg: entity work.reg port map(
      clock => clock,
      cke => expc_cke,
      d => nexpc,
      q => expc
   );

   expc_cke <=
      intreset or
      cop0_use_new_pc or
      p0_use_new_pc or
      --p1_use_new_pc or -- p1 never branches
      (not pipe_stall and group_issue(0));

   nexpc <= x"9fc00000" when intreset = '1' and CACHEABLE_BOOT_VECTORS else
            x"bfc00000" when intreset = '1' else
            cop0_new_pc when cop0_use_new_pc = '1' else
            p0_new_pc when p0_use_new_pc = '1' else
            --p1_new_pc when p1_use_new_pc = '1' else -- p1 never branches
            dec_new_pc when dec_use_new_pc = '1' else
            expc0 + 8 when group_issue = "11" else
            expc1 when group_issue = "01" else
            x"0badbeef" when POISON_EXPC else
            (others => '-');

   expc0 <= expc;
   expc1 <= expc + 4;

   expc_match(0) <= '1' when expc0(31 downto 2) = iqueue_pcs_out(0)(31 downto 2) else '0';
   expc_match(1) <= '1' when expc1(31 downto 2) = iqueue_pcs_out(1)(31 downto 2) else '0';

   -- cop0 target asserts 1cyc after exception taken, resulting in double-flush
   flush_pipe <= p0_flush_queue or p1_flush_queue or cop0_use_new_pc;
   
   iqueue_ok(0) <=
      '0' when iqueue_out_valid(0) = '0' else
      '0' when first_cycle = '1' else
      '0' when expc_match(0) = '0' else
      '1';
   iqueue_ok(1) <=
      '0' when iqueue_out_valid(1) = '0' else
      '0' when first_cycle = '1' else
      '0' when expc_match(1) = '0' else
      '0' when iqueue_ok(0) = '0' else -- must issue instrs in-order
      '1';

   iqueue_miss <= (iqueue_out_valid(0) and not expc_match(0)) or
                  (iqueue_out_valid(1) and not expc_match(1)) or
                  flush_pipe or
                  first_cycle;
   iqueue_missaddr <=
      cop0_new_pc when cop0_use_new_pc = '1' else
      p0_new_pc when p0_use_new_pc = '1' else
      --p1_new_pc when p1_use_new_pc = '1' else -- p1 never branches
      expc;
   iqueue_flush <= iqueue_miss or flush_pipe;

   pred_pc <=  p0_pred_pc when p0_t = '1' or p0_nt = '1' else
               --p1_pred_pc when p1_t = '1' or p1_nt = '1' else
               (others => '-');
   dbp: if(BRANCH_PREDICTOR and DYNAMIC_BRANCH_PREDICTOR) generate
      bht: entity work.bht generic map(
         BITS => DYNAMIC_BRANCH_BITS,
         TABLE_SIZE => DYNAMIC_BRANCH_SIZE,
         INIT_STATE => DYNAMIC_BRANCH_INIT_STATE
      )
      port map(
         clk => clock,
         rst => intreset,

         a_nexpc => nexpc,
         a_prediction => dbp_pred,
         b_nexpc => next_pc,
         b_prediction => fetch_dbp_pred,

         t => p0_t or p1_t,
         nt => p0_nt or p1_nt,
         pred_pc => pred_pc
      );
   end generate;
   gen_btb: if(BRANCH_PREDICTOR and HAVE_BTB) generate
      btb: entity work.btb generic map(
         TABLE_SIZE => BTB_SIZE,
         TAGGED => BTB_TAGGED,
         VALID_BIT => BTB_VALID_BIT
      )
      port map(
         clk => clock,
         rst => intreset,

         update => btb_update,
         update_pc => btb_pc,
         update_target => btb_new_target,

         a_next_pc => nexpc,
         a_target => btb_target,
         a_valid => btb_valid,
         b_next_pc => next_pc,
         b_target => fetch_btb_target,
         b_valid => fetch_btb_valid
      );
   end generate;

   mips_idec0: entity work.mipsidec generic map(
      BRANCH_PREDICTOR => BRANCH_PREDICTOR,
      STATIC_PREDICTOR => STATIC_BRANCH_PREDICTOR,
      DYNAMIC_PREDICTOR => DYNAMIC_BRANCH_PREDICTOR,
      BRANCH_NOHINT => BRANCH_NOHINT,
      RETURN_ADDR_PREDICTOR => HAVE_RASTACK,
      CLEVER_FLUSH => CLEVER_FLUSH,
      BTB => HAVE_BTB
   )
   port map(
      ireg => iqueue_out(0),
      pc => iqueue_pcs_out(0),
      irq => irq,
      flags => iqueue_flags_out(0),
      inst => p0_preg2d.i,
      new_pc => idec0_new_pc,
      use_new_pc => idec0_use_new_pc,
      rastack_top => ra_out,
      rastack_pop => idec0_pop,
      btb_target => btb_target,
      btb_valid => btb_valid,
      dbp_in => dbp_pred
   );
   mips_idec1: entity work.mipsidec generic map(
      BRANCH_PREDICTOR => BRANCH_PREDICTOR,
      STATIC_PREDICTOR => STATIC_BRANCH_PREDICTOR,
      DYNAMIC_PREDICTOR => DYNAMIC_BRANCH_PREDICTOR,
      BRANCH_NOHINT => BRANCH_NOHINT,
      RETURN_ADDR_PREDICTOR => HAVE_RASTACK,
      CLEVER_FLUSH => CLEVER_FLUSH,
      BTB => HAVE_BTB
   )
   port map(
      ireg => iqueue_out(1),
      pc => iqueue_pcs_out(1),
      irq => '0',
      flags => iqueue_flags_out(1),
      inst => p1_preg2d.i,
      new_pc => idec1_new_pc,
      use_new_pc => idec1_use_new_pc,
      rastack_top => ra_out,
      rastack_pop => idec1_pop,
      dbp_in => dbp_pred
   );
   p0_preg2d.pc <= iqueue_pcs_out(0);
   p0_preg2d.pred <= idec0_use_new_pc;
   p0_preg2d.new_pc <= idec0_new_pc;
   p1_preg2d.pc <= iqueue_pcs_out(1);
   p1_preg2d.pred <= idec1_use_new_pc;
   p1_preg2d.new_pc <= idec1_new_pc;

   dec_new_pc <=
      idec0_new_pc when idec0_use_new_pc = '1' and group_issue(0) = '1' else
      idec1_new_pc when idec1_use_new_pc = '1' and group_issue(1) = '1' else
      (others => '-');
   dec_use_new_pc <=
      '1' when idec0_use_new_pc = '1' and group_issue(0) = '1' else
      '1' when idec1_use_new_pc = '1' and group_issue(1) = '1' else
      '0';

   ras: if(BRANCH_PREDICTOR and HAVE_RASTACK) generate
      rastack: entity work.z48rastack generic map(
         ENTRIES => RASTACK_ENTRIES
      )
      port map(
         clock => clock,
         reset => intreset,
         cke => not pipe_stall,

         ra_in => ra_in,
         push => ra_push,
         ra_out => ra_out,
         pop => ra_pop
      );
   end generate;

   p0_call <= '1' when (p0_preg2g.i.op = i_br or p0_preg2g.i.op = i_jr) and p0_preg2d.i.writes_reg = '1' and p0_preg2g.i.valid = '1' else '0';
   p1_call <= '0'; -- p1 never branches
   p0_ra <= iqueue_pcs_out(0) + 8;
   p1_ra <= iqueue_pcs_out(1) + 8;
   ra_push <= (p0_call or p1_call) and not pipe_stall;
   ra_in <= p1_ra when p1_call = '1' else p0_ra;
   ra_pop <=   (idec0_pop and group_issue(0)) or
               (idec1_pop and group_issue(1));

   grouper: entity work.z48group generic map(
      ALLOW_CASCADE => ALLOW_CASCADE,
      AVOID_ISSUE_AFTER_TRAP => AVOID_ISSUE_AFTER_TRAP,
      AVOID_DUAL_ISSUE => AVOID_DUAL_ISSUE
   )
   port map(
      i0 => p0_preg2d,
      i1 => p1_preg2d,
      o0 => p0_preg2g,
      o1 => p1_preg2g,
      valid => iqueue_ok,
      issue => group_issue,
      stats_raw => g_perf_raw,
      stats_cascade => g_perf_cascade
   );

   dbg_snoop: if(DEBUG_ON) generate
      snoop.pc <= icache_addrout;
      snoop.next_pc <= icache_addr;
      snoop.curpc0 <= curpc0;
      snoop.curpc1 <= curpc1;
      snoop.p4valid0 <= p0_p4valid;
      snoop.p4valid1 <= p1_p4valid;
      snoop.r4valid0 <= p0_r4valid;
      snoop.r4valid1 <= p1_r4valid;
   end generate;

   write0_ad <= fwds(0)(STAGES - 2).dreg;
   write0_en <= 
      '0' when fwds(0)(STAGES - 2).dreg = fwds(1)(STAGES - 2).dreg and
               fwds(1)(STAGES - 2).enable = '1' else
      fwds(0)(STAGES - 2).enable;
   write0_data <= fwds(0)(STAGES - 2).data;
   write1_ad <= fwds(1)(STAGES - 2).dreg;
   write1_en <= fwds(1)(STAGES - 2).enable;
   write1_data <= fwds(1)(STAGES - 2).data;

   p0: entity work.z48pipe generic map(
      STAGES => STAGES,
      PIPE_ID => 0,
      SIBLING_PIPE_ID => 1,
      DCACHE_LATENCY => DCACHE_LATENCY,
      SHIFT_TYPE => SHIFT_TYPE,
      ALLOW_CASCADE => ALLOW_CASCADE,
      FORWARD_DCACHE_EARLY => FORWARD_DCACHE_EARLY,
      FAST_MISPREDICT => FAST_MISPREDICT,
      FAST_PREDICTOR_FEEDBACK => FAST_PREDICTOR_FEEDBACK,
      HAVE_RETURN_ADDR_PREDICTOR => HAVE_RASTACK,
      FAST_REG_WRITE => FAST_REG_WRITE,
      NO_BRANCH => false
   )
   port map(
      reset => intreset,
      clock => clock,

      d_mem_in => d_mem_in0,
      d_mem_out => d_mem_out0,
      d_mem_addr => d_mem_addr0,
      d_mem_rd => d_mem_rd0,
      d_mem_wr => d_mem_wr0,
      d_mem_ll => d_mem_ll0,
      d_mem_sc => d_mem_sc0,
      d_mem_inv => d_mem_inv0,
      d_mem_invop => d_mem_invop0,
      d_mem_halt => d_mem_halt0,
      d_mem_valid => d_mem_valid0,
      d_mem_invalid => d_mem_invalid0,
      d_mem_scok => d_mem_scok0,
      d_mem_be => d_mem_be0,
      d_mem_kill => d_mem_kill0,
      d_mem_sync => d_mem_sync0,

      dtlb_miss => dtlb_miss0,
      dtlb_invalid => dtlb_invalid0,
      dtlb_modified => dtlb_modified0,
      dtlb_permerr => dtlb_permerr0,
      dtlb_stall => dtlb_stall,

      preg => p0_preg2g,

      new_pc => p0_new_pc,
      use_new_pc => p0_use_new_pc,
      flush_in => p1_flush,
      flush_out => p0_flush,
      flush_queue => p0_flush_queue,

      read0_ad => read0_ad,
      read1_ad => read1_ad,
      read0_data => read0_data,
      read1_data => read1_data,
      read_as => read_as0,

      stallin => p1_stall,
      stallout => p0_stall,

      fwdout => fwds(0),
      fwds => fwds,

      trace_p => p0p,
      trace_r => p0r,

      stats_out => stats0,

      curpc => curpc0,
      step => step,
      p4valid => p0_p4valid,
      r4valid => p0_r4valid,
      btb_update => btb_update,
      btb_pc => btb_pc,
      btb_new_target => btb_new_target,

      c0_write => cop0_write,
      c0_addr => cop0_addr,
      c0_datain => cop0_datain,
      c0_dataout => cop0_dataout,
      c0_op => cop0_op,
      c0_stall => cop0_stall,

      muldiv_op => p0_muldiv_op,
      muldiv_i0 => p0_muldiv_i0,
      muldiv_i1 => p0_muldiv_i1,
      muldiv_u => p0_muldiv_u,
      muldiv_op_valid => p0_muldiv_op_valid,
      muldiv_stall => muldiv_stall,
      muldiv_lo => muldiv_lo,
      muldiv_hi => muldiv_hi,

      cu0 => cu0,

      ex => p0_ex,

      LLbit => LLbit,
      LLset => p0_LLset,
      LLclr => p0_LLclr,

      mce_p => p0_mcheck_p,
      mce_r => p0_mcheck_r,

      t => p0_t,
      nt => p0_nt,
      pred_pc => p0_pred_pc
   );

   p1: entity work.z48pipe generic map(
      STAGES => STAGES,
      PIPE_ID => 1,
      SIBLING_PIPE_ID => 0,
      DCACHE_LATENCY => DCACHE_LATENCY,
      SHIFT_TYPE => SHIFT_TYPE,
      ALLOW_CASCADE => ALLOW_CASCADE,
      FORWARD_DCACHE_EARLY => FORWARD_DCACHE_EARLY,
      FAST_MISPREDICT => FAST_MISPREDICT,
      FAST_PREDICTOR_FEEDBACK => FAST_PREDICTOR_FEEDBACK,
      HAVE_RETURN_ADDR_PREDICTOR => HAVE_RASTACK,
      FAST_REG_WRITE => FAST_REG_WRITE,
      NO_BRANCH => true
   )
   port map(
      reset => intreset,
      clock => clock,

      d_mem_in => d_mem_in1,
      d_mem_out => d_mem_out1,
      d_mem_addr => d_mem_addr1,
      d_mem_rd => d_mem_rd1,
      d_mem_wr => d_mem_wr1,
      d_mem_ll => d_mem_ll1,
      d_mem_sc => d_mem_sc1,
      d_mem_inv => d_mem_inv1,
      d_mem_invop => d_mem_invop1,
      d_mem_halt => d_mem_halt1,
      d_mem_valid => d_mem_valid1,
      d_mem_invalid => d_mem_invalid1,
      d_mem_scok => d_mem_scok1,
      d_mem_be => d_mem_be1,
      d_mem_kill => d_mem_kill1,
      d_mem_sync => d_mem_sync1,

      dtlb_miss => dtlb_miss1,
      dtlb_invalid => dtlb_invalid1,
      dtlb_modified => dtlb_modified1,
      dtlb_permerr => dtlb_permerr1,
      dtlb_stall => dtlb_stall,

      preg => p1_preg2g,

      new_pc => p1_new_pc,
      use_new_pc => p1_use_new_pc,
      flush_in => p0_flush,
      flush_out => p1_flush,
      flush_queue => p1_flush_queue,

      read0_ad => read2_ad,
      read1_ad => read3_ad,
      read0_data => read2_data,
      read1_data => read3_data,
      read_as => read_as1,

      stallin => p0_stall,
      stallout => p1_stall,

      fwdout => fwds(1),
      fwds => fwds,

      trace_p => p1p,
      trace_r => p1r,

      stats_out => stats1,

      curpc => curpc1,
      step => step,
      p4valid => p1_p4valid,
      r4valid => p1_r4valid,

      c0_stall => '0',

      muldiv_op => p1_muldiv_op,
      muldiv_i0 => p1_muldiv_i0,
      muldiv_i1 => p1_muldiv_i1,
      muldiv_u => p1_muldiv_u,
      muldiv_op_valid => p1_muldiv_op_valid,
      muldiv_stall => muldiv_stall,
      muldiv_lo => muldiv_lo,
      muldiv_hi => muldiv_hi,

      cu0 => cu0,

      ex => p1_ex,

      LLbit => LLbit,
      LLset => p1_LLset,
      LLclr => p1_LLclr,

      mce_p => p1_mcheck_p,
      mce_r => p1_mcheck_r,

      t => p1_t,
      nt => p1_nt,
      pred_pc => p1_pred_pc
   );

   muldiv: entity work.muldiv generic map(
      HAVE_MULTIPLY => HAVE_MULTIPLY,
      MULTIPLY_TYPE => MULTIPLY_TYPE,
      COMB_MULTIPLY_CYCLES => COMB_MULTIPLY_CYCLES,
      HAVE_DIVIDE => HAVE_DIVIDE,
      DIVIDE_TYPE => DIVIDE_TYPE,
      COMB_DIVIDE_CYCLES => COMB_DIVIDE_CYCLES
   )
   port map(
      clock => clock,
      rst => intreset,
      op => muldiv_op,
      op_valid => muldiv_op_valid,
      i0 => muldiv_i0,
      i1 => muldiv_i1,
      u => muldiv_u,
      lo => muldiv_lo,
      hi => muldiv_hi,
      stall => muldiv_stall,
      fault => muldiv_fault
   );

   muldiv_op <=   p0_muldiv_op when p0_muldiv_op_valid = '1' else
                  p1_muldiv_op when p1_muldiv_op_valid = '1' else
                  a_nop;
   muldiv_i0 <=   p0_muldiv_i0 when p0_muldiv_op_valid = '1' else
                  p1_muldiv_i0 when p1_muldiv_op_valid = '1' else
                  (others => '-');
   muldiv_i1 <=   p0_muldiv_i1 when p0_muldiv_op_valid = '1' else
                  p1_muldiv_i1 when p1_muldiv_op_valid = '1' else
                  (others => '-');
   muldiv_u <=    p0_muldiv_u when p0_muldiv_op_valid = '1' else
                  p1_muldiv_u when p1_muldiv_op_valid = '1' else
                  '-';
   muldiv_op_valid <= p0_muldiv_op_valid or p1_muldiv_op_valid;

   regfile: entity work.xorregfile generic map(
      WRITE_PORTS => 2,
      READ_PORTS => 5
   )
   port map(
      clock => clock,
      reset => intreset,

      read_ad(0) => read0_ad,
      read_ad(1) => read1_ad,
      read_ad(2) => read2_ad,
      read_ad(3) => read3_ad,
      read_ad(4) => dbg_ad,
      read_data(0) => read0_data,
      read_data(1) => read1_data,
      read_data(2) => read2_data,
      read_data(3) => read3_data,
      read_data(4) => dbg_data,
      read_as => (4 => '0', 3 downto 2 => read_as1, 1 downto 0 => read_as0),

      write_ad(0) => write0_ad,
      write_ad(1) => write1_ad,
      write_data(0) => write0_data,
      write_data(1) => write1_data,
      write_en(0) => write0_en,
      write_en(1) => write1_en
   );

   --regfile: entity work.altregfile generic map(
   --   WRITE_PORTS => 2,
   --   READ_PORTS => 5,
   --   MIXED_BYPASS => true
   --)
   --port map(
   --   clock => clock,
   --   reset => intreset,

   --   read_ad(0) => read0_ad,
   --   read_ad(1) => read1_ad,
   --   read_ad(2) => read2_ad,
   --   read_ad(3) => read3_ad,
   --   read_ad(4) => dbg_ad,
   --   read_data(0) => read0_data,
   --   read_data(1) => read1_data,
   --   read_data(2) => read2_data,
   --   read_data(3) => read3_data,
   --   read_data(4) => dbg_data,
   --   read_as => (4 => '0', 3 downto 2 => read_as1, 1 downto 0 => read_as0),

   --   write_ad(0) => write0_ad,
   --   write_ad(1) => write1_ad,
   --   write_data(0) => write0_data,
   --   write_data(1) => write1_data,
   --   write_en(0) => write0_en,
   --   write_en(1) => write1_en
   --);

   dbg: if(DEBUG_ON) generate
      debugger: entity work.z48debug generic map(
         AUTOBOOT => DEBUG_AUTOBOOT
      )
      port map(
         reset => reset,
         clock => clock,

         mem_addr => debug_mem_addr,
         mem_in => debug_mem_in,
         mem_out => debug_mem_out,
         mem_be => debug_mem_be,
         mem_rd => debug_mem_rd,
         mem_wr => debug_mem_wr,
         mem_halt => debug_mem_halt,

         step => step,
         break_hit => break_hit,
         any_mce => l2_mce or cop0_mce or i_mce or d_mce or mce,
         intreset => intreset,
         signaltap_trigger => signaltap_trigger,
         iqueue_gate => iqueue_gate,
         dcache_bypass => dcache_bypass,

         reg_snoop_ad => dbg_ad,
         reg_snoop_data => dbg_data(31 downto 0),

         snoopin => snoop,
         stats_in0 => stats0,
         stats_in1 => stats1
      );
   end generate;
   no_dbg: if(not DEBUG_ON) generate
      -- treat external reset signal as asynch for power-on reset
      por: process(clock, reset) is begin
         if(reset = '1') then
            intreset_synch(0) <= '1';
         elsif(rising_edge(clock)) then
            intreset_synch(0) <= '0';
         end if;
      end process;
      -- synchronize latched reset signal
      rst_synch: process(clock) is begin
         if(rising_edge(clock)) then
            intreset_synch(intreset_synch'high downto intreset_synch'low + 1) <= intreset_synch(intreset_synch'high - 1 downto intreset_synch'low);
         end if;
      end process;
      intreset <= intreset_synch(intreset_synch'high);
      step <= '1';
      break_hit <= '0';
      iqueue_gate <= '0';
      dcache_bypass <= '0';
      debug_mem_halt <= '0';
      debug_mem_out <= x"deadbabe";
   end generate;

   trace_gen: if(TRACE_ON) generate
      tracebuf: entity work.tracebuf generic map(
         TRACE_LENGTH => TRACE_LENGTH
      )
      port map(
         reset => intreset,
         clock => clock,

         mem_addr => trace_mem_addr,
         mem_in => trace_mem_in,
         mem_out => trace_mem_out,
         mem_be => trace_mem_be,
         mem_rd => trace_mem_rd,
         mem_wr => trace_mem_wr,
         mem_halt => trace_mem_halt,

         p0p => p0p,
         p1p => p1p,
         p0r => p0r,
         p1r => p1r,

         uto => triggermask(16)
      );
   end generate;
   no_trace: if(not TRACE_ON) generate
      trace_mem_halt <= '0';
      trace_mem_out <= x"deadbabe";
   end generate;

   -- data bus glue logic
   p0_mem <= d_mem_rd0 or d_mem_wr0 or d_mem_inv0 or d_mem_sync0;
   p1_mem <= d_mem_rd1 or d_mem_wr1 or d_mem_inv1 or d_mem_sync1;
   c_mem_addr <= (others => '-') when p0_mem = p1_mem else
               d_mem_addr0 when p0_mem = '1' else
               d_mem_addr1;
   c_mem_out <= (others => '-') when p0_mem = p1_mem else
               d_mem_out0 when p0_mem = '1' else
               d_mem_out1;
   c_mem_be <= (others => '-') when p0_mem = p1_mem else
               d_mem_be0 when p0_mem = '1' else
               d_mem_be1;
   c_mem_invop <= (others => '-') when p0_mem = p1_mem else
               d_mem_invop0 when p0_mem = '1' else
               d_mem_invop1;
   d_mem_in0 <= c_mem_in;
   d_mem_in1 <= c_mem_in;
   d_mem_halt0 <= c_mem_halt or (c_inv_halt and not c_mem_kill);
   d_mem_halt1 <= c_mem_halt or (c_inv_halt and not c_mem_kill);
   d_mem_valid0 <= c_mem_valid;
   d_mem_valid1 <= c_mem_valid;
   d_mem_invalid0 <= c_mem_invalid;
   d_mem_invalid1 <= c_mem_invalid;
   d_mem_scok0 <= c_mem_scok;
   d_mem_scok1 <= c_mem_scok;
   c_mem_rd <= d_mem_rd0 or d_mem_rd1;
   c_mem_wr <= d_mem_wr0 or d_mem_wr1;
   c_mem_ll <= d_mem_ll0 or d_mem_ll1;
   c_mem_sc <= d_mem_sc0 or d_mem_sc1;
   c_mem_inv <= d_mem_inv0 or d_mem_inv1;
   c_mem_sync <= d_mem_sync0 or d_mem_sync1;
   dtlb_miss0 <= dtlb_miss;
   dtlb_miss1 <= dtlb_miss;
   dtlb_invalid0 <= dtlb_invalid;
   dtlb_invalid1 <= dtlb_invalid;
   dtlb_modified0 <= dtlb_modified;
   dtlb_modified1 <= dtlb_modified;
   dtlb_permerr0 <= dtlb_permerr;
   dtlb_permerr1 <= dtlb_permerr;
   c_mem_kill <= d_mem_kill0 or d_mem_kill1;

   l1d: entity work.l1 generic map(
      CLOCK_DOUBLING => CACHE_CLOCK_DOUBLING,
      CPU_WIDTH => 32,
      CPU_BLOCK_BITS => DCACHE_BLOCK_BITS,
      REFILL_WIDTH => CACHE_WIDTH,
      REFILL_BLOCK_BITS => CACHE_BLOCK_BITS,
      OFFSET_BITS => DCACHE_OFFSET_BITS,
      WAYS => DCACHE_WAYS,
      TLB_OFFSET_BITS => DTLB_OFFSET_BITS,
      TLB_WAYS => DTLB_WAYS,
      TLB_REPLACE_TYPE => DTLB_REPLACE_TYPE,
      TLB_SUB_REPLACE_TYPE => DTLB_SUB_REPLACE_TYPE,
      TLB_HYBRID_BLOCK_FACTOR => DTLB_HYBRID_BLOCK_FACTOR,
      REPLACE_TYPE => DCACHE_REPLACE_TYPE,
      SUB_REPLACE_TYPE => DCACHE_SUB_REPLACE_TYPE,
      HYBRID_BLOCK_FACTOR => DCACHE_HYBRID_BLOCK_FACTOR,
      LATENCY => DCACHE_LATENCY,
      ENABLE_STAGS => L2_ENABLE_SNOOPING,
      EARLY_RESTART => DCACHE_EARLY_RESTART,
      DEBUG_SDATA => DEBUG_SDATA
   )
   port map(
      clock => clock,
      dclock => dclock,
      rst => intreset,

      c_asid => asid,
      c_mode => mode,
      c_addr => c_mem_addr,
      c_paddrout => c_paddrout,
      c_paddroutv => c_paddroutv,
      c_in => c_mem_out,
      c_out => c_mem_in,
      c_rd => c_mem_rd,
      c_wr => c_mem_wr,
      c_ll => c_mem_ll,
      c_sc => c_mem_sc,
      c_scok => c_mem_scok,
      c_inv => c_mem_inv,
      c_kill => c_mem_kill,
      c_halt => c_mem_halt,
      c_valid => c_mem_valid,
      c_invalid => c_mem_invalid,
      c_be => c_mem_be,
      c_sync => c_mem_sync,

      tlb_miss => dtlb_miss,
      tlb_invalid => dtlb_invalid,
      tlb_modified => dtlb_modified,
      tlb_permerr => dtlb_permerr,
      tlb_stall => dtlb_stall,

      tlb_vaddr => dtlb_vaddr,
      tlb_probe => dtlb_probe,
      tlb_ack => dtlb_ack,
      tlb_nack => dtlb_nack,
      tlb_ent => dtlb_ent,
      tlb_inv_addr => dtlb_inv_addr,
      tlb_inv => dtlb_inv,

      u_addr => u_mem_addr,
      u_in => u_mem_in,
      u_out => u_mem_out,
      u_rd => u_mem_rd,
      u_wr => u_mem_wr,
      u_halt => u_mem_halt,
      u_valid => u_mem_valid,
      u_be => u_mem_be,

      miss_addr => d_miss_addr,
      miss_valid => d_miss_valid,
      miss_minstate => d_miss_minstate,
      miss_curstate => d_miss_curstate,
      miss_way => d_miss_way,

      cc_init_wait => cc_init_wait,
      cc_synched => cc_synched,

      cc_mshr_addr => cc_mshr_addr,
      cc_mshr_valid => cc_mshr_valid,
      cc_mshr_insstate => cc_mshr_insstate,

      tag_addr => d_tag_addr,
      tag_as => d_tag_as,
      tag_data => l1_u_tag,
      tag_q => l1_d_tag,
      tag_match => d_tag_match,
      tag_dirty => d_tag_dirty,
      tag_oe => d_tag_oe,
      tag_we => d_tag_we,
      data_addr => d_data_addr,
      data_as => d_data_as,
      data_data => d_data_data,
      data_q => l1_d_data,
      data_oe => d_data_oe,
      data_we => d_data_we,
      sdata_data => l1_u_sdata,
      sdata_q => l1_d_sdata,
      stag_addr => d_stag_addr,
      stag_as => d_stag_as,
      stag_data => l1_u_stag,
      stag_match => d_stag_match,
      stag_excl => d_stag_excl,

      mce => d_mce,

      perf_req => d_perf_req,
      perf_stall => d_perf_stall,
      perf_hit => d_perf_hit,
      perf_miss_stall => d_perf_miss_stall,
      perf_promote_miss_stall => d_perf_promote_miss_stall,
      perf_tlb_stall => d_perf_tlb_stall,
      perf_tlb_hit => d_perf_tlb_hit,
      perf_tlb_miss => d_perf_tlb_miss,
      perf_sc_success => d_perf_sc_success,
      perf_sc_failure => d_perf_sc_failure,
      perf_sc_flushed => d_perf_sc_flushed,
      perf_turnaround_stall => d_perf_turnaround_stall,
      perf_inv_tlb_fault => d_perf_inv_tlb_fault,

      tlb_cacheable_mask => not (triggermask(15) or dcache_bypass)
   );

   cop0: entity work.cop0 generic map(
      JTLB_SIZE => JTLB_SIZE,
      JTLB_CAM_LATENCY => JTLB_CAM_LATENCY,
      JTLB_PRECISE_FLUSH => JTLB_PRECISE_FLUSH,
      CACHEABLE_BOOT_VECTORS => CACHEABLE_BOOT_VECTORS,
      DCACHE_BLOCK_BITS => DCACHE_BLOCK_BITS,
      DCACHE_OFFSET_BITS => DCACHE_OFFSET_BITS,
      DCACHE_WAYS => DCACHE_WAYS,
      DTLB_OFFSET_BITS => DTLB_OFFSET_BITS,
      ICACHE_BLOCK_BITS => ICACHE_BLOCK_BITS,
      ICACHE_OFFSET_BITS => ICACHE_OFFSET_BITS,
      ICACHE_WAYS => ICACHE_WAYS,
      ITLB_OFFSET_BITS => ITLB_OFFSET_BITS,
      NO_LARGE_PAGES => NO_LARGE_PAGES
   )
   port map(
      clock => clock,
      rst => intreset,
      step => step,

      eirqs => eirqs,

      mbox_irq => mbox_irq,

      cpu_write => cop0_write,
      cpu_addr => cop0_addr,
      cpu_datain => cop0_dataout,
      cpu_dataout => cop0_datain,
      cpu_cop0op => cop0_op,
      cpu_stall => cop0_stall,

      p0_ex => p0_ex,
      p1_ex => p1_ex,

      fetch_new_pc => cop0_new_pc,
      fetch_use_new_pc => cop0_use_new_pc,

      asid => asid,
      mode => mode,
      
      LLbit => LLbit,
      LLset => p0_LLset or p1_LLset,
      LLclr => p0_LLclr or p1_LLclr,

      itlb_vaddr => itlb_vaddr,
      itlb_probe => itlb_probe,
      itlb_ack => itlb_ack,
      itlb_nack => itlb_nack,
      itlb_ent => itlb_ent,
      itlb_inv_addr => itlb_inv_addr,
      itlb_inv => itlb_inv,

      dtlb_vaddr => dtlb_vaddr,
      dtlb_probe => dtlb_probe,
      dtlb_ack => dtlb_ack,
      dtlb_nack => dtlb_nack,
      dtlb_ent => dtlb_ent,
      dtlb_inv_addr => dtlb_inv_addr,
      dtlb_inv => dtlb_inv,

      cu0 => cu0,
      irq => irq,

      bev_out => cop0_bev,
      refill_out => cop0_refill,
      eret_out => cop0_eret,
      epc_out => cop0_epc,
      badvaddr_out => cop0_badvaddr,

      mce => cop0_mce
   );

   process(clock) is begin
      if(rising_edge(clock)) then
         if(DEBUG_DEADLOCK_DETECT) then
            deadlock <= '0';
            if(fetch_stall = '1' and step = '1' and break_hit = '0' and c_mem_halt = '0' and cop0_stall = '0' and muldiv_stall = '0') then
               if(deadlock_count = DEBUG_DEADLOCK_CYCLES) then
                  deadlock <= '1';
               else
                  deadlock_count <= deadlock_count + 1;
               end if;
            else
               deadlock_count <= 0;
            end if;
         end if;
         pc <= next_pc;
         first_cycle <= '0';

         if(icache_stall = '0') then
            iqueue_miss_d <= '0';
         end if;
         if(iqueue_miss = '1') then
            iqueue_miss_d <= '1';
            iqueue_missaddr_d <= iqueue_missaddr;
         end if;

         -- synch reset
         if(intreset = '1') then
            first_cycle <= '1';
            deadlock_count <= 0;
            deadlock <= '0';
            iqueue_miss_d <= '0';
         end if;
      end if;
   end process;

   process(clock) is begin
      if(rising_edge(clock)) then
         blinkenlights <= blinkenlights_raw;
         blinkenlights2 <= blinkenlights2_raw;
      end if;
   end process;

   mcheck_gen: if(MCHECK_ON) generate
      mcheck: entity work.mcheck port map(
         clock => clock,
         reset => intreset,

         p0p => p0_mcheck_p,
         p0r => p0_mcheck_r,
         p1p => p1_mcheck_p,
         p1r => p1_mcheck_r,

         bev => cop0_bev,
         refill => cop0_refill,
         eret => cop0_eret,
         epc => cop0_epc,

         d_mem_halt => c_mem_halt,
         cop0_stall => cop0_stall,
         muldiv_stall => muldiv_stall,

         mce => mce
      );
   end generate;
   mcheck_stub: if(not MCHECK_ON) generate
      mce <= '0';
   end generate;

   cache_invalidates: process(clock) is
      type state_t is (s_idle, s_dtlbwait, s_wait);
      variable state: state_t;
      variable is_d: std_logic;
   begin
      if(rising_edge(clock)) then
         case state is
            when s_idle =>
               c_inv_halt <= '0';
               if(c_mem_inv = '1') then
                  c_inv_halt <= '1';
                  cc_inv_op <= c_mem_invop(4 downto 2);
                  state := s_dtlbwait;
               end if;
            when s_dtlbwait =>
               if(c_paddroutv = '1') then
                  cc_inv_addr <= c_paddrout;
                  cc_inv <= '1';
                  state := s_wait;
               end if;
               if(c_mem_kill = '1') then
                  cc_inv <= '0';
                  state := s_idle;
               end if;
            when s_wait =>
               if(cc_inv_done = '1') then
                  cc_inv <= '0';
                  state := s_idle;
               end if;
            when others =>
               state := s_idle;
         end case;

         if(intreset = '1') then
            state := s_idle;
            cc_inv <= '0';
            c_inv_halt <= '0';
         end if;
      end if;
   end process;

   cache_controller: entity work.z48cc generic map(
      CLOCK_DOUBLING => CACHE_CLOCK_DOUBLING,
      WIDTH => CACHE_WIDTH,
      BLOCK_BITS => CACHE_BLOCK_BITS,
      CRITICAL_WORD_FIRST => CACHE_CRITICAL_WORD_FIRST,
      L1_OFFSET_BITS => get_l1_offset_bits,
      L1_WAYS => DCACHE_WAYS + ICACHE_WAYS,
      L2_OFFSET_BITS => L2_OFFSET_BITS,
      L2_WAYS => L2_WAYS,
      L2_REPLACE_TYPE => L2_REPLACE_TYPE,
      L2_SUB_REPLACE_TYPE => L2_SUB_REPLACE_TYPE,
      L2_HYBRID_BLOCK_FACTOR => L2_HYBRID_BLOCK_FACTOR,
      ENABLE_SNOOPING => L2_ENABLE_SNOOPING,
      DEBUG_SDATA => DEBUG_SDATA
   )
   port map(
      clock => clock,
      dclock => dclock,
      rst => intreset,

      init => cc_init_wait,
      synched => cc_synched,

      mshr_addr => cc_mshr_addr,
      mshr_valid => cc_mshr_valid,
      mshr_insstate => cc_mshr_insstate,

      l1_miss_addr => l1_miss_addr,
      l1_miss_valid => l1_miss_valid,
      l1_miss_minstate => l1_miss_minstate,
      l1_miss_curstate => l1_miss_curstate,
      l1_miss_way => l1_miss_way,
      l1_hint_share => l1_hint_share,

      l1_tag_addr => l1_tag_addr,
      l1_way_mask => l1_way_mask,
      l1_tag_as => l1_tag_as,
      l1_data_addr => l1_data_addr,
      l1_data_as => l1_data_as,
      l1_stag_addr => l1_stag_addr,
      l1_stag_as => l1_stag_as,

      l1_u_data => l1_u_data,
      l1_u_data_we => l1_u_data_we,
      l1_u_tag => l1_u_tag,
      l1_u_tag_we => l1_u_tag_we,
      l1_u_sdata => l1_u_sdata,
      l1_u_stag => l1_u_stag,

      l1_d_data => l1_d_data,
      l1_d_tag => l1_d_tag,
      l1_d_tag_match => l1_d_tag_match,
      l1_d_tag_dirty => l1_d_tag_dirty,
      l1_d_sdata => l1_d_sdata,
      l1_d_stag_match => l1_d_stag_match,
      l1_d_stag_excl => l1_d_stag_excl,

      inv => cc_inv,
      invaddr => cc_inv_addr,
      invop => cc_inv_op,
      invdone => cc_inv_done,

      m_addr => m_addr,
      m_out => m_out,
      m_burstcount => m_burstcount,
      m_rd => m_rd,
      m_wr => m_wr,
      m_halt => m_halt,
      m_valid => m_valid,
      m_in => m_in,

      s_bus_reqn => s_bus_reqn,
      s_bus_gntn => s_bus_gntn,
      s_bus_r_addr_oe => s_bus_r_addr_oe,
      s_bus_r_addr_out => s_bus_r_addr_out,
      s_bus_r_addr => s_bus_r_addr,
      s_bus_r_sharen_oe => s_bus_r_sharen_oe,
      s_bus_r_sharen => s_bus_r_sharen,
      s_bus_r_excln_oe => s_bus_r_excln_oe,
      s_bus_r_excln => s_bus_r_excln,
      s_bus_a_waitn_oe => s_bus_a_waitn_oe,
      s_bus_a_waitn => s_bus_a_waitn,
      s_bus_a_ackn_oe => s_bus_a_ackn_oe,
      s_bus_a_ackn => s_bus_a_ackn,
      s_bus_a_sharen_oe => s_bus_a_sharen_oe,
      s_bus_a_sharen => s_bus_a_sharen,
      s_bus_a_excln_oe => s_bus_a_excln_oe,
      s_bus_a_excln => s_bus_a_excln,

      perf_miss => cc_perf_miss,
      perf_fill_miss => cc_perf_fill_miss,
      perf_promote_miss => cc_perf_promote_miss,
      perf_dirty => cc_perf_dirty,
      perf_fill_excl => cc_perf_fill_excl,
      perf_wb => cc_perf_wb,
      perf_l2_hit => cc_perf_l2_hit,
      perf_l2_miss => cc_perf_l2_miss,
      perf_lsnoop_arbit => cc_perf_lsnoop_arbit,
      perf_lsnoop_wait => cc_perf_lsnoop_wait,
      perf_rsnoop => cc_perf_rsnoop,
      perf_rsnoop_S => cc_perf_rsnoop_S,
      perf_rsnoop_E => cc_perf_rsnoop_E,
      perf_reenter => cc_perf_reenter,
      perf_unlock => cc_perf_unlock,
      perf_l2_alias => cc_perf_l2_alias,
      perf_l2_nonalias => cc_perf_l2_nonalias,

      mce => l2_mce,
      mce_code => cc_mce_code
   );

   cache_glue: entity work.z48cc_glue generic map(
      WIDTH => CACHE_WIDTH,
      ICACHE_WAYS => ICACHE_WAYS,
      DCACHE_WAYS => DCACHE_WAYS,
      HINT_ICACHE_SHARE => CACHE_HINT_ICACHE_SHARE
   )
   port map(
      clock => clock,
      rst => reset,

      l1_miss_addr => l1_miss_addr,
      l1_miss_valid => l1_miss_valid,
      l1_miss_minstate => l1_miss_minstate,
      l1_miss_curstate => l1_miss_curstate,
      l1_miss_way => l1_miss_way,
      l1_hint_share => l1_hint_share,

      l1_tag_addr => l1_tag_addr,
      l1_way_mask => l1_way_mask,
      l1_tag_as => l1_tag_as,
      l1_data_addr => l1_data_addr,
      l1_data_as => l1_data_as,
      l1_stag_addr => l1_stag_addr,
      l1_stag_as => l1_stag_as,

      l1_u_data => l1_u_data,
      l1_u_data_we => l1_u_data_we,
      l1_u_tag_we => l1_u_tag_we,

      l1_d_tag_match => l1_d_tag_match,
      l1_d_tag_dirty => l1_d_tag_dirty,

      l1_d_stag_match => l1_d_stag_match,
      l1_d_stag_excl => l1_d_stag_excl,

      d_miss_addr => d_miss_addr,
      d_miss_valid => d_miss_valid,
      d_miss_minstate => d_miss_minstate,
      d_miss_curstate => d_miss_curstate,
      d_miss_way => d_miss_way,

      d_tag_addr => d_tag_addr,
      d_tag_as => d_tag_as,
      d_tag_match => d_tag_match,
      d_tag_dirty => d_tag_dirty,
      d_tag_oe => d_tag_oe,
      d_tag_we => d_tag_we,
      d_data_addr => d_data_addr,
      d_data_as => d_data_as,
      d_data_data => d_data_data,
      d_data_oe => d_data_oe,
      d_data_we => d_data_we,
      d_stag_addr => d_stag_addr,
      d_stag_as => d_stag_as,
      d_stag_match => d_stag_match,
      d_stag_excl => d_stag_excl,

      i_miss_addr => i_miss_addr,
      i_miss_valid => i_miss_valid,
      i_miss_minstate => i_miss_minstate,
      i_miss_curstate => i_miss_curstate,
      i_miss_way => i_miss_way,

      i_tag_addr => i_tag_addr,
      i_tag_as => i_tag_as,
      i_tag_match => i_tag_match,
      i_tag_dirty => i_tag_dirty,
      i_tag_oe => i_tag_oe,
      i_tag_we => i_tag_we,
      i_data_addr => i_data_addr,
      i_data_as => i_data_as,
      i_data_data => i_data_data,
      i_data_oe => i_data_oe,
      i_data_we => i_data_we,
      i_stag_addr => i_stag_addr,
      i_stag_as => i_stag_as,
      i_stag_match => i_stag_match,
      i_stag_excl => i_stag_excl
   );

   perf( 0) <= d_perf_req;
   perf( 1) <= d_perf_stall;
   perf( 2) <= d_perf_hit;
   perf( 3) <= cc_perf_miss;
   perf( 4) <= cc_perf_fill_miss;
   perf( 5) <= cc_perf_promote_miss;
   perf( 6) <= cc_perf_dirty;
   perf( 7) <= cc_perf_fill_excl;

   perf( 8) <= i_perf_req;
   perf( 9) <= i_perf_stall;
   perf(10) <= i_perf_hit;
   perf(11) <= cc_perf_wb;
   perf(12) <= i_perf_miss_stall;
   perf(13) <= d_perf_promote_miss_stall;
   perf(14) <= d_perf_inv_tlb_fault;
   perf(15) <= d_perf_miss_stall;

   perf(16) <= step;
   perf(17) <= stats0.predict or stats1.predict;
   perf(18) <= stats0.mispredict or stats1.mispredict;
   perf(19) <= stats0.alustall or stats1.alustall;
   perf(20) <= stats0.fwd_hazard or stats1.fwd_hazard;
   perf(21) <= stats0.uncond_branch or stats1.uncond_branch;
   perf(22) <= stats0.compute_branch or stats1.compute_branch;
   perf(23) <= not pipe_stall and g_perf_raw;

   perf(24) <= step and flush_pipe;
   perf(25) <= not pipe_stall and g_perf_cascade;
   perf(26) <= d_perf_turnaround_stall;
   perf(27) <= step and pipe_stall;
   perf(28) <= not pipe_stall and (g_perf_raw and not g_perf_cascade);
   perf(29) <= iqueue_miss;
   perf(30) <= stats0.exec;
   perf(31) <= stats1.exec;

   perf(32) <= cc_perf_lsnoop_arbit;
   perf(33) <= cc_perf_lsnoop_wait;
   perf(34) <= d_perf_sc_flushed;
   perf(35) <= i_perf_tlb_stall;
   perf(36) <= d_perf_tlb_stall;
   perf(37) <= itlb_miss or itlb_invalid or itlb_permerr;
   perf(38) <= dtlb_miss or dtlb_invalid or dtlb_permerr or dtlb_modified;
   perf(39) <= stats0.clever_flush;

   perf(40) <= d_perf_sc_success;
   perf(41) <= d_perf_sc_failure;
   perf(42) <= iqueue_empty and step;
   perf(43) <= iqueue_full and step;
   perf(44) <= cc_perf_l2_hit;
   perf(45) <= cc_perf_l2_miss;
   perf(46) <= dtlb_inv;
   perf(47) <= itlb_inv;

   perf(48) <= cc_perf_rsnoop;
   perf(49) <= cc_perf_rsnoop_S;
   perf(50) <= cc_perf_rsnoop_E;
   perf(51) <= cc_perf_reenter;
   perf(52) <= cc_perf_unlock;
   perf(53) <= cc_perf_l2_alias;
   perf(54) <= cc_perf_l2_nonalias;
   perf(55) <= '0';

   perf(56) <= itlb_ack or itlb_nack;
   perf(57) <= dtlb_ack or dtlb_nack;
   perf(58) <= itlb_nack;
   perf(59) <= dtlb_nack;
   perf(60) <= i_perf_tlb_hit;
   perf(61) <= i_perf_tlb_miss;
   perf(62) <= d_perf_tlb_hit;
   perf(63) <= d_perf_tlb_miss;

   perf(64) <= icache_in_valid(1) and icache_in_valid(0);
   perf(65) <= icache_in_valid(0) and not icache_in_valid(1);
   perf(66) <= icache_in_valid(1) and not icache_in_valid(0);
   perf(67) <= '0';
   perf(68) <= '0';
   perf(69) <= '0';
   perf(70) <= '0';
   perf(71) <= '0';

   special_trig <=   '1' when cop0_epc(11 downto 0) = x"f34" and cop0_badvaddr = x"00000059" else '0';
   special_trig2 <=  '1' when p0_ex.raise = '1' and p0_ex.code = EXC_BP else
                     '1' when p1_ex.raise = '1' and p1_ex.code = EXC_BP else
                     '0';

   triggers <= (
      0  => step,
      1  => p0_ex.raise or p1_ex.raise,
      2  => itlb_miss or itlb_invalid or itlb_permerr or i_unaligned,
      3  => dtlb_miss or dtlb_invalid or dtlb_permerr or dtlb_modified,
      4  => itlb_probe,
      5  => dtlb_probe,
      6  => l2_mce,
      7  => cop0_mce,
      8  => i_mce,
      9  => d_mce,
      10 => mce,
      11 => muldiv_fault,
      12 => iqueue_miss,
      13 => deadlock,
      14 => break_hit,
      others => '0'
   );
   blinkentriggers <= triggers;
   signaltap_trigger <= '1' when (triggers and triggermask) /= (17 downto 0 => '0') else '0';

   mce_code(8 downto 6) <=
      "100" when mce = '1' else
      "101" when cop0_mce = '1' or muldiv_fault = '1' else
      "110" when l2_mce = '1' else
      "111" when i_mce = '1' or d_mce = '1' else
      "000";
   mce_code(5 downto 0) <=
      "000001" when mce = '1' else
      "000001" when cop0_mce = '1' else
      "000010" when muldiv_fault = '1' else
      "000001" when d_mce = '1' else
      "000010" when i_mce = '1' else
      cc_mce_code when l2_mce = '1' else
      "111111";
end z48core;
