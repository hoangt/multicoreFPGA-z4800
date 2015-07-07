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

entity z48cc is
   generic(
      CLOCK_DOUBLING:               boolean;
      WIDTH:                        natural;
      BLOCK_BITS:                   natural;
      CRITICAL_WORD_FIRST:          boolean;
      L1_OFFSET_BITS:               natural;
      L1_WAYS:                      natural;
      L2_OFFSET_BITS:               natural;
      L2_WAYS:                      natural;
      L2_REPLACE_TYPE:              string;
      L2_SUB_REPLACE_TYPE:          string;
      L2_HYBRID_BLOCK_FACTOR:       natural;
      ENABLE_SNOOPING:              boolean;
      DEBUG_SDATA:                  boolean;
      NO_WRITEBACK_SNOOPING:        boolean := false;
      HACK_NO_AUTOPROMOTE:          boolean := false;
      PARANOID:                     boolean := true
   );
   port(
      clock:                        in std_logic;
      dclock:                       in std_logic;
      rst:                          in std_logic;

      init:                         buffer std_logic;
      synched:                      out std_logic;

      l1_miss_addr:                 in word;
      l1_miss_valid:                in std_logic;
      l1_miss_minstate:             in cache_state_t;
      l1_miss_curstate:             in cache_state_t;
      l1_miss_way:                  in std_logic_vector(log2c(L1_WAYS) - 1 downto 0);
      l1_hint_share:                in std_logic;

      mshr_addr:                    out word;
      mshr_valid:                   out std_logic;
      mshr_insstate:                out cache_state_t;

      l1_tag_addr:                  buffer word;
      l1_way_mask:                  buffer std_logic_vector(L1_WAYS - 1 downto 0);
      l1_tag_as:                    buffer std_logic;
      l1_data_addr:                 out word;
      l1_data_as:                   out std_logic;
      l1_stag_addr:                 buffer word;
      l1_stag_as:                   buffer std_logic;

      l1_u_data:                    out std_logic_vector(WIDTH - 1 downto 0);
      l1_u_data_we:                 out std_logic_vector(L1_WAYS - 1 downto 0);
      l1_u_tag:                     out std_logic_vector(CACHE_STATE_BITS + 32 - 1 downto 0);
      l1_u_tag_we:                  out std_logic_vector(L1_WAYS - 1 downto 0);
      l1_u_sdata:                   out word;
      l1_u_stag:                    out std_logic_vector(CACHE_STATE_BITS + 32 - 1 downto 0);
   
      l1_d_data:                    in std_logic_vector(WIDTH - 1 downto 0);
      l1_d_tag:                     in std_logic_vector(CACHE_STATE_BITS + 32 - 1 downto 0);
      l1_d_tag_match:               in std_logic_vector(L1_WAYS - 1 downto 0);
      l1_d_tag_dirty:               in std_logic_vector(L1_WAYS - 1 downto 0);
      l1_d_sdata:                   in word;
      l1_d_stag_match:              in std_logic_vector(L1_WAYS - 1 downto 0);
      l1_d_stag_excl:               in std_logic_vector(L1_WAYS - 1 downto 0);

      inv:                          in std_logic;
      invaddr:                      in word;
      invop:                        in std_logic_vector(2 downto 0);
      invdone:                      out std_logic;

      m_addr:                       buffer word;
      m_out:                        out std_logic_vector(WIDTH - 1 downto 0);
      m_burstcount:                 out std_logic_vector(BLOCK_BITS downto 0);
      m_rd:                         buffer std_logic;
      m_wr:                         buffer std_logic;

      m_halt:                       in std_logic;
      m_valid:                      in std_logic;
      m_in:                         in std_logic_vector(WIDTH - 1 downto 0);

      s_bus_reqn:                   buffer std_logic;
      s_bus_gntn:                   in std_logic;
      s_bus_r_addr_oe:              out std_logic;
      s_bus_r_addr_out:             out word;
      s_bus_r_addr:                 in word;
      s_bus_r_sharen_oe:            buffer std_logic;
      s_bus_r_sharen:               in std_logic;
      s_bus_r_excln_oe:             buffer std_logic;
      s_bus_r_excln:                in std_logic;
      s_bus_a_waitn_oe:             out std_logic;
      s_bus_a_waitn:                in std_logic;
      s_bus_a_ackn_oe:              out std_logic;
      s_bus_a_ackn:                 in std_logic;
      s_bus_a_sharen_oe:            out std_logic;
      s_bus_a_sharen:               in std_logic;
      s_bus_a_excln_oe:             out std_logic;
      s_bus_a_excln:                in std_logic;

      perf_miss:                    out std_logic;
      perf_fill_miss:               out std_logic;
      perf_promote_miss:            out std_logic;
      perf_dirty:                   out std_logic;
      perf_fill_excl:               out std_logic;
      perf_wb:                      out std_logic;
      perf_l2_hit:                  out std_logic;
      perf_l2_miss:                 out std_logic;
      perf_lsnoop_arbit:            out std_logic;
      perf_lsnoop_wait:             out std_logic;
      perf_rsnoop:                  out std_logic;
      perf_rsnoop_S:                out std_logic;
      perf_rsnoop_E:                out std_logic;
      perf_reenter:                 out std_logic;
      perf_unlock:                  out std_logic;
      perf_l2_alias:                out std_logic;
      perf_l2_nonalias:             out std_logic;

      mce:                          buffer std_logic;
      mce_code:                     out std_logic_vector(5 downto 0)
   );
end entity;

