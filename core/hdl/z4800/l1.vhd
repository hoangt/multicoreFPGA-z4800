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
library altera;
use altera.altera_syn_attributes.all;

entity l1 is
   generic(
      CLOCK_DOUBLING:               boolean;
      CPU_WIDTH:                    natural;
      CPU_BLOCK_BITS:               natural;
      REFILL_WIDTH:                 natural;
      REFILL_BLOCK_BITS:            natural;
      OFFSET_BITS:                  natural;
      WAYS:                         natural;
      TLB_OFFSET_BITS:              natural;
      TLB_WAYS:                     natural;
      TLB_REPLACE_TYPE:             string;
      TLB_SUB_REPLACE_TYPE:         string;
      TLB_HYBRID_BLOCK_FACTOR:      natural;
      REPLACE_TYPE:                 string;
      SUB_REPLACE_TYPE:             string;
      HYBRID_BLOCK_FACTOR:          natural;
      LATENCY:                      integer range 1 to 2 := 2;
      ENABLE_STAGS:                 boolean;
      READ_ONLY:                    boolean := false;
      EARLY_RESTART:                boolean := false;
      DEBUG_SDATA:                  boolean := false
   );
   port(
      clock:                        in std_logic;
      dclock:                       in std_logic;
      rst:                          in std_logic;

      c_asid:                       in std_logic_vector(7 downto 0);
      c_mode:                       in mode_t;
      c_addr:                       in word;
      c_addrout:                    out word;
      c_paddrout:                   out word;
      c_paddroutv:                  out std_logic;
      c_in:                         in std_logic_vector(CPU_WIDTH - 1 downto 0);
      c_out:                        out std_logic_vector(CPU_WIDTH - 1 downto 0);
      c_rd:                         in std_logic;
      c_wr:                         in std_logic;
      c_ll:                         in std_logic := '0';
      c_sc:                         in std_logic := '0';
      c_scok:                       buffer std_logic;
      c_inv:                        in std_logic := '0';
      c_kill:                       in std_logic;
      c_halt:                       buffer std_logic;
      c_valid:                      out std_logic;
      c_invalid:                    out std_logic;
      c_be:                         in std_logic_vector((CPU_WIDTH / 8) - 1 downto 0);
      c_sync:                       in std_logic := '0';

      tlb_miss:                     buffer std_logic;
      tlb_invalid:                  buffer std_logic;
      tlb_modified:                 buffer std_logic;
      tlb_permerr:                  buffer std_logic;
      tlb_stall:                    buffer std_logic;

      tlb_vaddr:                    out word;
      tlb_probe:                    out std_logic;
      tlb_ack:                      in std_logic;
      tlb_nack:                     in std_logic;
      tlb_ent:                      in utlb_raw_t;
      tlb_inv_addr:                 in std_logic_vector(TLB_OFFSET_BITS - 1 downto 0);
      tlb_inv:                      in std_logic;

      u_addr:                       out word;
      u_out:                        out std_logic_vector(CPU_WIDTH - 1 downto 0);
      u_be:                         out std_logic_vector((CPU_WIDTH / 8) - 1 downto 0);
      u_rd:                         buffer std_logic;
      u_wr:                         buffer std_logic;
      
      u_halt:                       in std_logic;
      u_valid:                      in std_logic;
      u_in:                         in std_logic_vector(CPU_WIDTH - 1 downto 0);

      miss_addr:                    buffer word;
      miss_valid:                   buffer std_logic;
      miss_minstate:                buffer cache_state_t;
      miss_curstate:                buffer cache_state_t;
      miss_way:                     out std_logic_vector(log2c(WAYS) - 1 downto 0);

      cc_init_wait:                 in std_logic;
      cc_synched:                   in std_logic;

      cc_mshr_addr:                 in word;
      cc_mshr_valid:                in std_logic;
      cc_mshr_insstate:             in cache_state_t;

      tag_addr:                     in word;
      tag_as:                       in std_logic;
      tag_data:                     in std_logic_vector(CACHE_STATE_BITS + 32 - 1 downto 0);
      tag_q:                        inout std_logic_vector(CACHE_STATE_BITS + 32 - 1 downto 0);
      tag_match:                    out std_logic_vector(WAYS - 1 downto 0);
      tag_dirty:                    out std_logic_vector(WAYS - 1 downto 0);
      tag_oe:                       in std_logic_vector(WAYS - 1 downto 0);
      tag_we:                       in std_logic_vector(WAYS - 1 downto 0);

      data_addr:                    in word;
      data_as:                      in std_logic;
      data_data:                    in std_logic_vector(REFILL_WIDTH - 1 downto 0);
      data_q:                       inout std_logic_vector(REFILL_WIDTH - 1 downto 0);
      data_oe:                      in std_logic_vector(WAYS - 1 downto 0);
      data_we:                      in std_logic_vector(WAYS - 1 downto 0);

      sdata_data:                   in word;
      sdata_q:                      inout word;

      stag_addr:                    in word;
      stag_as:                      in std_logic;
      stag_data:                    in std_logic_vector(CACHE_STATE_BITS + 32 - 1 downto 0);
      stag_match:                   out std_logic_vector(WAYS - 1 downto 0);
      stag_excl:                    out std_logic_vector(WAYS - 1 downto 0);

      mce:                          buffer std_logic;

      perf_req:                     out std_logic;
      perf_stall:                   out std_logic;
      perf_hit:                     out std_logic;
      perf_miss_stall:              buffer std_logic;
      perf_promote_miss_stall:      out std_logic;
      perf_tlb_stall:               out std_logic;
      perf_tlb_hit:                 out std_logic;
      perf_tlb_miss:                out std_logic;
      perf_sc_success:              out std_logic;
      perf_sc_failure:              out std_logic;
      perf_sc_flushed:              out std_logic;
      perf_turnaround_stall:        out std_logic;
      perf_inv_tlb_fault:           out std_logic;

      tlb_cacheable_mask:           in std_logic := '1'
   );
