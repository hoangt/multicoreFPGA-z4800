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

entity l2_v4 is
   generic(
      ABITS:                        natural := 23; -- bits in cacheable range
      OFFSET_BITS:                  natural := 11;
      BLOCK_BITS:                   natural := 4;
      WAYS:                         natural := 8;
      REPLACE_TYPE:                 string := "RANDOM";
      SUB_REPLACE_TYPE:             string := "";
      HYBRID_BLOCK_FACTOR:          natural := 2;
      RRIP_RRPV_BITS:               natural := 2;
      RRIP_INSERT_RRPV:             natural := 2;
      RRIP_HIT_RRPV:                natural := 0;
      PMFIFO_LENGTH:                natural := 4;
      WRITE_ALLOCATE:               boolean := false;
      WIDTH:                        natural := 64;
      LIMIT_OUTSTANDING_REQS:       boolean := true;
      OUTSTANDING_LIMIT:            natural := 16;
      MBURST_MODE:                  boolean := false;
      MAX_MBURST_LENGTH:            natural := 0;
      CBURST_MODE:                  boolean := false;
      CBURSTBITS:                   natural := 4;
      CBURST_WRAP:                  boolean := false
   );
   port(
      clock:                        in std_logic;
      rst:                          in std_logic;

      p_addr:                       in std_logic_vector(ABITS - 1 downto 0);
      p_out:                        out std_logic_vector(WIDTH - 1 downto 0);
      p_in:                         in std_logic_vector(WIDTH - 1 downto 0);
      p_rd:                         in std_logic;
      p_wr:                         in std_logic;
      p_valid:                      out std_logic;
      p_halt:                       buffer std_logic;
      p_be:                         in std_logic_vector(WIDTH / 8 - 1 downto 0);
      p_burstcount:                 in std_logic_vector(CBURSTBITS - 1 downto 0);

      m_addr:                       out std_logic_vector(31 downto 0);
      m_out:                        out std_logic_vector(WIDTH - 1 downto 0);
      m_in:                         in std_logic_vector(WIDTH - 1 downto 0);
      m_rd:                         out std_logic;
      m_wr:                         out std_logic;
      m_valid:                      in std_logic;
      m_halt:                       in std_logic;
      m_be:                         out std_logic_vector(WIDTH / 8 - 1 downto 0);
      m_burstcount:                 out std_logic_vector(BLOCK_BITS downto 0);

      c_addr:                       out std_logic_vector(31 downto 0);
      c_out:                        out std_logic_vector(WIDTH - 1 downto 0);
      c_in:                         in std_logic_vector(WIDTH - 1 downto 0);
      c_rd:                         buffer std_logic;
      c_wr:                         out std_logic;
      c_valid:                      in std_logic;
      c_halt:                       in std_logic;
      c_be:                         out std_logic_vector(WIDTH / 8 - 1 downto 0);
      c_burstcount:                 buffer std_logic_vector(CBURSTBITS - 1 downto 0);

      perf_addr:                    in std_logic_vector(2 downto 0);
      perf_in:                      in std_logic_vector(31 downto 0);
      perf_out:                     out std_logic_vector(31 downto 0);
      perf_be:                      in std_logic_vector(3 downto 0);
      perf_rd:                      in std_logic;
      perf_wr:                      in std_logic
   );
end entity;

