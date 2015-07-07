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

library ieee, altera_mf, z48common; use ieee.std_logic_1164.all, ieee.std_logic_unsigned.all, ieee.std_logic_arith.all, altera_mf.altera_mf_components.all, z48common.z48common.all;


entity z48iqueue is
   generic(
      QUEUE_LENGTH:              natural;
      GATE_CYCLES:               natural := 0
   );
   port(
      clock:                     in       std_logic;
      reset:                     in       std_logic;

      -- signals coming from icache
      icache_in:                 in       dword;
      icache_pcs:                in       dword;
      icache_flags:              in       icache_flags_t;
      icache_in_valid:           in       std_logic_vector(1 downto 0);
      full:                      buffer   std_logic;
      empty:                     out      std_logic;

      -- signals going forward to decoders
      iqueue_out:                out      dworda;
      iqueue_pcs_out:            out      dworda;
      iqueue_flags_out:          out      icache_flags_t;
      iqueue_out_valid:          buffer   std_logic_vector(1 downto 0);
      issue:                     in       std_logic_vector(1 downto 0);
      stall:                     in       std_logic;
      flush:                     in       std_logic;

      gate_stall:                in       std_logic := '0';
      gate:                      in       std_logic := '0'
   );
end entity;

architecture z48iqueue of z48iqueue is
   constant ABITS:               natural := log2c(QUEUE_LENGTH);
   constant FLAGS:               natural := 4;
   constant WIDTH:               natural := 32 + 32 + FLAGS;
   signal inp, ninp:             std_logic_vector(ABITS - 1 downto 0);
   signal outp, noutp:           std_logic_vector(ABITS - 1 downto 0);
   signal count, ncount:         integer range 0 to QUEUE_LENGTH;
   signal nr_in, nr_out:         integer range 0 to 2;

   signal e_addr_a, e_addr_b, o_addr_a, o_addr_b: std_logic_vector(ABITS - 2 downto 0);
   signal e_d, e_q, o_d, o_q:    std_logic_vector(WIDTH - 1 downto 0);
   signal e_we, o_we:            std_logic;
   signal e_l, o_l:              std_logic;
   signal as_b:                  std_logic;
   
   signal o0, o1:                std_logic_vector(WIDTH - 1 downto 0);

   function flag_pack(x: icache_flag_t) return std_logic_vector is
      variable ret: std_logic_vector(FLAGS - 1 downto 0);
   begin
      ret := (
         0 => x.itlb_miss,
         1 => x.itlb_invalid,
         2 => x.itlb_permerr,
         3 => x.i_unaligned
      );
      return ret;
   end function;

   function flag_unpack(x: std_logic_vector) return icache_flag_t is begin
      return (
         itlb_miss => x(x'low + 0),
         itlb_invalid => x(x'low + 1),
         itlb_permerr => x(x'low + 2),
         i_unaligned => x(x'low + 3)
      );
   end function;

   type packed_t is array(1 downto 0) of std_logic_vector(WIDTH - 1 downto 0);
   signal packed: packed_t;

   signal gate_count: integer range 0 to GATE_CYCLES - 1;
   signal gate_out: std_logic;
begin
   assert(QUEUE_LENGTH mod 2 = 0 and QUEUE_LENGTH >= 8) report "QUEUE_LENGTH must be even and >= 8" severity error;

   even: entity work.ramwrap generic map(
      WIDTH_A => WIDTH,
      WIDTHAD_A => ABITS - 1,
      NUMWORDS_A => QUEUE_LENGTH / 2,
      WIDTH_B => WIDTH,
      WIDTHAD_B => ABITS - 1,
      NUMWORDS_B => QUEUE_LENGTH / 2,
      OPERATION_MODE => "DUAL_PORT",
      MIXED_PORT_FORWARDING => true
   )
   port map(
      clock0 => clock,
      clock1 => clock,
      address_a => e_addr_a,
      address_b => e_addr_b,
      addressstall_b => as_b,
      data_a => e_d,
      q_b => e_q,
      wren_a => e_we
   );

   odd: entity work.ramwrap generic map(
      WIDTH_A => WIDTH,
      WIDTHAD_A => ABITS - 1,
      NUMWORDS_A => QUEUE_LENGTH / 2,
      WIDTH_B => WIDTH,
      WIDTHAD_B => ABITS - 1,
      NUMWORDS_B => QUEUE_LENGTH / 2,
      OPERATION_MODE => "DUAL_PORT",
      MIXED_PORT_FORWARDING => true
   )
   port map(
      clock0 => clock,
      clock1 => clock,
      address_a => o_addr_a,
      address_b => o_addr_b,
      addressstall_b => as_b,
      data_a => o_d,
      q_b => o_q,
      wren_a => o_we
   );

   nr_in <= 0 when full = '1' else
            2 when icache_in_valid = "11" else
            1 when icache_in_valid = "10" else
            1 when icache_in_valid = "01" else
            0;
   ninp <=  (others => '0') when flush = '1' else
            inp when full = '1' else
            inp + 2 when icache_in_valid = "11" else
            inp + 1 when icache_in_valid = "10" else
            inp + 1 when icache_in_valid = "01" else
            inp;
   e_addr_a <= inp(ABITS - 1 downto 1) when inp(0) = '0' else
               inp(ABITS - 1 downto 1) + 1;
   o_addr_a <= inp(ABITS - 1 downto 1);
   packed(0) <= flag_pack(icache_flags(0)) & icache_pcs(31 downto 0) & icache_in(31 downto 0);
   packed(1) <= flag_pack(icache_flags(1)) & icache_pcs(63 downto 32) & icache_in(63 downto 32);
   e_d <=   packed(0) when inp(0) = '0' and icache_in_valid(0) = '1' else -- 2A
            packed(1) when inp(0) = '1' and icache_in_valid(1) = '1' else -- 2U
            packed(1) when inp(0) = '0' and icache_in_valid(1) = '1' else -- 1A
            (others => '-');
   o_d <=   packed(1) when inp(0) = '0' and icache_in_valid(1) = '1' else -- 2A
            packed(0) when inp(0) = '1' and icache_in_valid(0) = '1' else -- 2U
            packed(1) when inp(0) = '1' and icache_in_valid(1) = '1' else -- 1U
            (others => '-');
   e_l <=   '1' when inp(0) = '0' and icache_in_valid(0) = '1' else -- 2A
            '1' when inp(0) = '1' and icache_in_valid(1) = '1' else -- 2U
            '1' when inp(0) = '0' and icache_in_valid(1) = '1' else -- 1A
            '0';
   o_l <=   '1' when inp(0) = '0' and icache_in_valid(1) = '1' else -- 2A
            '1' when inp(0) = '1' and icache_in_valid(0) = '1' else -- 2U
            '1' when inp(0) = '1' and icache_in_valid(1) = '1' else -- 1U
            '0';
   e_we <= not full and not flush and e_l;
   o_we <= not full and not flush and o_l;

   nr_out <= 0 when stall = '1' else
             2 when issue = "11" else
             1 when issue = "01" else
             0;
   noutp <= (others => '0') when flush = '1' else
            outp when stall = '1' else
            outp + 2 when issue = "11" else
            (others => '-') when issue = "10" else
            outp + 1 when issue = "01" else
            outp;
   ncount <= 0 when flush = '1' else
             count + nr_in - nr_out;
   full <= '1' when count > QUEUE_LENGTH - 4 else '0';
   empty <= '1' when count = 0 else
            '0';
   e_addr_b <= noutp(ABITS - 1 downto 1) when noutp(0) = '0' else
               noutp(ABITS - 1 downto 1) + 1;
   o_addr_b <= noutp(ABITS - 1 downto 1);
   as_b <= stall and not flush;
   o0 <= e_q when outp(0) = '0' else o_q;
   o1 <= o_q when outp(0) = '0' else e_q;
   iqueue_out_valid(0) <=  '0' when gate_out = '1' else
                           '1' when count >= 1 else
                           '0';
   iqueue_out_valid(1) <=  '0' when gate_out = '1' else
                           '1' when count >= 2 else
                           '0';
   iqueue_out(0) <= o0(31 downto 0);
   iqueue_out(1) <= o1(31 downto 0);
   iqueue_pcs_out(0) <= o0(63 downto 32);
   iqueue_pcs_out(1) <= o1(63 downto 32);
   iqueue_flags_out(0) <= flag_unpack(o0(FLAGS + 63 downto 64));
   iqueue_flags_out(1) <= flag_unpack(o1(FLAGS + 63 downto 64));

   process(clock) is begin
      if(rising_edge(clock)) then
         outp <= noutp;
         inp <= ninp;
         count <= ncount;

         if(gate = '1') then
            gate_out <= '1';
            if(gate_stall = '0') then
               gate_count <= gate_count + 1;
               if(gate_count = GATE_CYCLES - 1) then
                  gate_out <= '0';
                  gate_count <= 0;
               end if;
            end if;
         else
            gate_out <= '0';
         end if;

         -- synch reset
         if(reset = '1') then
            outp <= (others => '0');
            inp <= (others => '0');
            count <= 0;
            gate_count <= 0;
            gate_out <= '0';
         end if;
      end if;
   end process;
end architecture;