architecture z48cc of z48cc is
   constant BYTES:                  natural := WIDTH / 8;
   constant BYTE_BITS:              natural := log2c(BYTES);
   constant L2_WAY_BITS:            natural := log2c(L2_WAYS);

   constant BL:                     natural := 0;
   constant BH:                     natural := BL + BYTE_BITS - 1;
   constant BLKL:                   natural := BH + 1;
   constant BLKH:                   natural := BLKL + BLOCK_BITS - 1;
   constant L1_OFFL:                natural := BLKH + 1;
   constant L1_OFFH:                natural := L1_OFFL + L1_OFFSET_BITS - 1;

   constant L1_T_TAGL:              natural := BLKH + 1;
   constant L1_T_TAGH:              natural := 31;
   constant L1_T_STATEL:            natural := L1_T_TAGH + 1;
   constant L1_T_STATEH:            natural := L1_T_STATEL + CACHE_STATE_BITS - 1;

   constant VOFFL:                  natural := BLKH + 1;
   constant VOFFH:                  natural := VOFFL + L2_OFFSET_BITS - 1;
   constant VTAGL:                  natural := VOFFH + 1;
   constant VTAGH:                  natural := 31;
   constant VWAYL:                  natural := VOFFH + 1;
   constant VWAYH:                  natural := VWAYL + L2_WAY_BITS - 1;

   constant L2_TAG_BITS:            natural := 32 - L2_OFFSET_BITS - BLOCK_BITS - BYTE_BITS;

   constant L2_T_TAGL:              natural := 0;
   constant L2_T_TAGH:              natural := L2_T_TAGL + L2_TAG_BITS - 1;
   constant L2_T_STATEL:            natural := L2_T_TAGH + 1;
   constant L2_T_STATEH:            natural := L2_T_STATEL + CACHE_STATE_BITS - 1;
   constant L2_T_BITS:              natural := CACHE_STATE_BITS + L2_TAG_BITS;

   signal l1_miss_addr_a:           word;
   type mshr_t is record
      valid:                        std_logic;
      snooped:                      std_logic;
      hint_share:                   std_logic;
      addr:                         word;
      oldaddr:                      word;
      curstate:                     cache_state_t;
      minstate:                     cache_state_t;
      insstate:                     cache_state_t;
      oldstate:                     cache_state_t;
      l2hit:                        std_logic;
      l2state:                      cache_state_t;
      l2_needs_victim:              std_logic;
   end record;
   signal mshr:                     mshr_t;
   signal l1_tag_use_miss, l2_tag_use_miss: std_logic;

   type bus_t is record
      data:                         std_logic_vector(WIDTH - 1 downto 0);
      active:                       std_logic;
      valid:                        std_logic;
      ready:                        std_logic;
      transfer:                     std_logic;
      transfer_r:                   std_logic;
      stall:                        std_logic;
   end record;
   signal ubus, dbus:               bus_t;
   signal subus, sdbus:             bus_t;

   signal l1_bus_addr:              word;
   signal l2_bus_rd_addr, l2_bus_wr_addr: word;

   signal ubus_m_oe:                std_logic;
   signal ubus_l1_we:               std_logic;

   signal dbus_l1_oe:               std_logic;
   signal dbus_m_we:                std_logic;

   type transfer_t is record
      remaining:                    integer range 0 to (2 ** BLOCK_BITS) - 1;
      dbus:                         std_logic;
      ubus:                         std_logic;
      run:                          std_logic;
   end record;
   signal transfer:                 transfer_t;

   signal mufifo_empty, mufifo_full: std_logic;
   signal mufifo_rd, mufifo_wr:     std_logic;
   signal mufifo_in, mufifo_out:    std_logic_vector(WIDTH - 1 downto 0);
   signal mufifo_rst:               std_logic;
   signal musfifo_in, musfifo_out:  word;

   signal dmfifo_empty, dmfifo_full: std_logic;
   signal dmfifo_rd, dmfifo_wr:     std_logic;
   signal dmfifo_in, dmfifo_out:    std_logic_vector(WIDTH - 1 downto 0);
   signal dmfifo_rst:               std_logic;

   signal tag_addr_cc:              word;
   signal explicit_inv:             std_logic;
   signal inv_final_state:          cache_state_t;

   signal phase:                    std_logic;
   signal Dphase, Uphase, Wphase:   std_logic;
   signal idle:                     std_logic;

   signal suaddr, sdaddr:           word;

   function align_addr(addr: word) return std_logic_vector is
      variable ret:                 word;
   begin
      ret := addr;
      ret(BH downto BL) := (others => '0');
      if(not CRITICAL_WORD_FIRST) then
         ret(BLKH downto BLKL) := (others => '0');
      end if;
      return ret;
   end function;

   signal l2_tag_addr_a, l2_tag_addr_b: word;
   signal l2_tag_as_a, l2_tag_as_b: std_logic;
   signal l2_hitvec_a, l2_hitvec_b: std_logic_vector(L2_WAYS - 1 downto 0);
   signal l2_hitway_a, l2_hitway_b: std_logic_vector(L2_WAY_BITS - 1 downto 0);
   signal l2_hit_a, l2_hit_b:       std_logic;
   signal l2_state_a, l2_state_b:   cache_state_t;
   signal l2_have_empty_way:        std_logic;
   signal l2_empty_way:             std_logic_vector(L2_WAY_BITS - 1 downto 0);

   signal l2_tag_data_a, l2_tag_data_b: std_logic_vector(L2_T_BITS - 1 downto 0);
   type l2_tag_a_t is array(L2_WAYS - 1 downto 0) of std_logic_vector(L2_T_BITS - 1 downto 0);
   signal l2_tag_q_a, l2_tag_q_b:   l2_tag_a_t;
   signal l2_tag_we_a:              std_logic_vector(L2_WAYS - 1 downto 0);

   signal ubus_l2_oe, dbus_l2_we:   std_logic;
   signal l2_clock:                 std_logic;
   signal l2_replaceway:            std_logic_vector(L2_WAY_BITS - 1 downto 0);
   signal l2_rdway, l2_wrway:       std_logic_vector(L2_WAY_BITS - 1 downto 0);
   signal l2_data_addr:             std_logic_vector(L2_WAY_BITS + L2_OFFSET_BITS + BLOCK_BITS - 1 downto 0);
   signal l2_data_as:               std_logic;
   signal l2_data_we:               std_logic;
   signal l2_data_q, l2_data_data:  std_logic_vector(WIDTH - 1 downto 0);
   signal l2_ref:                   std_logic;

   signal s_bus_r_addr_r:           word;
   signal s_bus_r_sharen_r:         std_logic;
   signal s_bus_r_excln_r:          std_logic;
   signal s_match:                  std_logic;
   signal s_match_excl:             std_logic;
   signal s_fifowait:               std_logic;
   signal s_active:                 std_logic;
   signal s_attn:                   std_logic;

   attribute direct_enable of s_bus_a_waitn: signal is true;
