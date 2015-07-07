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

entity z4800 is
   generic(
      HAVE_DEBUG:                   boolean := false;
      HAVE_PERF:                    boolean := false;
      HAVE_TRACE:                   boolean := false;
      TRACE_LENGTH:                 natural := 64;
      HAVE_MCHECK:                  boolean := false;
      HAVE_MBOX:                    boolean := false;
      DEBUG_AUTOBOOT:               boolean := false;

      HAVE_MULTIPLY:                boolean := true;
      MULTIPLY_TYPE:                string := "COMB";
      COMB_MULTIPLY_CYCLES:         natural := 5;
      HAVE_DIVIDE:                  boolean := true;
      DIVIDE_TYPE:                  string := "COMB";
      COMB_DIVIDE_CYCLES:           natural := 15;
      SHIFT_TYPE:                   string := "BSHIFT";

      ALLOW_CASCADE:                boolean := true;

      FORWARD_DCACHE_EARLY:         boolean := true;
      FAST_MISPREDICT:              boolean := false;
      FAST_PREDICTOR_FEEDBACK:      boolean := false;
      FAST_REG_WRITE:               boolean := false;

      IQUEUE_LENGTH:                natural := 8;
      FETCH_MISS_DELAYED:           boolean := false;
      FETCH_ABORT_MISS:             boolean := true;

      FETCH_BRANCH_PREDICTOR:       boolean := true;
      FETCH_STATIC_PREDICTOR:       boolean := true;
      FETCH_DYNAMIC_PREDICTOR:      boolean := false;
      FETCH_HAVE_BTB:               boolean := false;
      FETCH_RETURN_ADDR_PREDICTOR:  boolean := false;
      FETCH_UNALIGNED_DELAY_SLOT:   boolean := false;
      FETCH_BRANCH_NOHINT:          boolean := false;

      BRANCH_PREDICTOR:             boolean := true;
      BRANCH_NOHINT:                boolean := true;
      STATIC_BRANCH_PREDICTOR:      boolean := false;
      DYNAMIC_BRANCH_PREDICTOR:     boolean := true;
      DYNAMIC_BRANCH_SIZE:          natural := 2048;
      CLEVER_FLUSH:                 boolean := true;
      HAVE_RASTACK:                 boolean := true;
      RASTACK_ENTRIES:              natural := 8;
      HAVE_BTB:                     boolean := true;
      BTB_TAGGED:                   boolean := true;
      BTB_VALID_BIT:                boolean := true;
      BTB_SIZE:                     natural := 128;

      JTLB_SIZE:                    natural := 16;
      JTLB_CAM_LATENCY:             natural := 1;
      JTLB_PRECISE_FLUSH:           boolean := true;
      NO_LARGE_PAGES:               boolean := false;

      ITLB_OFFSET_BITS:             natural := 6;
      ITLB_WAYS:                    natural := 1;
      ITLB_REPLACE_TYPE:            string := "LRU";
      ITLB_SUB_REPLACE_TYPE:        string := "LRU";
      ITLB_HYBRID_BLOCK_FACTOR:     natural := 2;
      ICACHE_BLOCK_BITS:            natural := 3;
      ICACHE_OFFSET_BITS:           natural := 6;
      ICACHE_WAYS:                  natural := 1;
      ICACHE_REPLACE_TYPE:          string := "LRU";
      ICACHE_SUB_REPLACE_TYPE:      string := "LRU";
      ICACHE_HYBRID_BLOCK_FACTOR:   natural := 2;
      ICACHE_EARLY_RESTART:         boolean := false;

      DTLB_OFFSET_BITS:             natural := 6;
      DTLB_WAYS:                    natural := 1;
      DTLB_REPLACE_TYPE:            string := "LRU";
      DTLB_SUB_REPLACE_TYPE:        string := "LRU";
      DTLB_HYBRID_BLOCK_FACTOR:     natural := 2;
      DCACHE_BLOCK_BITS:            natural := 4;
      DCACHE_OFFSET_BITS:           natural := 6;
      DCACHE_WAYS:                  natural := 1;
      DCACHE_REPLACE_TYPE:          string := "LRU";
      DCACHE_SUB_REPLACE_TYPE:      string := "LRU";
      DCACHE_HYBRID_BLOCK_FACTOR:   natural := 2;
      DCACHE_EARLY_RESTART:         boolean := false;
      DCACHE_LATENCY:               integer range 1 to 2 := 1;

      CACHE_CLOCK_DOUBLING:         boolean := false;
      CACHE_WIDTH:                  natural := 64;
      CACHE_BLOCK_BITS:             natural := 3;
      CACHE_CRITICAL_WORD_FIRST:    boolean := true;
      CACHE_HINT_ICACHE_SHARE:      boolean := true;
      L2_OFFSET_BITS:               natural := 0;
      L2_WAYS:                      natural := 0;
      L2_REPLACE_TYPE:              string := "PLRU";
      L2_SUB_REPLACE_TYPE:          string := "LRU";
      L2_HYBRID_BLOCK_FACTOR:       natural := 2;
      L2_ENABLE_SNOOPING:           boolean := false;

      BUS_CDC:                      boolean := true;
      BUS_SMFIFO_DEPTH:             natural := 8;
      BUS_MSFIFO_DEPTH:             natural := 32;
      BUS_CLOCKS_SYNCHED:           boolean := true;
      BUS_SYNCH_STAGES:             natural := 2
   );
   port(
      reset:                        in std_logic;
      coreclk:                      in std_logic;
      dcoreclk:                     in std_logic;

      eirqs:                        in std_logic_vector(1 downto 0);

      iu_mem_in:                    in dword;
      iu_mem_addr:                  out word;
      iu_mem_rd:                    buffer std_logic;
      iu_mem_halt:                  in std_logic;
      iu_mem_valid:                 in std_logic;

      m_clk:                        in std_logic;
      m_rst:                        in std_logic;
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

      u_mem_in:                     in word;
      u_mem_out:                    out word;
      u_mem_addr:                   out word;
      u_mem_rd:                     out std_logic;
      u_mem_wr:                     out std_logic;
      u_mem_halt:                   in std_logic;
      u_mem_valid:                  in std_logic;
      u_mem_be:                     out std_logic_vector(3 downto 0);

      debug_mem_addr:               in std_logic_vector(5 downto 0);
      debug_mem_in:                 in word;
      debug_mem_out:                out word;
      debug_mem_be:                 in std_logic_vector(3 downto 0);
      debug_mem_rd:                 in std_logic;
      debug_mem_wr:                 in std_logic;
      debug_mem_halt:               out std_logic;

      trace_mem_addr:               in std_logic_vector(15 downto 0);
      trace_mem_in:                 in word;
      trace_mem_out:                out word;
      trace_mem_be:                 in std_logic_vector(3 downto 0);
      trace_mem_rd:                 in std_logic;
      trace_mem_wr:                 in std_logic;
      trace_mem_halt:               out std_logic;

      mbox_addr:                    in std_logic_vector(0 downto 0) := (others => '-');
      mbox_out:                     out std_logic_vector(31 downto 0);
      mbox_in:                      in std_logic_vector(31 downto 0) := (others => '-');
      mbox_rd:                      in std_logic := '0';
      mbox_wr:                      in std_logic := '0';

      perf_addr:                    in std_logic_vector(6 downto 0);
      perf_in:                      in std_logic_vector(31 downto 0);
      perf_out:                     out std_logic_vector(31 downto 0);
      perf_be:                      in std_logic_vector(3 downto 0);
      perf_rd:                      in std_logic;
      perf_wr:                      in std_logic;

      blinkenlights:                out std_logic_vector(7 downto 0);
      blinkenlights2:               out std_logic_vector(7 downto 0);

      triggermask:                  in std_logic_vector(17 downto 0);
      signaltap_trigger:            buffer std_logic;
      blinkentriggers:              out std_logic_vector(17 downto 0);

      mce_code:                     out std_logic_vector(8 downto 0)
   );