architecture l2_v4 of l2_v4 is
   constant BLOCKS:                 integer := 2 ** BLOCK_BITS;
   constant WAY_BITS:                integer := log2c(WAYS);
   constant BYTES:                  integer := WIDTH / 8;
   constant BYTEBITS:               integer := log2c(BYTES);
   constant MAX_CBURST_LENGTH:      integer := 2 ** (CBURSTBITS - 1);

   constant BL:                     integer := 0;
   constant BH:                     integer := BL + BYTEBITS - 1;
   constant BLKL:                   integer := BH + 1;
   constant BLKH:                   integer := BLKL + BLOCK_BITS - 1;
   constant OFFL:                   integer := BLKH + 1;
   constant OFFH:                   integer := OFFL + OFFSET_BITS - 1;
   constant TAGL:                   integer := OFFH + 1;
   constant TAGH:                   integer := ABITS + BYTEBITS - 1;
   constant WAYL:                   integer := TAGL;
   constant WAYH:                   integer := WAYL + WAY_BITS - 1;

   constant TAGBITS:                integer := TAGH - TAGL + 1;
   constant CONTROLBITS:            integer := TAGBITS + 1;

   signal tag_addr_a, tag_addr_b:   std_logic_vector(OFFSET_BITS - 1 downto 0);
   signal tag_data_a:               std_logic_vector(CONTROLBITS - 1 downto 0);
   type tag_array_t is array(0 to WAYS - 1) of std_logic_vector(CONTROLBITS - 1 downto 0);
   signal tag_q_b:                  tag_array_t;
   signal tag_we_a:                 std_logic_vector(0 to WAYS - 1);
   signal tag_as_b:                 std_logic;

   type req_t is record
      addr:                         std_logic_vector(31 downto 0);
      data:                         std_logic_vector(WIDTH - 1 downto 0);
      be:                           std_logic_vector(BYTES - 1 downto 0);
      rd:                           std_logic;
      wr:                           std_logic;
      burstcount:                   std_logic_vector(CBURSTBITS - 1 downto 0);
      first_cycle:                  std_logic;
   end record;
   type req_array_t is array(0 to 1) of req_t;
   signal req:                      req_array_t;

   signal hit, miss:                std_logic;
   signal way:                      integer range 0 to WAYS - 1;

   signal idle:                     std_logic;
   signal halt:                     std_logic;

   signal mcfifo_in, mcfifo_out:    std_logic_vector(32 + WIDTH - 1 downto 0);
   signal mcfifo_rd, mcfifo_empty:  std_logic;
   signal mc_addr_in:               std_logic_vector(31 downto 0);
   
   signal mc_addr:                  std_logic_vector(31 downto 0);
   signal mc_data:                  std_logic_vector(WIDTH - 1 downto 0);
   signal mc_be:                    std_logic_vector(BYTES - 1 downto 0);
   signal mc_rd:                    std_logic;
   signal mc_wr:                    std_logic;
   signal mc_burstcount:            std_logic_vector(CBURSTBITS - 1 downto 0);
   signal mc:                       std_logic;

   signal pc_addr:                  std_logic_vector(31 downto 0);
   signal pc_data:                  std_logic_vector(WIDTH - 1 downto 0);
   signal pc_be:                    std_logic_vector(BYTES - 1 downto 0);
   signal pc_rd:                    std_logic;
   signal pc_wr:                    std_logic;
   signal pc_burstcount:            std_logic_vector(CBURSTBITS - 1 downto 0);
   signal pc:                       std_logic;

   signal pm_addr:                  std_logic_vector(31 downto 0);
   signal pm_data:                  std_logic_vector(WIDTH - 1 downto 0);
   signal pm_be:                    std_logic_vector(BYTES - 1 downto 0);
   signal pm_rd:                    std_logic;
   signal pm_wr:                    std_logic;
   signal pm:                       std_logic;

   signal pmfifo_in, pmfifo_out:    std_logic_vector(32 + BYTES + WIDTH - 1 downto 0);
   signal pmfifo_empty, pmfifo_full: std_logic;

   signal outstanding_cnt:          integer range 0 to OUTSTANDING_LIMIT - 1;
   signal toomany:                  std_logic;

   signal replace_addr:             std_logic_vector(OFFSET_BITS - 1 downto 0);
   signal replace_way:              std_logic_vector(WAY_BITS - 1 downto 0);
   signal replace_req, replace_ack: std_logic;

   signal perf_inc:                 std_logic_vector(7 downto 0);
   signal perf_req:                 std_logic;
   signal perf_ureq:                std_logic;
   signal perf_hit:                 std_logic;
   signal perf_miss:                std_logic;
   signal perf_miss_stall:          std_logic;
   signal perf_stall:               std_logic;
   signal perf_wt_stall:            std_logic;
   signal perf_c_stall:             std_logic;

   signal last_addr:                word;
   signal last_addr_match:          std_logic;