begin
   -- main L1 datapath
   ddr: if(CLOCK_DOUBLING) generate
      Dphase <= '1';
      Uphase <= '1';
      Wphase <= not clock;
      l1_data_addr <= l1_bus_addr;
      l1_data_as <= '0';

      mufifo_out <= m_in;
      mufifo_empty <= not m_valid;

      musfifo_out <= musfifo_in;
   end generate;
   sdr: if(not CLOCK_DOUBLING) generate
      Dphase <= not phase;
      Uphase <= phase;
      Wphase <= phase;
      l1_data_addr <= l1_bus_addr;
      l1_data_as <= '0';

      mufifo_in <= m_in;
      mufifo_wr <= m_valid;
      mufifo: entity work.fifo generic map(
         WIDTH => WIDTH,
         LENGTH => 2 ** BLOCK_BITS
      )
      port map(
         clock => clock,
         rst => mufifo_rst,
         empty => mufifo_empty,
         full => mufifo_full,
         read => mufifo_rd,
         write => mufifo_wr,
         d => mufifo_in,
         q => mufifo_out
      );
      mufifo_rd <= ubus_m_oe and ubus.transfer;

      musfifo_gen: if(DEBUG_SDATA) generate
         musfifo: entity work.fifo generic map(
            WIDTH => 32,
            LENGTH => 2 ** BLOCK_BITS
         )
         port map(
            clock => clock,
            rst => mufifo_rst,
            read => mufifo_rd,
            write => mufifo_wr,
            d => musfifo_in,
            q => musfifo_out
         );
      end generate;
   end generate;

   process(clock) is begin
      if(rising_edge(clock) and DEBUG_SDATA) then
         if(m_rd = '1' and m_halt = '0') then
            musfifo_in <= m_addr;
         end if;
         if(m_valid = '1') then
            musfifo_in(BLKH downto BLKL) <= musfifo_in(BLKH downto BLKL) + 1;
         end if;
      end if;
   end process;

   ubus.data <= mufifo_out when ubus_m_oe = '1' else (others => 'Z');
   ubus.valid <= (not mufifo_empty and ubus_m_oe) or ubus_l2_oe;
   ubus.ready <= ubus_l1_we;
   ubus.transfer <= ubus.active and Uphase and ubus.ready and ubus.valid;
   ubus.stall <= ubus.active and not ubus.transfer;
   l1_u_data <= ubus.data;
   l1_u_data_we <= (l1_u_data_we'range => (Wphase and ubus_l1_we and ubus.transfer)) and l1_way_mask;
   l1_u_sdata <= musfifo_out when ubus_m_oe = '1' else suaddr;

   dbus.data <= l1_d_data when dbus_l1_oe = '1' else (others => 'Z');
   dbus.valid <= dbus_l1_oe;
   dbus.ready <= dbus_m_we or dbus_l2_we;
   dbus.transfer <= dbus.active and Dphase and dbus.ready and dbus.valid;
   dbus.stall <= dbus.active and not dbus.transfer;

   dmfifo_in <= dbus.data;
   dmfifo_wr <=   dbus_m_we and dbus.transfer when CLOCK_DOUBLING else
                  dbus_m_we and dbus.transfer_r;
   dmfifo: entity work.fifo generic map(
      WIDTH => WIDTH,
      LENGTH => 2 ** BLOCK_BITS
   )
   port map(
      clock => clock,
      rst => dmfifo_rst,
      empty => dmfifo_empty,
      full => dmfifo_full,
      read => dmfifo_rd,
      write => dmfifo_wr,
      d => dmfifo_in,
      q => dmfifo_out
   );
   dmfifo_rd <= m_wr and not m_halt;
   m_out <= dmfifo_out;
   m_wr <= not dmfifo_empty;

   l1_tag_addr <= align_addr(tag_addr_cc) when l1_tag_use_miss = '0' else
                  align_addr(invaddr) when inv = '1' else
                  align_addr(l1_miss_addr);
   l1_miss_addr_a <= align_addr(l1_miss_addr);

   -- L1/L2 state machine
   process(clock) is
      type state_t is (s_idle, s_miss1, s_miss2, s_miss3, s_miss4, s_miss5, s_lsnoop_promote1, s_lsnoop_promote2, s_lsnoop_promote3, s_lsnoop_miss1, s_lsnoop_miss2, s_lsnoop_miss3, s_inv0, s_inv1, s_inv2, s_inv3, s_inv4, s_inv5, s_inv6, s_inv7, s_return1, s_return2, s_reset1, s_reset2, s_reset3, s_bug);
      variable state:               state_t;

      procedure assert_bus is begin
         dbus.active <= transfer.dbus;
         ubus.active <= transfer.ubus;
      end procedure;
      procedure negate_bus is begin
         dbus_l1_oe <= '0';
         dbus_m_we <= '0';
         dbus_l2_we <= '0';
         dbus.active <= '0';
         transfer.dbus <= '0';
         ubus_m_oe <= '0';
         ubus_l2_oe <= '0';
         ubus_l1_we <= '0';
         ubus.active <= '0';
         transfer.ubus <= '0';
      end procedure;
      procedure start_transfer is begin
         transfer.remaining <= transfer.remaining'high;
         phase <= '0';
         transfer.run <= '1';
      end procedure;

      variable loff:                std_logic_vector(L1_OFFSET_BITS - 1 downto 0);
      variable voff:                std_logic_vector(L2_OFFSET_BITS - 1 downto 0);
      type invact_t is (i_none, i_idx_wb_inv, i_hit_inv, i_hit_wb, i_hit_wb_shar, i_hit_wb_inv);
      variable invact:              invact_t;

      procedure handle_s_attn is begin
         mshr.valid <= '0';
         explicit_inv <= '0';
         tag_addr_cc <= align_addr(s_bus_r_addr_r);
         l1_tag_use_miss <= '0';
         l2_tag_use_miss <= '0';
         l1_tag_as <= '0';
         l2_tag_as_a <= '0';
         l1_u_tag(L1_T_TAGH downto BL) <= align_addr(s_bus_r_addr_r);
         l2_tag_data_a(L2_T_TAGH downto L2_T_TAGL) <= s_bus_r_addr_r(VTAGH downto VTAGL);
         perf_rsnoop <= '1';
         if(s_bus_r_excln_r = '0') then
            perf_rsnoop_E <= '1';
            invact := i_hit_wb_inv;
         else
            perf_rsnoop_S <= '1';
            invact := i_hit_wb_shar;
         end if;
         state := s_inv0;
      end procedure;
      procedure trigger_writeback(i: integer range 0 to L1_WAYS - 1) is begin
         invdone <= '0';
         l1_way_mask <= (others => '0');
         l1_way_mask(i) <= '1';
         l1_u_tag(L1_T_STATEH downto L1_T_STATEL) <= T_STATE_EXCLUSIVE;
         l1_u_tag_we <= (others => '0');
         state := s_inv2;
      end procedure;
      procedure handle_snoop_ack is begin
      end procedure;
   begin
      if(rising_edge(clock)) then
         perf_miss <= '0';
         perf_fill_miss <= '0';
         perf_promote_miss <= '0';
         perf_dirty <= '0';
         perf_fill_excl <= '0';
         perf_wb <= '0';
         perf_l2_hit <= '0';
         perf_l2_miss <= '0';
         perf_lsnoop_arbit <= '0';
         perf_lsnoop_wait <= '0';
         perf_rsnoop <= '0';
         perf_rsnoop_S <= '0';
         perf_rsnoop_E <= '0';
         perf_reenter <= '0';
         perf_unlock <= '0';
         perf_l2_alias <= '0';
         perf_l2_nonalias <= '0';

         if(s_bus_a_waitn = '1') then
            s_bus_r_addr_oe <= '0';
            s_bus_r_sharen_oe <= '0';
            s_bus_r_excln_oe <= '0';
         end if;
         invdone <= '0';
         mufifo_rst <= '0';
         dmfifo_rst <= '0';
         if(m_halt = '0') then
            m_rd <= '0';
         end if;
         l1_u_tag_we <= (others => '0');
         l2_ref <= '0';
         l2_tag_we_a <= (others => '0');

         if(phase = '0' and dbus.stall = '0') then
            phase <= '1';
         elsif(phase = '1' and ubus.stall = '0') then
            phase <= '0';
         end if;

         if((CLOCK_DOUBLING and dbus.transfer = '1') or
            (not CLOCK_DOUBLING and dbus.transfer_r = '1')) then
            sdaddr(BLKH downto BLKL) <= sdaddr(BLKH downto BLKL) + 1;
         end if;
         if(ubus.transfer = '1') then
            suaddr(BLKH downto BLKL) <= suaddr(BLKH downto BLKL) + 1;
         end if;

         dbus.transfer_r <= dbus.transfer;
         ubus.transfer_r <= ubus.transfer;

         if(transfer.run = '1') then
            if(dbus.stall = '0' and ubus.stall = '0') then
               l1_bus_addr(BLKH downto BLKL) <= l1_bus_addr(BLKH downto BLKL) + 1;
               l2_bus_rd_addr(BLKH downto BLKL) <= l2_bus_rd_addr(BLKH downto BLKL) + 1;
               l2_bus_wr_addr(BLKH downto BLKL) <= l2_bus_wr_addr(BLKH downto BLKL) + 1;
               if(transfer.remaining > 0) then
                  assert_bus;
               else
                  negate_bus;
                  transfer.run <= '0';
               end if;
               transfer.remaining <= transfer.remaining - 1;
            else
               if(dbus.transfer = '1') then
                  dbus.active <= '0';
               end if;
               if(ubus.transfer = '1') then
                  ubus.active <= '0';
               end if;
            end if;
         end if;

         case state is
            when s_idle =>
               mshr.valid <= '0';
               mshr.snooped <= '0';
               explicit_inv <= '0';
               l1_tag_as <= '0';
               l2_tag_as_a <= '0';
               if(s_attn = '1') then
                  handle_s_attn;
               elsif(inv = '1' and dmfifo_empty = '1') then
                  l1_tag_as <= '1';
                  l2_tag_as_a <= '1';
                  explicit_inv <= '1';
                  l1_u_tag(L1_T_TAGH downto BL) <= align_addr(invaddr);
                  l2_tag_data_a(L2_T_TAGH downto L2_T_TAGL) <= invaddr(VTAGH downto VTAGL);
                  state := s_inv1;
                  case invop is
                     when "000" =>
                        invact := i_idx_wb_inv;
                     when "100" =>
                        invact := i_hit_inv;
                     when "101" =>
                        invact := i_hit_wb_inv;
                     when "110" =>
                        invact := i_hit_wb;
                     when others =>
                        state := s_bug;
                        mce_code <= "000010";
                  end case;
               elsif(l1_miss_valid = '1' and dmfifo_empty = '1') then
                  l1_tag_as <= '1';
                  l2_tag_as_a <= '1';
                  l1_way_mask <= (others => '0');
                  l1_way_mask(int(l1_miss_way)) <= '1';
                  mshr.valid <= '1';
                  mshr.hint_share <= l1_hint_share;
                  mshr.addr <= l1_miss_addr_a;
                  mshr.minstate <= l1_miss_minstate;
                  mshr.curstate <= cache_state_unlock(l1_miss_curstate);
                  mshr.insstate <= l1_miss_minstate;

                  l1_u_tag(L1_T_TAGH downto BL) <= l1_miss_addr_a;
                  l2_tag_data_a(L2_T_TAGH downto L2_T_TAGL) <= l1_miss_addr_a(VTAGH downto VTAGL);

                  state := s_miss1;
               end if;
               if(l1_miss_valid = '0') then
                  s_bus_reqn <= '1';
               end if;

            when s_miss1 =>
               perf_miss <= '1';
               s_bus_reqn <= '1'; -- probably overridden later in this state
               mshr.oldaddr <= l1_d_tag(L1_T_TAGH downto BL);
               mshr.oldstate <= cache_state_unlock(l1_d_tag(L1_T_STATEH downto L1_T_STATEL));

               if(PARANOID and any_bit_set(l1_d_tag_match) and l2_hit_a = '1') then
                  -- L2 exclusion violated
                  state := s_bug;
                  mce_code <= "000011";
               elsif(any_bit_set(l1_d_tag_match and not l1_way_mask)) then
                  -- cross-L1 coherence: maintain strict exclusion
                  invact := i_hit_wb_inv;
                  state := s_inv1;
               elsif(mshr.curstate /= T_STATE_INVALID) then
                  -- some type of promotion
                  perf_promote_miss <= '1';
                  if(mshr.minstate = T_STATE_MODIFIED) then
                     perf_dirty <= '1';
                  end if;
                  if(cache_state_test_less_than(mshr.curstate, mshr.minstate)) then
                     -- line needs actual promotion
                     l1_u_tag(L1_T_STATEH downto L1_T_STATEL) <= mshr.minstate;
                     if(PARANOID and cache_state_test_less_than(mshr.minstate, T_STATE_EXCLUSIVE)) then
                        -- we should never be promoting to < EXCLUSIVE
                        state := s_bug;
                        mce_code <= "000100";
                     else
                        if(ENABLE_SNOOPING and cache_state_test_less_than(mshr.curstate, T_STATE_EXCLUSIVE)) then
                           s_bus_reqn <= '0';
                           state := s_lsnoop_promote1;
                        else
                           l1_u_tag_we <= l1_way_mask;
                           state := s_return1;
                        end if;
                     end if;
                  else
                     -- we don't really need promotion; this should only
                     -- happen if the line is locked
                     perf_unlock <= '1';
                     if(PARANOID and not cache_state_test_locked(l1_d_tag(L1_T_STATEH downto L1_T_STATEL))) then
                        state := s_bug;
                        mce_code <= "000101";
                     else
                        l1_u_tag(L1_T_STATEH downto L1_T_STATEL) <= cache_state_unlock(l1_d_tag(L1_T_STATEH downto L1_T_STATEL));
                        l1_u_tag_we <= l1_way_mask;
                        state := s_return1;
                     end if;
                  end if;
                  if(PARANOID and (compare_ne(mshr.curstate, cache_state_unlock(l1_d_tag(L1_T_STATEH downto L1_T_STATEL))) or compare_ne(mshr.addr(L1_T_TAGH downto L1_OFFL), l1_d_tag(L1_T_TAGH downto L1_OFFL)))) then
                     -- something has gone very wrong...
                     state := s_bug;
                     mce_code <= "000110";
                  end if;
               else
                  -- refill
                  perf_fill_miss <= '1';

                  l1_bus_addr <= mshr.addr;
                  l2_bus_rd_addr <= mshr.addr;
                  l2_bus_wr_addr <= l1_d_tag(L1_T_TAGH downto BL);

                  l1_u_tag(L1_T_STATEH downto L1_T_STATEL) <= cache_state_lock(l1_d_tag(L1_T_STATEH downto L1_T_STATEL));
                  l1_u_tag(L1_T_TAGH downto BL) <= l1_d_tag(L1_T_TAGH downto BL);
                  l1_u_tag_we <= l1_way_mask;

                  if(cache_state_unlock(l1_d_tag(L1_T_STATEH downto L1_T_STATEL)) = T_STATE_MODIFIED) then
                     mshr.l2state <= T_STATE_EXCLUSIVE;
                  else
                     mshr.l2state <= cache_state_unlock(l1_d_tag(L1_T_STATEH downto L1_T_STATEL));
                  end if;

                  mshr.l2hit <= l2_hit_a;
                  if(l2_hit_a = '1') then
                     -- L2 hit, refill from L2
                     ubus_l2_oe <= '1';
                     ubus_m_oe <= '0';
                     mshr.snooped <= '1';

                     -- we can directly promote exclusive lines from L2
                     -- on a write-miss; otherwise, use L2 state
                     if(mshr.minstate = T_STATE_MODIFIED and l2_state_a = T_STATE_EXCLUSIVE) then
                        mshr.insstate <= T_STATE_MODIFIED;
                     else
                        mshr.insstate <= l2_state_a;
                     end if;

                     l2_rdway <= l2_hitway_a;

                     -- invalidate line being read from L2 (exclusion)
                     -- mshr will guard against concurrent snoops
                     l2_tag_data_a(L2_T_STATEH downto L2_T_STATEL) <= T_STATE_INVALID;
                     if(L2_WAYS > 0) then
                        l2_tag_we_a(int(l2_hitway_a)) <= '1';
                     end if;

                     state := s_miss2;
                     perf_l2_hit <= '1';
                  else
                     -- L2 miss, refill from memory
                     ubus_m_oe <= '1';
                     ubus_l2_oe <= '0';

                     m_addr <= mshr.addr;

                     if(ENABLE_SNOOPING) then
                        s_bus_reqn <= '0';
                        state := s_lsnoop_miss1;
                     else
                        m_rd <= '1';
                        state := s_miss2;
                     end if;
                     perf_l2_miss <= '1';
                  end if;
               end if;

            when s_miss2 =>
               tag_addr_cc <= mshr.oldaddr;
               l2_tag_use_miss <= '0';
               l2_tag_as_a <= '0';

               suaddr <= mshr.addr;
               sdaddr <= mshr.oldaddr;

               transfer.ubus <= '1';
               ubus_l1_we <= '1';

               if(mshr.oldstate /= T_STATE_INVALID) then
                  transfer.dbus <= '1';
                  dbus_l2_we <= '1';
               else
                  transfer.dbus <= '0';
                  dbus_l2_we <= '0';
               end if;
               dbus_l1_oe <= '1';
               if(mshr.oldstate = T_STATE_MODIFIED) then
                  dbus_m_we <= '1';
                  perf_wb <= '1';
               else
                  dbus_m_we <= '0';
               end if;
               if(L2_WAYS > 0 and L2_OFFSET_BITS > 0) then
                  if(mshr.l2hit = '1' and (mshr.addr(VOFFH downto VOFFL) = mshr.oldaddr(VOFFH downto VOFFL))) then
                     -- lines alias to same set in L2, replace L2-evicted way
                     mshr.l2_needs_victim <= '0';
                     l2_wrway <= l2_rdway;
                     state := s_miss4;
                     perf_l2_alias <= '1';
                  else
                     -- L2 miss or lines alias to different set in L2,
                     -- need to look for empty/victim way
                     mshr.l2_needs_victim <= '1';
                     state := s_miss3;
                     if(mshr.l2hit = '1') then
                        perf_l2_nonalias <= '1';
                     end if;
                  end if;
               else
                  -- no L2 at all
                  state := s_miss4;
               end if;

            when s_miss3 =>
               state := s_miss4;

            when s_miss4 =>
               if(mshr.l2_needs_victim = '1') then
                  if(l2_have_empty_way = '1') then
                     -- have an empty way, use it
                     l2_wrway <= l2_empty_way;
                  else
                     -- no empty ways, use replacement algo
                     l2_wrway <= l2_replaceway;
                  end if;
               end if;
               if(dbus_m_we = '0') then
                  assert_bus;
                  start_transfer;
                  state := s_miss5;
               elsif(m_halt = '0') then
                  m_addr <= mshr.oldaddr;
                  assert_bus;
                  start_transfer;
                  state := s_miss5;
               end if;

            when s_miss5 =>
               if(transfer.run = '0') then
                  l1_u_tag <= mshr.insstate & mshr.addr;
                  l1_u_tag_we <= l1_way_mask;

                  if(cache_state_test_at_least(mshr.insstate, T_STATE_EXCLUSIVE)) then
                     perf_fill_excl <= '1';
                  end if;

                  if(mshr.l2state /= T_STATE_INVALID) then
                     l2_tag_data_a <= mshr.l2state & mshr.oldaddr(VTAGH downto VTAGL);
                     l2_ref <= '1';
                     if(L2_WAYS > 0) then
                        l2_tag_we_a(int(l2_wrway)) <= '1';
                     end if;
                  end if;
                  state := s_return1;
               end if;

            when s_lsnoop_promote1 =>
               if(s_attn = '1') then
                  perf_reenter <= '1';
                  handle_s_attn;
               elsif(s_bus_gntn = '0' and s_bus_a_waitn = '1') then
                  s_bus_reqn <= '1';
                  s_bus_r_addr_oe <= '1';
                  s_bus_r_addr_out <= mshr.addr;
                  s_bus_r_sharen_oe <= '0';
                  s_bus_r_excln_oe <= '1';
                  state := s_lsnoop_promote2;
               else
                  perf_lsnoop_arbit <= '1';
               end if;

            when s_lsnoop_promote2 =>
               if(s_attn = '1') then
                  perf_reenter <= '1';
                  handle_s_attn;
               elsif(s_bus_a_waitn = '1') then
                  state := s_lsnoop_promote3;
               else
                  perf_lsnoop_wait <= '1';
               end if;

            when s_lsnoop_promote3 =>
               if(PARANOID and (s_active = '1' or s_attn = '1' or s_bus_a_ackn = '1' or s_bus_a_excln = '0')) then
                  state := s_bug;
                  mce_code <= "000111";
               elsif(s_bus_a_waitn = '1') then
                  l1_u_tag_we <= l1_way_mask;
                  mshr.snooped <= '1';
                  state := s_return1;
                  if(PARANOID and s_bus_a_sharen = '0') then
                     -- promotions mean we are going to EXCLUSIVE, so no other
                     -- CPU should still hold a shared copy...
                     state := s_bug;
                     mce_code <= "001000";
                  end if;
               else
                  perf_lsnoop_wait <= '1';
               end if;

            when s_lsnoop_miss1 =>
               if(s_attn = '1') then
                  perf_reenter <= '1';
                  handle_s_attn;
               elsif(s_bus_gntn = '0' and s_bus_a_waitn = '1') then
                  s_bus_reqn <= '1';
                  s_bus_r_addr_oe <= '1';
                  s_bus_r_addr_out <= mshr.addr;
                  if(cache_state_test_at_least(mshr.minstate, T_STATE_EXCLUSIVE)) then
                     s_bus_r_sharen_oe <= '0';
                     s_bus_r_excln_oe <= '1';
                  else
                     s_bus_r_sharen_oe <= '1';
                     s_bus_r_excln_oe <= '0';
                  end if;
                  state := s_lsnoop_miss2;
               end if;

            when s_lsnoop_miss2 =>
               if(s_attn = '1') then
                  perf_reenter <= '1';
                  handle_s_attn;
               elsif(s_bus_a_waitn = '1') then
                  state := s_lsnoop_miss3;
               end if;

            when s_lsnoop_miss3 =>
               if(PARANOID and (s_active = '1' or s_attn = '1' or s_bus_a_ackn = '1')) then
                  state := s_bug;
                  mce_code <= "001001";
               elsif(s_bus_a_waitn = '1') then
                  m_rd <= '1';
                  mshr.snooped <= '1';
                  if(not HACK_NO_AUTOPROMOTE and
                     cache_state_test_less_than(mshr.insstate, T_STATE_EXCLUSIVE) and
                     s_bus_a_sharen = '1' and
                     mshr.hint_share = '0') then
                     -- we have an exclusive copy, can autopromote our state
                     mshr.insstate <= T_STATE_EXCLUSIVE;
                  end if;
                  state := s_miss2;
                  if(PARANOID and (cache_state_test_at_least(mshr.insstate, T_STATE_EXCLUSIVE) and s_bus_a_sharen = '0')) then
                     -- we asked for an exclusive copy but other CPU holds a
                     -- shared copy...
                     state := s_bug;
                     mce_code <= "001010";
                  end if;
               end if;

            when s_inv0 =>
               l1_tag_as <= '1';
               l2_tag_as_a <= '1';
               state := s_inv1;

            when s_inv1 =>
               invdone <= explicit_inv;
               inv_final_state <= T_STATE_INVALID;
               l1_u_tag(L1_T_STATEH downto L1_T_STATEL) <= T_STATE_INVALID;
               l2_tag_data_a(L2_T_STATEH downto L2_T_STATEL) <= T_STATE_INVALID;
               if(invact = i_idx_wb_inv) then
                  l1_u_tag_we <= (others => '1');
                  l2_tag_we_a <= (others => '1');
                  state := s_return1;
                  for i in l1_d_tag_dirty'range loop
                     if(l1_d_tag_dirty(i) = '1') then
                        trigger_writeback(i);
                     end if;
                  end loop;
               elsif(invact = i_hit_wb_inv) then
                  l1_u_tag_we <= l1_d_tag_match;
                  l2_tag_we_a <= l2_hitvec_a;
                  state := s_return1;
                  for i in l1_d_tag_dirty'range loop
                     if(l1_d_tag_match(i) = '1' and l1_d_tag_dirty(i) = '1') then
                        trigger_writeback(i);
                     end if;
                  end loop;
               elsif(invact = i_hit_wb_shar) then
                  inv_final_state <= T_STATE_SHARED;
                  l1_u_tag(L1_T_STATEH downto L1_T_STATEL) <= T_STATE_SHARED;
                  l2_tag_data_a(L2_T_STATEH downto L2_T_STATEL) <= T_STATE_SHARED;
                  l1_u_tag_we <= l1_d_tag_match;
                  l2_tag_we_a <= l2_hitvec_a;
                  state := s_return1;
                  for i in l1_d_tag_dirty'range loop
                     if(l1_d_tag_match(i) = '1' and l1_d_tag_dirty(i) = '1') then
                        trigger_writeback(i);
                     end if;
                  end loop;
               elsif(invact = i_hit_wb) then
                  inv_final_state <= T_STATE_EXCLUSIVE;
                  state := s_return1;
                  for i in l1_d_tag_match'range loop
                     if(l1_d_tag_match(i) = '1' and l1_d_tag_dirty(i) = '1') then
                        trigger_writeback(i);
                     end if;
                  end loop;
               elsif(invact = i_hit_inv) then
                  l1_u_tag_we <= l1_d_tag_match;
                  l2_tag_we_a <= l2_hitvec_a;
                  state := s_return1;
               else
                  mce <= '1';
                  mce_code <= "001011";
                  state := s_bug;
               end if;

            when s_inv2 =>
               perf_wb <= '1';
               mshr.oldaddr <= l1_d_tag(L1_T_TAGH downto BL);
               l1_u_tag(L1_T_TAGH downto BL) <= l1_d_tag(L1_T_TAGH downto BL);
               l1_u_tag_we <= l1_way_mask;
               sdaddr <= l1_d_tag(L1_T_TAGH downto BL);
               l1_bus_addr <= l1_d_tag(L1_T_TAGH downto BL);
            
               transfer.ubus <= '0';
               transfer.dbus <= '1';
               dbus_l1_oe <= '1';
               dbus_l2_we <= '0';
               dbus_m_we <= '1';
               state := s_inv3;
               if(PARANOID and transfer.run = '1') then
                  state := s_bug;
                  mce_code <= "001100";
               end if;

            when s_inv3 =>
               state := s_inv4;

            when s_inv4 =>
               state := s_inv5;

            when s_inv5 =>
               if(dmfifo_empty = '1') then
                  m_addr <= l1_d_tag(L1_T_TAGH downto BL);
                  assert_bus;
                  start_transfer;
                  state := s_inv6;
               end if;

            when s_inv6 =>
               if(transfer.run = '0') then
                  l1_u_tag(L1_T_STATEH downto L1_T_STATEL) <= inv_final_state;
                  l1_u_tag_we <= l1_way_mask;
                  state := s_inv7;
               end if;

            when s_inv7 =>
               state := s_inv1;
            
            when s_return1 =>
               l1_tag_as <= '0';
               l2_tag_as_a <= '0';
               l1_tag_use_miss <= '1';
               l2_tag_use_miss <= '1';
               state := s_return2;

            when s_return2 =>
               mshr.valid <= '0';
               init <= '0';
               state := s_idle;

            when s_reset1 =>
               if(all_bits_set(loff)) then
                  state := s_reset2;
               end if;
               tag_addr_cc(L1_OFFH downto L1_OFFL) <= loff;
               loff := loff + 1;
               l1_u_tag_we <= (others => '1');
               mufifo_rst <= '1';
               dmfifo_rst <= '1';
            when s_reset2 =>
               if(L2_OFFSET_BITS > 0 and L2_WAYS > 0) then
                  state := s_reset3;
               else
                  state := s_return1;
               end if;
            when s_reset3 =>
               if(all_bits_set(voff)) then
                  state := s_return1;
               end if;
               tag_addr_cc(VOFFH downto VOFFL) <= voff;
               voff := voff + 1;
               l2_tag_we_a <= (others => '1');
            when others =>
               mce <= '1';
               state := s_bug;
         end case;

         if((DEBUG_SDATA and sdaddr /= l1_d_sdata) and (
               (CLOCK_DOUBLING and dbus.transfer = '1') or
               (not CLOCK_DOUBLING and dbus.transfer_r = '1')
            )) then
            mce <= '1';
            mce_code <= "000001";
            state := s_bug;
         end if;

         if(rst = '1') then
            mce <= '0';
            mce_code <= "000000";
            transfer.run <= '0';
            negate_bus;
            dbus.transfer_r <= '0';
            ubus.transfer_r <= '0';

            l1_u_tag(L1_T_STATEH downto L1_T_STATEL) <= T_STATE_INVALID;
            l1_tag_as <= '0';
            l2_tag_data_a(L2_T_STATEH downto L2_T_STATEL) <= T_STATE_INVALID;
            l2_tag_as_a <= '0';

            loff := (others => '0');
            voff := (others => '0');
            tag_addr_cc <= (others => '0');
            l1_tag_use_miss <= '0';
            l2_tag_use_miss <= '0';

            init <= '1';
            explicit_inv <= '0';
            mshr.valid <= '0';
            mshr.snooped <= '0';

            s_bus_reqn <= '1';
            s_bus_r_addr_oe <= '0';
            s_bus_r_sharen_oe <= '0';
            s_bus_r_excln_oe <= '0';

            state := s_reset1;
         end if;
         if(state = s_idle) then
            idle <= '1';
         else
            idle <= '0';
         end if;
      end if;
   end process;
   m_burstcount <= (m_burstcount'high => '1', others => '0');
   synched <= idle and dmfifo_empty;

   mshr_addr <= mshr.addr;
   mshr_valid <= mshr.valid;
   mshr_insstate <= mshr.insstate;

   -- L2 victim cache
   gen_l2: if(L2_OFFSET_BITS > 0 and L2_WAYS > 0) generate
      gen_l2_ways: for i in 0 to L2_WAYS - 1 generate
         l2_tags: altsyncram generic map(
            WIDTH_A => L2_T_BITS,
            WIDTHAD_A => L2_OFFSET_BITS,
            WIDTH_B => L2_T_BITS,
            WIDTHAD_B => L2_OFFSET_BITS
         )
         port map(
            clock0 => clock,
            clock1 => clock,
            address_a => l2_tag_addr_a(VOFFH downto VOFFL),
            addressstall_a => l2_tag_as_a,
            address_b => l2_tag_addr_b(VOFFH downto VOFFL),
            addressstall_b => l2_tag_as_b,
            q_a => l2_tag_q_a(i),
            q_b => l2_tag_q_b(i),
            data_a => l2_tag_data_a,
            wren_a => l2_tag_we_a(i)
         );
      end generate;
      l2_data: altsyncram generic map(
         WIDTH_A => WIDTH,
         WIDTHAD_A => L2_WAY_BITS + L2_OFFSET_BITS + BLOCK_BITS,
         NUMWORDS_A => L2_WAYS * (2 ** (L2_OFFSET_BITS + BLOCK_BITS)),
         OPERATION_MODE => "SINGLE_PORT"
      )
      port map(
         clock0 => l2_clock,
         address_a => l2_data_addr,
         addressstall_a => l2_data_as,
         q_a => l2_data_q,
         data_a => l2_data_data,
         wren_a => l2_data_we
      );

      l2_clock <= dclock when CLOCK_DOUBLING else clock;
      l2_data_as <= '0';
      l2_data_addr <=
         l2_rdway & l2_bus_rd_addr(VOFFH downto BLKL) when Wphase = '0' else
         l2_wrway & l2_bus_wr_addr(VOFFH downto BLKL);

      ubus.data <= l2_data_q when ubus_l2_oe = '1' else (others => 'Z');

      l2_data_data <= dbus.data;
      l2_data_we <= Wphase and dbus_l2_we and dbus.transfer;

      -- L2 tags are searched in parallel with L1 tags
      l2_tag_addr_a <=  align_addr(tag_addr_cc) when l2_tag_use_miss = '0' else
                        align_addr(invaddr) when inv = '1' else
                        align_addr(l1_miss_addr);
      l2_tag_addr_b <= l1_stag_addr;
      l2_tag_as_b <= l1_stag_as;
      l2_tag_data_b <= (CACHE_STATE_BITS - 1 downto 0 => '-') & s_bus_r_addr_r(VTAGH downto VTAGL);

      l2_find_empty_way: process(l2_tag_q_a) is begin
         l2_have_empty_way <= '0';
         l2_empty_way <= (others => '-');
         for i in 0 to L2_WAYS - 1 loop
            if(l2_tag_q_a(i)(L2_T_STATEH downto L2_T_STATEL) = T_STATE_INVALID) then
               l2_have_empty_way <= '1';
               l2_empty_way <= vec(i, L2_WAY_BITS);
            end if;
         end loop;
      end process;
      l2_tag_a_comparators: process(l2_tag_q_a, l2_tag_data_a) is begin
         l2_hit_a <= '0';
         l2_hitvec_a <= (others => '0');
         l2_hitway_a <= (others => '-');
         l2_state_a <= T_STATE_INVALID;
         for i in 0 to L2_WAYS - 1 loop
            if((l2_tag_q_a(i)(L2_T_TAGH downto L2_T_TAGL) = l2_tag_data_a(L2_T_TAGH downto L2_T_TAGL)) and (l2_tag_q_a(i)(L2_T_STATEH downto L2_T_STATEL) /= T_STATE_INVALID)) then
               l2_hit_a <= '1';
               l2_hitvec_a(i) <= '1';
               l2_hitway_a <= vec(i, l2_hitway_a'length);
               l2_state_a <= l2_tag_q_a(i)(L2_T_STATEH downto L2_T_STATEL);
            end if;
         end loop;
      end process;
      l2_tag_b_comparators: process(l2_tag_q_b, l2_tag_data_b) is begin
         l2_hit_b <= '0';
         l2_hitvec_b <= (others => '0');
         l2_hitway_b <= (others => '-');
         l2_state_b <= T_STATE_INVALID;
         for i in 0 to L2_WAYS - 1 loop
            if((l2_tag_q_b(i)(L2_T_TAGH downto L2_T_TAGL) = l2_tag_data_b(L2_T_TAGH downto L2_T_TAGL)) and (l2_tag_q_b(i)(L2_T_STATEH downto L2_T_STATEL) /= T_STATE_INVALID)) then
               l2_hit_b <= '1';
               l2_hitvec_b(i) <= '1';
               l2_hitway_b <= vec(i, l2_hitway_b'length);
               l2_state_b <= l2_tag_q_b(i)(L2_T_STATEH downto L2_T_STATEL);
            end if;
         end loop;
      end process;

      l2_replace_algo: entity work.l1_replace generic map(
         OFFSET_BITS => L2_OFFSET_BITS,
         WAY_BITS => L2_WAY_BITS,
         WAYS => L2_WAYS,
         REPLACE_TYPE => L2_REPLACE_TYPE,
         SUB_REPLACE_TYPE => L2_SUB_REPLACE_TYPE,
         BLOCK_FACTOR => L2_HYBRID_BLOCK_FACTOR
      )
      port map(
         clock => clock,
         rst => rst,

         ref_addr => l2_bus_wr_addr(VOFFH downto VOFFL),
         ref_way => l2_wrway,
         ref_valid => l2_ref,
         fill_addr => l2_tag_addr_a(VOFFH downto VOFFL),
         fill_way => l2_replaceway
      );
   end generate;
   no_l2: if(not (L2_OFFSET_BITS > 0 and L2_WAYS > 0)) generate
      l2_hit_a <= '0';
      l2_state_a <= T_STATE_INVALID;
      l2_hit_b <= '0';
      l2_state_b <= T_STATE_INVALID;
   end generate;


   -- MP cache coherence stuff
   mp: if(ENABLE_SNOOPING) generate
      snoop_pipe: process(clock) is begin
         if(rising_edge(clock)) then
            if(s_bus_a_waitn = '1') then
               s_bus_r_addr_r <= s_bus_r_addr;
               s_bus_r_sharen_r <= s_bus_r_sharen or s_bus_r_sharen_oe;
               s_bus_r_excln_r <= s_bus_r_excln or s_bus_r_excln_oe;
            end if;

            if(rst = '1') then
               s_bus_r_sharen_r <= '1';
               s_bus_r_excln_r <= '1';
            end if;
         end if;
      end process;

      l1_stag_as <= not s_bus_a_waitn;
      l1_stag_addr <= s_bus_r_addr;
      s_active <= s_bus_r_sharen_r nand s_bus_r_excln_r;

      l1_u_stag(L1_T_TAGH downto BL) <= s_bus_r_addr_r;

      snoop_tag_check: process(l1_d_stag_match, l1_d_stag_excl, l2_hit_b, l2_state_b, s_bus_r_addr_r, mshr) is begin
         s_match <= '0';
         s_match_excl <= '0';
         if(any_bit_set(l1_d_stag_match)) then
            s_match <= '1';
         end if;
         if(any_bit_set(l1_d_stag_match and l1_d_stag_excl)) then
            s_match_excl <= '1';
         end if;
         if(l2_hit_b = '1') then
            s_match <= '1';
            if(cache_state_test_at_least(l2_state_b, T_STATE_EXCLUSIVE)) then
               s_match_excl <= '1';
            end if;
         end if;
         if(mshr.valid = '1' and mshr.snooped = '1' and compare_eq(s_bus_r_addr_r(L1_T_TAGH downto L1_OFFL), mshr.addr(L1_T_TAGH downto L1_OFFL))) then
            s_match <= '1';
            if(cache_state_test_at_least(mshr.insstate, T_STATE_EXCLUSIVE)) then
               s_match_excl <= '1';
            end if;
         end if;
      end process;

      s_attn <=
         '0' when s_active = '0' else
         '0' when s_match = '0' else
         '1' when s_match_excl = '1' else
         '1' when s_bus_r_excln_r = '0' else
         '0';

      s_fifowait <=
         '0' when dmfifo_empty = '1' else
         '1' when NO_WRITEBACK_SNOOPING else
         '1' when compare_eq(
                     s_bus_r_addr_r(L1_T_TAGH downto L1_OFFL),
                     mshr.oldaddr(L1_T_TAGH downto L1_OFFL)
                  ) else
         '0';

      s_bus_a_waitn_oe <= s_active and (s_attn or s_fifowait);
      s_bus_a_ackn_oe <= s_active;
      s_bus_a_sharen_oe <= s_active and s_match;
      s_bus_a_excln_oe <= s_active and s_match_excl;
   end generate;
   no_mp: if(not ENABLE_SNOOPING) generate
      l1_stag_addr <= (others => '-');
      l1_stag_as <= '1';
      s_attn <= '0';
   end generate;
end architecture;