end entity;

architecture l1 of l1 is
   constant CPU_BYTE_INDEX_BITS: natural := log2c(CPU_WIDTH / 8);
   constant REFILL_BYTE_INDEX_BITS: natural := log2c(REFILL_WIDTH / 8);
   constant CPU_BYTES: natural := CPU_WIDTH / 8;
   constant CPU_BLOCKS: natural := 2 ** CPU_BLOCK_BITS;
   constant REFILL_BLOCKS: natural := 2 ** REFILL_BLOCK_BITS;
   constant SETS: natural := 2 ** OFFSET_BITS;
   constant WAY_BITS: natural := log2c(WAYS);

   -- address slicing: tag & offset & block & byte
   constant CBL: natural := 0;
   constant CBH: natural := CPU_BYTE_INDEX_BITS - 1;
   constant RBL: natural := 0;
   constant RBH: natural := REFILL_BYTE_INDEX_BITS - 1;
   constant CBLKL: natural := CBH + 1;
   constant CBLKH: natural := CBLKL + CPU_BLOCK_BITS - 1;
   constant RBLKL: natural := RBH + 1;
   constant RBLKH: natural := RBLKL + REFILL_BLOCK_BITS - 1;
   constant OFFL: natural := CBLKH + 1;
   constant OFFH: natural := OFFL + OFFSET_BITS - 1;
   constant TAGL: natural := OFFH + 1;
   constant TAGH: natural := 31;

   -- tag ram layout
   constant T_TAG_BITS: natural := 32 - (CPU_BYTE_INDEX_BITS + CPU_BLOCK_BITS + OFFSET_BITS);
   constant T_TAG_L: natural := 0;
   constant T_TAG_H: natural := T_TAG_L + T_TAG_BITS - 1;
   constant T_STATE_L: natural := T_TAG_H + 1;
   constant T_STATE_H: natural := T_STATE_L + CACHE_STATE_BITS - 1;
   constant T_BITS: natural := T_STATE_H + 1;

   signal tlb_as:                   std_logic;
   signal tlb_paddr:                word;
   signal tlb_cacheable_raw:        std_logic;
   signal tlb_cacheable:            std_logic;
   signal tlb_mapped:               std_logic;
   signal tlb_fault:                std_logic;

   type c_req_t is record
      vaddr: word;
      paddr: word;
      data_in: std_logic_vector(CPU_WIDTH - 1 downto 0);
      ucdata: std_logic_vector(CPU_WIDTH - 1 downto 0);
      rd: std_logic;
      wr: std_logic;
      ll: std_logic;
      sc: std_logic;
      be: std_logic_vector(CPU_BYTES - 1 downto 0);
      cacheable: std_logic;
      way: integer range 0 to WAYS - 1;
      valid: std_logic;
      invalid: std_logic;
      min_state: std_logic_vector(CACHE_STATE_BITS - 1 downto 0);
      sync: std_logic;
      inv: std_logic;
   end record;
   type c_req_a_t is array(0 to 2) of c_req_t;
   signal c_req:                    c_req_a_t;

   type tag_a_t is array(WAYS - 1 downto 0) of std_logic_vector(T_BITS - 1 downto 0);
   signal tag_q_a, tag_q_b:         tag_a_t;
   signal tag_addr_a:               std_logic_vector(OFFSET_BITS - 1 downto 0);
   signal tag_addr_r:               std_logic_vector(tag_addr'range);
   signal tag_as_a:                 std_logic;

   signal stag_q_b:                 tag_a_t;
   signal stag_addr_r:              std_logic_vector(stag_addr'range);

   signal restart_way:              std_logic_vector(WAY_BITS - 1 downto 0);
   signal restart_ok:               std_logic;

   type data_cpu_a_t is array(WAYS - 1 downto 0) of std_logic_vector(CPU_WIDTH - 1 downto 0);
   type data_refill_a_t is array(WAYS - 1 downto 0) of std_logic_vector(REFILL_WIDTH - 1 downto 0);
   signal data_q_a:                 data_cpu_a_t;
   signal data_q_b:                 data_refill_a_t;
   signal data_addr_a:              std_logic_vector(OFFSET_BITS + CPU_BLOCK_BITS - 1 downto 0);
   signal data_as_a:                std_logic;
   signal data_data_a:              std_logic_vector(CPU_WIDTH - 1 downto 0);
   signal data_be_a:                std_logic_vector(CPU_BYTES - 1 downto 0);
   signal data_we_a:                std_logic_vector(WAYS - 1 downto 0);
   signal data_clk_b:               std_logic;

   type sdata_q_a_t is array(WAYS - 1 downto 0) of word;
   signal sdata_q_a, sdata_q_b:     sdata_q_a_t;

   signal miss, hit:                std_logic;
   signal hit_vec:                  std_logic_vector(WAYS - 1 downto 0);
   signal victimway:                std_logic_vector(log2c(WAYS) - 1 downto 0);
   signal emptyway:                 std_logic_vector(log2c(WAYS) - 1 downto 0);
   signal have_emptyway:            std_logic;
   
   signal req_issue:                std_logic;
   signal u_issued:                 std_logic;
   signal u_aborted:                std_logic;
   signal u_halt_r:                 std_logic;

   signal LLlocal:                  std_logic;
   signal LLaddr:                   word;

   signal turnaround_stall:         std_logic;

   signal c_sout:                   word;
   attribute keep of c_sout:        signal is true;
begin
   assert(RBLKH = CBLKH) report "CPU and refill line sizes must be the same" severity error;
   assert(OFFH < 12) report "Cache way size bigger than 4K; virtual aliasing will occur. FIXME: cache controller is very broken due to mixture of virtual/physical indexing for tags (refill/snooping/invalidates)" severity error;
   assert(not EARLY_RESTART or (REFILL_BLOCK_BITS <= CPU_BLOCK_BITS)) report "EARLY_RESTART requires refill word size to be larger than cpu word size" severity error;
   assert(REFILL_BLOCKS >= 2) report "Refill must have at least 2 beats per cacheline" severity error;

   tlb: entity work.utlb generic map(
      OFFSET_BITS => TLB_OFFSET_BITS,
      WAYS => TLB_WAYS,
      REPLACE_TYPE => TLB_REPLACE_TYPE,
      SUB_REPLACE_TYPE => TLB_SUB_REPLACE_TYPE,
      HYBRID_BLOCK_FACTOR => TLB_HYBRID_BLOCK_FACTOR
   )
   port map(
      clock => clock,
      rst => rst,

      addrstall => tlb_as,
      vaddr => c_addr(TAGH downto CBLKL) & (CBH downto CBL => '0'),
      probe => c_req(1).rd or c_req(1).wr or c_req(1).inv,
      kill => c_kill,
      write => c_req(1).wr,
      asid => c_asid,
      mode => c_mode,

      jtlb_vaddr => tlb_vaddr,
      jtlb_probe => tlb_probe,
      jtlb_ack => tlb_ack,
      jtlb_nack => tlb_nack,
      jtlb_ent => tlb_ent,
      jtlb_inv_addr => tlb_inv_addr,
      jtlb_inv => tlb_inv,

      paddr => tlb_paddr,
      stall => tlb_stall,
      miss => tlb_miss,
      invalid => tlb_invalid,
      modified => tlb_modified,
      cacheable => tlb_cacheable_raw,
      permerr => tlb_permerr,
      mapped => tlb_mapped,
      fault => tlb_fault

      --perf_hit => perf_tlb_hit,
      --perf_miss => perf_tlb_miss
   );
   tlb_as <= c_halt;
   tlb_cacheable <= tlb_cacheable_raw and tlb_cacheable_mask;
   c_paddrout <= c_req(1).paddr;
   c_paddroutv <= tlb_mapped;

   c_req(0).vaddr <= c_addr;
   c_req(0).data_in <= c_in;
   c_req(0).rd <= c_rd;
   c_req(0).wr <= c_wr;
   c_req(0).ll <= c_ll;
   c_req(0).sc <= c_sc;
   c_req(0).be <= c_be;
   c_req(0).min_state <=
      T_STATE_SHARED when c_req(0).rd = '1' else
      T_STATE_MODIFIED when c_req(0).wr = '1' else
      T_STATE_INVALID;
   c_req(0).sync <= c_sync;
   c_req(0).inv <= c_inv;
   c_req(1).paddr <= tlb_paddr;
   c_req(1).cacheable <= tlb_cacheable;

   frontend_regs: process(clock) is begin
      if(rising_edge(clock)) then
         c_req(2) <= c_req(1);
         if(c_halt = '1' or c_kill = '1') then
            c_req(2).rd <= '0';
            c_req(2).wr <= '0';
         end if;
         if(c_halt = '0') then
            c_req(1).vaddr <= c_req(0).vaddr;
            c_req(1).data_in <= c_req(0).data_in;
            c_req(1).rd <= c_req(0).rd;
            c_req(1).wr <= c_req(0).wr;
            c_req(1).ll <= c_req(0).ll;
            c_req(1).sc <= c_req(0).sc;
            c_req(1).be <= c_req(0).be;
            c_req(1).min_state <= c_req(0).min_state;
            c_req(1).sync <= c_req(0).sync;
            c_req(1).inv <= c_req(0).inv;
         end if;

         if(rst = '1') then
            for i in c_req'low + 1 to c_req'high loop
               c_req(i).rd <= '0';
               c_req(i).wr <= '0';
               c_req(i).ll <= '0';
               c_req(i).sc <= '0';
               c_req(i).sync <= '0';
               c_req(i).inv <= '0';
            end loop;
         end if;
      end if;
   end process;

   tag_addr_a <= c_req(0).vaddr(OFFH downto OFFL);
   tag_as_a <= c_halt;

   data_addr_a <= c_req(1).vaddr(OFFH downto CBLKL) when LATENCY = 2 else
                  c_req(1).vaddr(OFFH downto CBLKL) when c_req(1).wr = '1' else
                  c_req(1).vaddr(OFFH downto CBLKL) when turnaround_stall = '1' else
                  c_req(0).vaddr(OFFH downto CBLKL);
   data_as_a <=   '0' when LATENCY = 2 else
                  '0' when c_req(1).wr = '1' else
                  '0' when turnaround_stall = '1' else
                  c_halt;
   data_data_a <= c_req(1).data_in;
   data_be_a <= c_req(1).be;
   data_we_a <=
      (others => '0') when READ_ONLY else
      (others => '0') when c_req(1).wr = '0' else
      (others => '0') when c_kill = '1' else
      (others => '0') when tlb_mapped = '0' else
      (others => '0') when tlb_cacheable = '0' else
      hit_vec;

   gen_ways: for i in 0 to WAYS - 1 generate
      tags: altsyncram generic map(
         WIDTH_A => T_BITS,
         WIDTHAD_A => OFFSET_BITS,
         WIDTH_B => T_BITS,
         WIDTHAD_B => OFFSET_BITS
      )
      port map(
         clock0 => clock,
         clock1 => clock,
         address_a => tag_addr_a,
         addressstall_a => tag_as_a,
         address_b => tag_addr(OFFH downto OFFL),
         addressstall_b => tag_as,
         q_a => tag_q_a(i),
         q_b => tag_q_b(i),
         data_b => tag_data(CACHE_STATE_BITS + TAGH downto TAGL),
         wren_b => tag_we(i)
      );

      stags_gen: if(ENABLE_STAGS) generate
         stags: altsyncram generic map(
            WIDTH_A => T_BITS,
            WIDTHAD_A => OFFSET_BITS,
            WIDTH_B => T_BITS,
            WIDTHAD_B => OFFSET_BITS,
            OPERATION_MODE => "DUAL_PORT"
         )
         port map(
            clock0 => clock,
            clock1 => clock,
            address_a => tag_addr(OFFH downto OFFL),
            addressstall_a => tag_as,
            address_b => stag_addr(OFFH downto OFFL),
            addressstall_b => stag_as,
            q_b => stag_q_b(i),
            data_a => tag_data(CACHE_STATE_BITS + TAGH downto TAGL),
            wren_a => tag_we(i)
         );
      end generate;

      data: altsyncram generic map(
         WIDTH_A => CPU_WIDTH,
         WIDTHAD_A => OFFSET_BITS + CPU_BLOCK_BITS,
         NUMWORDS_A => SETS * CPU_BLOCKS,
         WIDTH_BYTEENA_A => CPU_BYTES,
         WIDTH_B => REFILL_WIDTH,
         WIDTHAD_B => OFFSET_BITS + REFILL_BLOCK_BITS,
         NUMWORDS_B => SETS * REFILL_BLOCKS
      )
      port map(
         clock0 => clock,
         clock1 => data_clk_b,
         address_a => data_addr_a,
         addressstall_a => data_as_a,
         address_b => data_addr(OFFH downto RBLKL),
         addressstall_b => data_as,
         q_a => data_q_a(i),
         q_b => data_q_b(i),
         data_a => data_data_a,
         data_b => data_data,
         byteena_a => data_be_a,
         wren_a => data_we_a(i),
         wren_b => data_we(i)
      );

      sdata_en: if(DEBUG_SDATA) generate
         sdata: altsyncram generic map(
            WIDTH_A => 32,
            WIDTHAD_A => OFFSET_BITS + REFILL_BLOCK_BITS,
            WIDTH_B => 32,
            WIDTHAD_B => OFFSET_BITS + REFILL_BLOCK_BITS
         )
         port map(
            clock0 => clock,
            clock1 => data_clk_b,
            address_a => data_addr_a(data_addr_a'high downto RBLKL - CBLKL),
            addressstall_a => data_as_a,
            address_b => data_addr(OFFH downto RBLKL),
            addressstall_b => data_as,
            q_a => sdata_q_a(i),
            q_b => sdata_q_b(i),
            data_b => sdata_data,
            wren_b => data_we(i)
         );
      end generate;
   end generate;

   ddr_clock: if(CLOCK_DOUBLING) generate
      data_clk_b <= dclock;
   end generate;
   sdr_clock: if(not CLOCK_DOUBLING) generate
      data_clk_b <= clock;
   end generate;

   -- minimum state for tag match to be considered a hit
   -- we need MODIFIED when writing and only SHARED when reading. this covers
   -- everything but ll/sc. the ll/sc stuff uses a bit of black magic which
   -- deserves a thorough comment:
   --
   -- to implement ll/sc, we require the line in MODIFIED state during the ll.
   -- this trick allows us to implement sc very cheaply, without direct snoop
   -- monitoring, and without some icky timing issues (tag cross-port latency).
   -- on sc, we flag a failure if the operation is not a hit. the pipeline will
   -- abort the transaction immediately; this will inhibit the store since the
   -- pipeline asserts c_kill when sc fails.
   --
   -- this works because, if another CPU is running a similar ll/sc pair
   -- (or even a non-sc store) to the same cacheline, we are going to get the
   -- line stolen by a snoop; the line will then be in INVALID so our
   -- subsequent sc fails correctly.
   --
   -- this all relies on one key assumption: no other cache operations should
   -- be issued between an ll/sc pair, or the sc might not behave as intended.
   -- however, the R4K manual states exactly this so we should be in the clear.
   -- to be safe, we add checking logic and force sc to fail if that assumption
   -- is violated.
   miss_minstate <=  T_STATE_MODIFIED when c_req(1).wr = '1' else
                     T_STATE_MODIFIED when c_req(1).ll = '1' else -- tricky.
                     T_STATE_SHARED;
   
   restart_gen: if(EARLY_RESTART) generate
      restart: entity work.z48cc_restart generic map(
         WAYS => WAYS,
         WAY_BITS => WAY_BITS,
         RBLKL => RBLKL,
         RBLKH => RBLKH,
         OFFL => OFFL,
         OFFH => OFFH,
         TAGL => TAGL,
         TAGH => TAGH
      )
      port map(
         clock => clock,
         rst => rst,

         mshr_addr => cc_mshr_addr,
         mshr_valid => cc_mshr_valid,
         mshr_insstate => cc_mshr_insstate,

         miss_addr => miss_addr,
         miss_valid => miss_valid,
         miss_minstate => miss_minstate,

         l1_way_mask => tag_oe,

         l1_data_addr => data_addr,
         l1_data_as => data_as,
         l1_u_data_we => data_we,

         l1_u_tag_we => tag_we,

         restart_way => restart_way,
         restart_ok => restart_ok
      );
   end generate;
   no_restart: if(not EARLY_RESTART) generate
      restart_way <= (others => '-');
      restart_ok <= '0';
   end generate;

   tag_comparators: process(c_req(1), tag_q_a, miss_minstate, restart_way, restart_ok) is begin
      miss_curstate <= T_STATE_INVALID;
      hit <= '0';
      miss <= '1';
      c_req(1).way <= 0;
      hit_vec <= (others => '0');
      emptyway <= (others => '0');
      have_emptyway <= '0';

      -- early restart stuff
      if(restart_ok = '1') then
         hit <= '1';
         miss <= '0';
         c_req(1).way <= int(restart_way);
         hit_vec(int(restart_way)) <= '1';
      end if;

      -- normal tag search
      for i in 0 to WAYS - 1 loop
         if(tag_q_a(i)(T_TAG_H downto T_TAG_L) = c_req(1).paddr(TAGH downto TAGL) and cache_state_unlock(tag_q_a(i)(T_STATE_H downto T_STATE_L)) /= T_STATE_INVALID) then
            miss_curstate <= tag_q_a(i)(T_STATE_H downto T_STATE_L);
            c_req(1).way <= i;
            if(cache_state_test_access_ok(tag_q_a(i)(T_STATE_H downto T_STATE_L), miss_minstate)) then
               hit <= '1';
               miss <= '0';
               hit_vec(i) <= '1';
            end if;
         end if;
      end loop;

      -- empty way detection
      for i in 0 to WAYS - 1 loop
         if(cache_state_unlock(tag_q_a(i)(T_STATE_H downto T_STATE_L)) = T_STATE_INVALID) then
            emptyway <= vec(i, emptyway'length);
            have_emptyway <= '1';
         end if;
      end loop;
   end process;
   miss_way <=
      vec(c_req(1).way, miss_way'length) when cache_state_unlock(miss_curstate) /= T_STATE_INVALID else
      emptyway when have_emptyway = '1' else
      victimway;

   turnaround_stall <=
      '0' when LATENCY > 1 else
      '0' when c_kill = '1' else
      '1' when c_req(2).wr = '1' and c_req(1).rd = '1' else
      '0';
   c_halt <=
      ((c_req(1).rd or c_req(1).wr) and not c_kill and (
         (tlb_stall) or
         (not c_req(1).cacheable and c_req(1).rd and not (u_valid and not u_aborted)) or
         (not c_req(1).cacheable and c_req(1).wr and not (u_issued and not u_halt_r)) or
         (c_req(1).cacheable and miss) or
         (cc_init_wait) or
         (c_req(1).sync and not cc_synched)
      )) or
      (c_req(1).inv and tlb_stall and not c_kill) or
      turnaround_stall;

   req_issue <=
      (c_req(1).rd or c_req(1).wr) and not c_kill and tlb_mapped and (
         (not c_req(1).cacheable and not u_issued) or
         (c_req(1).cacheable and miss)
      );
   miss_addr <= c_req(1).paddr;
   miss_valid <= c_req(1).cacheable and req_issue;

   uncached_driver: process(clock) is begin
      if(rising_edge(clock)) then
         u_halt_r <= (u_rd or u_wr) and u_halt;
         if(u_halt = '0') then
            u_rd <= '0';
            u_wr <= '0';
         end if;
         if(c_halt = '0') then
            u_issued <= '0';
         end if;
         if(c_kill = '1' and u_issued = '1') then
            u_aborted <= '1';
         end if;
         if(u_valid = '1') then
            u_aborted <= '0';
         end if;

         if(c_req(1).cacheable = '0' and req_issue = '1' and u_halt = '0') then
            u_addr <= c_req(1).paddr;
            u_rd <= c_req(1).rd;
            u_wr <= c_req(1).wr;
            u_out <= c_req(1).data_in;
            u_be <= c_req(1).be;
            u_issued <= '1';
            u_halt_r <= c_req(1).wr;
         end if;

         if(rst = '1') then
            u_rd <= '0';
            u_wr <= '0';
            u_issued <= '0';
            u_aborted <= '0';
            u_halt_r <= '0';
         end if;
      end if;
   end process;

   c_req(1).ucdata <= u_in;
   c_out <= c_req(LATENCY).ucdata when c_req(LATENCY).cacheable = '0' else
            data_q_a(c_req(LATENCY).way);

   refill_regs: process(clock) is begin
      if(rising_edge(clock)) then
         if(tag_as = '0') then
            tag_addr_r <= tag_addr;
         end if;
         if(stag_as = '0') then
            stag_addr_r <= stag_addr;
         end if;
      end if;
   end process;
   tris_drivers: for i in 0 to WAYS - 1 generate
      tag_q <= tag_q_b(i) & tag_addr_r(OFFH downto RBL) when tag_oe(i) = '1' else (others => 'Z');
      data_q <= data_q_b(i) when data_oe(i) = '1' else (others => 'Z');
      sdata_q <= sdata_q_b(i) when data_oe(i) = '1' else (others => 'Z');
   end generate;
   refill_tag_comparators: process(tag_q_b, tag_addr_r, tag_data, stag_q_b, stag_addr_r, stag_data) is begin
      tag_match <= (others => '0');
      tag_dirty <= (others => '0');
      stag_match <= (others => '0');
      stag_excl <= (others => '0');
      for i in tag_q_b'range loop
         if((tag_q_b(i)(T_TAG_H downto T_TAG_L) & tag_addr_r(OFFH downto OFFL) = tag_data(TAGH downto OFFL)) and cache_state_test_at_least(tag_q_b(i)(T_STATE_H downto T_STATE_L), T_STATE_SHARED)) then
            tag_match(i) <= '1';
         end if;
         if(cache_state_test_at_least(tag_q_b(i)(T_STATE_H downto T_STATE_L), T_STATE_MODIFIED)) then
            tag_dirty(i) <= '1';
         end if;

         if((stag_q_b(i)(T_TAG_H downto T_TAG_L) & stag_addr_r(OFFH downto OFFL) = stag_data(TAGH downto OFFL)) and cache_state_test_at_least(stag_q_b(i)(T_STATE_H downto T_STATE_L), T_STATE_SHARED)) then
            stag_match(i) <= '1';
         end if;
         if(cache_state_test_at_least(stag_q_b(i)(T_STATE_H downto T_STATE_L), T_STATE_EXCLUSIVE)) then
            stag_excl(i) <= '1';
         end if;
      end loop;
   end process;

   c_req(1).valid <= c_req(1).rd and tlb_mapped and (
      (not tlb_cacheable and u_valid) or
      (tlb_cacheable and hit)
   ) and not turnaround_stall;
   c_req(1).invalid <= tlb_fault and not c_kill;

   c_scok <=
      '0' when c_req(1).wr = '0' else
      '0' when c_req(1).sc = '0' else
      '0' when tlb_mapped = '0' else
      '0' when LLlocal = '0' else
      '0' when c_req(1).paddr /= LLaddr else
      '1' when tlb_cacheable = '0' else -- sc to uncached mapping always succ.
      hit;

   c_addrout <= c_req(LATENCY).vaddr;
   c_valid <= c_req(LATENCY).valid;
   c_invalid <= c_req(LATENCY).invalid;

   replace: entity work.l1_replace generic map(
      OFFSET_BITS => OFFSET_BITS,
      WAY_BITS => WAY_BITS,
      WAYS => WAYS,
      REPLACE_TYPE => REPLACE_TYPE,
      SUB_REPLACE_TYPE => SUB_REPLACE_TYPE,
      BLOCK_FACTOR => HYBRID_BLOCK_FACTOR
   )
   port map(
      clock => clock,
      rst => rst,

      ref_addr => c_req(1).vaddr(OFFH downto OFFL),
      ref_way => vec(c_req(1).way, WAY_BITS),
      ref_valid => (c_req(1).rd or c_req(1).wr) and tlb_cacheable and hit and not c_halt,

      fill_addr => c_req(1).vaddr(OFFH downto OFFL),
      fill_way => victimway
   );

   LLtrack: process(clock) is begin
      if(rising_edge(clock)) then
         if((c_req(1).rd = '1' or c_req(1).wr = '1') and c_kill = '0') then
            LLlocal <= '0';
         end if;
         if(c_req(1).ll = '1' and c_kill = '0') then
            LLlocal <= '1';
            LLaddr <= c_req(1).paddr;
         end if;
         if(rst = '1') then
            LLlocal <= '0';
         end if;
      end if;
   end process;

   c_sout <= sdata_q_a(c_req(LATENCY).way);
   check: process(clock) is begin
      if(rising_edge(clock)) then
         if(
            DEBUG_SDATA and                           -- sdata debugging on,
            (
               c_req(LATENCY).rd = '1' or
               (c_req(LATENCY).wr = '1' and LATENCY > 1)
            ) and                                     -- read/write req,
            c_req(LATENCY).cacheable = '1' and        -- cacheable,
            compare_ne(
               c_sout(TAGH downto RBLKL),
               c_req(LATENCY).paddr(TAGH downto RBLKL)
            ) and                                     -- sdata mismatched
            (
               LATENCY > 1 or
               (c_kill = '0' and c_halt = '0')
            )                                         -- req completed
         ) then
            mce <= '1';
         end if;

         if(rst = '1') then
            mce <= '0';
         end if;
      end if;
   end process;

   perf_req <= (c_req(1).rd or c_req(1).wr) and not c_halt and not c_kill and tlb_cacheable;
   perf_stall <= c_halt;
   perf_hit <= tlb_cacheable and (c_req(1).rd or c_req(1).wr) and hit and not c_kill;
   perf_miss_stall <= (c_req(1).rd or c_req(1).wr) and tlb_mapped and tlb_cacheable and miss;
   perf_promote_miss_stall <= perf_miss_stall when cache_state_unlock(miss_curstate) /= T_STATE_INVALID else '0';
   perf_tlb_stall <= tlb_stall;
   perf_sc_success <= c_req(1).wr and c_req(1).sc and not c_halt and not c_kill;
   perf_sc_failure <= c_req(1).wr and c_req(1).sc and not c_halt and not c_scok;
   perf_sc_flushed <= c_req(1).wr and c_req(1).sc and not c_halt and c_kill;
   perf_turnaround_stall <= turnaround_stall;
   perf_inv_tlb_fault <= c_req(1).inv and tlb_fault;
end architecture;