begin
   assert(TAGH >= TAGL) report "Address configuration FUBAR" severity error;
   assert(not MBURST_MODE or (MAX_MBURST_LENGTH = 0) or (BLOCKS mod MAX_MBURST_LENGTH = 0)) report "Burst size must be factor of cache line size" severity error;
   assert(not CBURST_MODE or (CBURSTBITS - 1 <= BLOCK_BITS)) report "CBURSTBITS must not set burst size longer than BLOCK_BITS" severity error;
   assert(not CBURST_MODE or (OUTSTANDING_LIMIT >= MAX_CBURST_LENGTH + 2)) report "OUTSTANDING_LIMIT too low" severity error;

   genways: for i in 0 to WAYS - 1 generate
      tags: altsyncram generic map(
         WIDTH_A => CONTROLBITS,
         WIDTHAD_A => OFFSET_BITS,
         WIDTH_B => CONTROLBITS,
         WIDTHAD_B => OFFSET_BITS,
         OPERATION_MODE => "DUAL_PORT"
      )
      port map(
         clock0 => clock,
         clock1 => clock,
         address_a => tag_addr_a,
         address_b => tag_addr_b,
         addressstall_b => tag_as_b,
         data_a => tag_data_a,
         wren_a => tag_we_a(i),
         q_b => tag_q_b(i)
      );
   end generate;

   req(0).addr <= (31 downto TAGH + 1 => '0') & p_addr & (BH downto BL => '0');
   req(0).data <= p_in;
   req(0).be <= p_be;
   req(0).rd <= p_rd;
   req(0).wr <= p_wr;
   req(0).burstcount <= p_burstcount;
   req(0).first_cycle <= p_rd or p_wr;
   p_halt <= (p_rd or p_wr) and halt;

   process(clock) is begin
      if(rising_edge(clock)) then
         if(halt = '0') then
            for i in req'high downto req'low + 1 loop
               req(i) <= req(i - 1);
            end loop;
         else
            req(1).first_cycle <= '0';
         end if;

         if(rst = '1') then
            for i in req'high downto req'low + 1 loop
               req(i).rd <= '0';
               req(i).wr <= '0';
            end loop;
         end if;
      end if;
   end process;

   tag_addr_b <= req(0).addr(OFFH downto OFFL);
   tag_as_b <= halt;

   process(tag_q_b, req(1)) is begin
      hit <= '0';
      way <= 0;
      for i in tag_q_b'range loop
         if(tag_q_b(i) = '1' & req(1).addr(TAGH downto TAGL)) then
            hit <= '1';
            way <= i;
         end if;
      end loop;
      if(req(1).rd = '0' and req(1).wr = '0') then
         hit <= '0';
      end if;
   end process;
   miss <=  not hit when req(1).wr = '1' and WRITE_ALLOCATE else
            not hit when req(1).rd = '1' else
            '0';

   mcfifo: entity work.fifo generic map(
      WIDTH => 32 + WIDTH,
      LENGTH => BLOCKS
   )
   port map(
      clock => clock,
      rst => rst,
      write => m_valid,
      d => mcfifo_in,
      q => mcfifo_out,
      read => mcfifo_rd,
      empty => mcfifo_empty
   );

   mcfifo_in <= m_in & mc_addr_in;
   mc_addr <= mcfifo_out(31 downto 0);
   mc_data <= mcfifo_out(mcfifo_out'high downto 32);
   mc_be <= (others => '1');
   mc_rd <= '0';
   mc_wr <= not mcfifo_empty;
   mc_burstcount <= vec(1, CBURSTBITS);
   mcfifo_rd <= mc_wr and mc and not c_halt;

   toomany <=  '0' when not LIMIT_OUTSTANDING_REQS else
               '1' when CBURST_MODE and outstanding_cnt >= OUTSTANDING_LIMIT - MAX_CBURST_LENGTH - 2 else
               '1' when not CBURST_MODE and outstanding_cnt >= OUTSTANDING_LIMIT - 2 else
               '0';

   pc_addr(31 downto WAYH + 1) <= (others => '0');
   pc_addr(WAYH downto WAYL) <= vec(way, WAY_BITS);
   pc_addr(OFFH downto 0) <= req(1).addr(OFFH downto 0);
   pc_data <= req(1).data;
   pc_be <= req(1).be;
   pc_rd <= req(1).rd and hit and idle and not toomany;
   pc_wr <= req(1).wr and hit and idle and not pmfifo_full;
   pc_burstcount <= req(1).burstcount;

   halt <=
      miss or
      not idle or -- cache controller doing stuff (tags volatile)
      (req(1).rd and toomany) or -- limit outstanding reads
      (req(1).wr and pmfifo_full) or -- write fifo full
      ((pc_rd or pc_wr) and not pc) or -- lost arbitration
      ((pc_rd or pc_wr) and c_halt); -- cache stalled

   pc <= (pc_rd or pc_wr) and not mc;
   mc <= (mc_rd or mc_wr) and '1';

   c_addr <= mc_addr when mc = '1' else pc_addr;
   c_out <= mc_data when mc = '1' else pc_data;
   c_be <= mc_be when mc = '1' else pc_be;
   c_rd <= mc_rd when mc = '1' else pc_rd;
   c_wr <= mc_wr when mc = '1' else pc_wr;
   c_burstcount <= mc_burstcount when mc = '1' else pc_burstcount;

   p_out <= c_in;
   p_valid <= c_valid;

   pmfifo: entity work.fifo generic map(
      WIDTH => 32 + BYTES + WIDTH,
      LENGTH => PMFIFO_LENGTH
   )
   port map(
      clock => clock,
      rst => rst,
      write => req(1).wr and not halt,
      d => pmfifo_in,
      q => pmfifo_out,
      read => idle and not m_halt and not pmfifo_empty,
      full => pmfifo_full,
      empty => pmfifo_empty
   );
   pmfifo_in <= req(1).data & req(1).be & req(1).addr;

   normal_replace: if(REPLACE_TYPE /= "SRRIP") generate
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

         ref_addr => req(1).addr(OFFH downto OFFL),
         ref_way => vec(way, WAY_BITS),
         ref_valid => hit,

         fill_addr => replace_addr,
         fill_way => replace_way
      );
      replace_req <= '1';
      replace_addr <=   req(1).addr(OFFH downto OFFL) when halt = '1' else
                        req(0).addr(OFFH downto OFFL);
      replace_ack <= '1';
   end generate;

   process(clock) is
      type state_t is (s_idle, s_rrip1, s_rrip2, s_miss, s_return1, s_return2, s_return3, s_invall);
      variable state: state_t;
      variable l: std_logic_vector(OFFSET_BITS - 1 downto 0);
      variable missaddr: std_logic_vector(31 downto 0);
      variable cr, cw: integer range 0 to BLOCKS;
      variable way: integer range 0 to WAYS - 1;
      variable t: integer range outstanding_cnt'range;

      function get_addr_inc return integer is begin
         if(MBURST_MODE) then
            if(MAX_MBURST_LENGTH = 0) then
               return BLOCKS;
            elsif(BLOCKS > MAX_MBURST_LENGTH) then
               return MAX_MBURST_LENGTH;
            else
               return BLOCKS;
            end if;
         else
            return 1;
         end if;
      end function;
      constant addr_inc: integer := get_addr_inc;
   begin
      if(rising_edge(clock)) then
         t := outstanding_cnt;
         if(c_rd = '1' and c_halt = '0') then
            if(CBURST_MODE) then
               t := t + int(c_burstcount);
            else
               t := t + 1;
            end if;
         end if;
         if(c_valid = '1') then
            t := t - 1;
         end if;
         outstanding_cnt <= t;

         tag_addr_a <= missaddr(OFFH downto OFFL);
         tag_data_a <= '1' & missaddr(TAGH downto TAGL);
         tag_we_a <= (others => '0');
         if(m_halt = '0') then
            m_rd <= '0';
            m_wr <= '0';
         end if;

         case state is
            when s_idle =>
               if(m_halt = '0' and pmfifo_empty = '0') then
                  
                  m_addr <= pmfifo_out(31 downto 0);
                  m_be <= pmfifo_out(BYTES + 31 downto 32);
                  m_out <= pmfifo_out(WIDTH + BYTES + 31 downto BYTES + 32);
                  m_wr <= '1';
                  m_burstcount <= vec(1, m_burstcount'length);
               elsif(m_halt = '0' and miss = '1') then
                  missaddr := req(1).addr;
                  missaddr(BLKH downto BLKL) := (others => '0');
                  m_addr <= missaddr;
                  m_be <= (others => '1');
                  mc_addr_in <= (others => '0');
                  mc_addr_in(OFFH downto 0) <= missaddr(OFFH downto 0);
                  cr := BLOCKS - addr_inc;
                  cw := BLOCKS;
                  m_burstcount <= vec(addr_inc, m_burstcount'length);
                  if(REPLACE_TYPE = "SRRIP") then
                     replace_addr <= req(1).addr(OFFH downto OFFL);
                     state := s_rrip1;
                  else
                     m_rd <= '1';
                     mc_addr_in(TAGL + WAY_BITS - 1 downto TAGL) <= replace_way;
                     way := int(replace_way);
                     state := s_miss;
                  end if;
               end if;
            when s_rrip1 =>
               state := s_rrip2;
            when s_rrip2 =>
               replace_req <= '1';
               if(replace_ack = '1') then
                  replace_req <= '0';
                  m_rd <= '1';
                  mc_addr_in(TAGL + WAY_BITS - 1 downto TAGL) <= replace_way;
                  way := int(replace_way);
                  state := s_miss;
               end if;
            when s_miss =>
               if(m_valid = '1') then
                  cw := cw - 1;
                  mc_addr_in(BLKH downto BLKL) <= mc_addr_in(BLKH downto BLKL) + 1;
               end if;
               if(m_halt = '0' and cr > 0) then
                  cr := cr - addr_inc;
                  missaddr(BLKH downto BLKL) := missaddr(BLKH downto BLKL) + addr_inc;
                  m_addr <= missaddr;
                  m_rd <= '1';
               end if;
               if(cw = 0) then
                  state := s_return1;
               end if;
            when s_return1 =>
               if(mcfifo_empty = '1') then
                  tag_we_a(way) <= '1';
                  state := s_return2;
               end if;
            when s_return2 =>
               state := s_return3;
            when s_return3 =>
               state := s_idle;
            when s_invall =>
               tag_data_a <= (others => '0');
               tag_we_a <= (others => '1');
               tag_addr_a <= l;
               if(all_bits_set(l)) then
                  state := s_idle;
               end if;
               l := l + 1;
            when others =>
               state := s_idle;
         end case;

         if(state = s_idle) then
            idle <= '1';
         else
            idle <= '0';
         end if;

         if(rst = '1') then
            outstanding_cnt <= 0;
            idle <= '0';
            state := s_invall;
            l := (others => '0');
            replace_req <= '0';
         end if;
      end if;
   end process;

   process(clock) is begin
      if(rising_edge(clock)) then
         if(req(1).rd = '1' or req(1).wr = '1') then
            last_addr <= req(1).addr;
         end if;
      end if;
   end process;
   last_addr_match <= '1' when req(1).addr(TAGH downto OFFL) = last_addr(TAGH downto OFFL) else '0';

   perfcounters: entity work.perf generic map(
      NR_COUNTERS_LOG2 => 3
   )
   port map(
      clock => clock,
      rst => rst,
      clr => '0',

      m_addr => perf_addr,
      m_in => perf_in,
      m_out => perf_out,
      m_be => perf_be,
      m_rd => perf_rd,
      m_wr => perf_wr,

      perf_inc => perf_inc
   );

   perf_inc(0) <= perf_req;
   perf_inc(1) <= perf_ureq;
   perf_inc(2) <= perf_hit;
   perf_inc(3) <= perf_miss;
   perf_inc(4) <= perf_miss_stall;
   perf_inc(5) <= perf_stall;
   perf_inc(6) <= perf_wt_stall;
   perf_inc(7) <= perf_c_stall;

   perf_req <= req(1).first_cycle;
   perf_ureq <= req(1).first_cycle and not last_addr_match;
   perf_hit <= req(1).first_cycle and hit and not last_addr_match;
   perf_miss <= req(1).first_cycle and miss and not last_addr_match;
   perf_miss_stall <= miss;
   perf_stall <= (req(1).rd or req(1).wr) and halt;
   perf_wt_stall <= req(1).wr and idle and pmfifo_full;
   perf_c_stall <= c_halt and hit and idle and not pmfifo_full;
end architecture;