end;

architecture z4800 of z4800 is
   constant CACHE_BYTE_BITS:        natural := log2c(CACHE_WIDTH / 8);

   signal mbox_irq:                 std_logic;
   signal perf_inc:                 std_logic_vector(71 downto 0);

   signal cpu_m_addr:               word;
   signal cpu_m_out:                std_logic_vector(CACHE_WIDTH - 1 downto 0);
   signal cpu_m_burstcount:         std_logic_vector(CACHE_BLOCK_BITS downto 0);
   signal cpu_m_rd:                 std_logic;
   signal cpu_m_wr:                 std_logic;
   signal cpu_m_halt:               std_logic;
   signal cpu_m_valid:              std_logic;
   signal cpu_m_in:                 std_logic_vector(CACHE_WIDTH - 1 downto 0);
begin
   cpu: entity work.z48core generic map(
      DEBUG_ON => HAVE_DEBUG,
      TRACE_ON => HAVE_TRACE,
      TRACE_LENGTH => TRACE_LENGTH,
      MCHECK_ON => HAVE_MCHECK,
      DEBUG_AUTOBOOT => DEBUG_AUTOBOOT,
      
      HAVE_MULTIPLY => HAVE_MULTIPLY,
      MULTIPLY_TYPE => MULTIPLY_TYPE,
      COMB_MULTIPLY_CYCLES => COMB_MULTIPLY_CYCLES,
      HAVE_DIVIDE => HAVE_DIVIDE,
      DIVIDE_TYPE => DIVIDE_TYPE,
      COMB_DIVIDE_CYCLES => COMB_DIVIDE_CYCLES,
      SHIFT_TYPE => SHIFT_TYPE,

      ALLOW_CASCADE => ALLOW_CASCADE,

      FORWARD_DCACHE_EARLY => FORWARD_DCACHE_EARLY,
      FAST_MISPREDICT => FAST_MISPREDICT,
      FAST_PREDICTOR_FEEDBACK => FAST_PREDICTOR_FEEDBACK,
      FAST_REG_WRITE => FAST_REG_WRITE,

      IQUEUE_LENGTH => IQUEUE_LENGTH,
      FETCH_ABORT_MISS => FETCH_ABORT_MISS,
      FETCH_MISS_DELAYED => FETCH_MISS_DELAYED,

      FETCH_BRANCH_PREDICTOR => FETCH_BRANCH_PREDICTOR,
      FETCH_STATIC_PREDICTOR => FETCH_STATIC_PREDICTOR,
      FETCH_DYNAMIC_PREDICTOR => FETCH_DYNAMIC_PREDICTOR,
      FETCH_HAVE_BTB => FETCH_HAVE_BTB,
      FETCH_RETURN_ADDR_PREDICTOR => FETCH_RETURN_ADDR_PREDICTOR,
      FETCH_UNALIGNED_DELAY_SLOT => FETCH_UNALIGNED_DELAY_SLOT,
      FETCH_BRANCH_NOHINT => FETCH_BRANCH_NOHINT,

      BRANCH_PREDICTOR => BRANCH_PREDICTOR,
      BRANCH_NOHINT => BRANCH_NOHINT,
      STATIC_BRANCH_PREDICTOR => STATIC_BRANCH_PREDICTOR,
      DYNAMIC_BRANCH_PREDICTOR => DYNAMIC_BRANCH_PREDICTOR,
      DYNAMIC_BRANCH_SIZE => DYNAMIC_BRANCH_SIZE,
      CLEVER_FLUSH => CLEVER_FLUSH,
      HAVE_RASTACK => HAVE_RASTACK,
      RASTACK_ENTRIES => RASTACK_ENTRIES,
      HAVE_BTB => HAVE_BTB,
      BTB_TAGGED => BTB_TAGGED,
      BTB_VALID_BIT => BTB_VALID_BIT,
      BTB_SIZE => BTB_SIZE,

      JTLB_SIZE => JTLB_SIZE,
      JTLB_CAM_LATENCY => JTLB_CAM_LATENCY,
      JTLB_PRECISE_FLUSH => JTLB_PRECISE_FLUSH,
      NO_LARGE_PAGES => NO_LARGE_PAGES,

      ITLB_OFFSET_BITS => ITLB_OFFSET_BITS,
      ITLB_WAYS => ITLB_WAYS,
      ITLB_REPLACE_TYPE => ITLB_REPLACE_TYPE,
      ITLB_SUB_REPLACE_TYPE => ITLB_SUB_REPLACE_TYPE,
      ITLB_HYBRID_BLOCK_FACTOR => ITLB_HYBRID_BLOCK_FACTOR,
      ICACHE_BLOCK_BITS => ICACHE_BLOCK_BITS,
      ICACHE_OFFSET_BITS => ICACHE_OFFSET_BITS,
      ICACHE_WAYS => ICACHE_WAYS,
      ICACHE_REPLACE_TYPE => ICACHE_REPLACE_TYPE,
      ICACHE_SUB_REPLACE_TYPE => ICACHE_SUB_REPLACE_TYPE,
      ICACHE_HYBRID_BLOCK_FACTOR => ICACHE_HYBRID_BLOCK_FACTOR,
      ICACHE_EARLY_RESTART => ICACHE_EARLY_RESTART,

      DTLB_OFFSET_BITS => DTLB_OFFSET_BITS,
      DTLB_WAYS => DTLB_WAYS,
      DTLB_REPLACE_TYPE => DTLB_REPLACE_TYPE,
      DTLB_SUB_REPLACE_TYPE => DTLB_SUB_REPLACE_TYPE,
      DTLB_HYBRID_BLOCK_FACTOR => DTLB_HYBRID_BLOCK_FACTOR,
      DCACHE_BLOCK_BITS => DCACHE_BLOCK_BITS,
      DCACHE_OFFSET_BITS => DCACHE_OFFSET_BITS,
      DCACHE_WAYS => DCACHE_WAYS,
      DCACHE_REPLACE_TYPE => DCACHE_REPLACE_TYPE,
      DCACHE_SUB_REPLACE_TYPE => DCACHE_SUB_REPLACE_TYPE,
      DCACHE_HYBRID_BLOCK_FACTOR => DCACHE_HYBRID_BLOCK_FACTOR,
      DCACHE_EARLY_RESTART => DCACHE_EARLY_RESTART,
      DCACHE_LATENCY => DCACHE_LATENCY,

      CACHE_CLOCK_DOUBLING => CACHE_CLOCK_DOUBLING,
      CACHE_WIDTH => CACHE_WIDTH,
      CACHE_BLOCK_BITS => CACHE_BLOCK_BITS,
      CACHE_CRITICAL_WORD_FIRST => CACHE_CRITICAL_WORD_FIRST,
      CACHE_HINT_ICACHE_SHARE => CACHE_HINT_ICACHE_SHARE,
      L2_OFFSET_BITS => L2_OFFSET_BITS,
      L2_WAYS => L2_WAYS,
      L2_REPLACE_TYPE => L2_REPLACE_TYPE,
      L2_SUB_REPLACE_TYPE => L2_SUB_REPLACE_TYPE,
      L2_HYBRID_BLOCK_FACTOR => L2_HYBRID_BLOCK_FACTOR,
      L2_ENABLE_SNOOPING => L2_ENABLE_SNOOPING
   )
   port map(
      reset => reset,
      clock => coreclk,
      dclock => dcoreclk,

      eirqs => eirqs,

      iu_mem_in => iu_mem_in,
      iu_mem_addr => iu_mem_addr,
      iu_mem_rd => iu_mem_rd,
      iu_mem_halt => iu_mem_halt,
      iu_mem_valid => iu_mem_valid,

      u_mem_in => u_mem_in,
      u_mem_out => u_mem_out,
      u_mem_addr => u_mem_addr,
      u_mem_rd => u_mem_rd,
      u_mem_wr => u_mem_wr,
      u_mem_halt => u_mem_halt,
      u_mem_valid => u_mem_valid,
      u_mem_be => u_mem_be,
      
      m_addr => cpu_m_addr,
      m_out => cpu_m_out,
      m_burstcount => cpu_m_burstcount,
      m_rd => cpu_m_rd,
      m_wr => cpu_m_wr,
      m_halt => cpu_m_halt,
      m_valid => cpu_m_valid,
      m_in => cpu_m_in,

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

      debug_mem_addr => debug_mem_addr,
      debug_mem_in => debug_mem_in,
      debug_mem_out => debug_mem_out,
      debug_mem_be => debug_mem_be,
      debug_mem_rd => debug_mem_rd,
      debug_mem_wr => debug_mem_wr,
      debug_mem_halt => debug_mem_halt,

      trace_mem_addr => trace_mem_addr,
      trace_mem_in => trace_mem_in,
      trace_mem_out => trace_mem_out,
      trace_mem_rd => trace_mem_rd,
      trace_mem_wr => trace_mem_wr,
      trace_mem_halt => trace_mem_halt,

      mbox_irq => mbox_irq,
      blinkenlights => blinkenlights,
      blinkenlights2 => blinkenlights2,
      triggermask => triggermask,
      signaltap_trigger => signaltap_trigger,
      blinkentriggers => blinkentriggers,
      mce_code => mce_code,
      perf => perf_inc
   );

   mboxgen: if(HAVE_MBOX) generate
      mbox: entity work.mbox port map(
         clock => coreclk,
         reset => reset,

         mem_adr => mbox_addr,
         mem_out => mbox_out,
         mem_in => mbox_in,
         mem_rd => mbox_rd,
         mem_wr => mbox_wr,

         irq => mbox_irq
      );
   end generate;
   mboxoff: if(not HAVE_MBOX) generate
      mbox_irq <= '0';
   end generate;

   perfgen: if(HAVE_PERF) generate
      perfctrs: entity work.perf generic map(
         NR_COUNTERS_LOG2 => 7
      )
      port map(
         clock => coreclk,
         rst => reset,
         clr => '0',

         m_addr => perf_addr,
         m_in => perf_in,
         m_out => perf_out,
         m_be => perf_be,
         m_rd => perf_rd,
         m_wr => perf_wr,

         perf_inc(71 downto 0) => perf_inc,
         perf_inc(127 downto 72) => (others => '0')
      );
   end generate;

   need_cc: if(BUS_CDC) generate
      bus_cc: entity work.fast_cc generic map(
         ADDRBITS => 32 - CACHE_BYTE_BITS,
         WIDTH => CACHE_WIDTH,
         SMFIFO_DEPTH => BUS_SMFIFO_DEPTH,
         MSFIFO_DEPTH => BUS_MSFIFO_DEPTH,
         CLOCKS_SYNCHED => BUS_CLOCKS_SYNCHED,
         SYNCH_STAGES => BUS_SYNCH_STAGES,
         ENABLE_BURST => true,
         BURST_BITS => CACHE_BLOCK_BITS + 1,
         SINGLE_BURST => true
      )
      port map(
         a_rst => reset,

         s_clk => coreclk,
         s_addr => cpu_m_addr(31 downto CACHE_BYTE_BITS),
         s_rd => cpu_m_rd,
         s_wr => cpu_m_wr,
         s_in => cpu_m_out,
         s_out => cpu_m_in,
         s_be => (others => '1'),
         s_halt => cpu_m_halt,
         s_valid => cpu_m_valid,
         s_burstcount => cpu_m_burstcount,

         m_clk => m_clk,
         m_addr => m_addr,
         m_rd => m_rd,
         m_wr => m_wr,
         m_in => m_in,
         m_out => m_out,
         m_halt => m_halt,
         m_valid => m_valid,
         m_burstcount => m_burstcount
      );
   end generate;
   no_bus_cc: if(not BUS_CDC) generate
      m_addr <= cpu_m_addr;
      m_rd <= cpu_m_rd;
      m_wr <= cpu_m_wr;
      m_out <= cpu_m_out;
      cpu_m_in <= m_in;
      cpu_m_halt <= m_halt;
      cpu_m_valid <= m_valid;
      m_burstcount <= cpu_m_burstcount;
   end generate;
end;
