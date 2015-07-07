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

library ieee, lpm, altera_mf, z48common; use ieee.std_logic_1164.all, ieee.std_logic_unsigned.all, ieee.std_logic_arith.all, lpm.lpm_components.all, altera_mf.altera_mf_components.all, z48common.z48common.all;


entity jtlb is
   generic(
      JTLB_SIZE:                    integer;
      CAM_LATENCY:                  integer;
      PRECISE_FLUSH:                boolean;
      ITLB_OFFSET_BITS:             integer;
      DTLB_OFFSET_BITS:             integer;
      NO_LARGE_PAGES:               boolean;
      CHECK_CAM:                    boolean := false;
      DETECT_MULTIPLE_MATCH:        boolean := false
   );
   port(
      clock:                        in std_logic;
      rst:                          in std_logic;

      itlb_vaddr:                   in word;
      itlb_asid:                    in std_logic_vector(7 downto 0);
      itlb_probe:                   in std_logic;
      itlb_ack:                     out std_logic;
      itlb_nack:                    out std_logic;
      itlb_ent:                     out utlb_raw_t;
      itlb_inv_addr:                buffer std_logic_vector(ITLB_OFFSET_BITS - 1 downto 0);
      itlb_inv:                     out std_logic;

      dtlb_vaddr:                   in word;
      dtlb_asid:                    in std_logic_vector(7 downto 0);
      dtlb_probe:                   in std_logic;
      dtlb_ack:                     out std_logic;
      dtlb_nack:                    out std_logic;
      dtlb_ent:                     out utlb_raw_t;
      dtlb_inv_addr:                buffer std_logic_vector(DTLB_OFFSET_BITS - 1 downto 0);
      dtlb_inv:                     out std_logic;

      r_entryhi:                    in word;
      r_pagemask:                   in word;
      r_entrylo0:                   in word;
      r_entrylo1:                   in word;
      r_index:                      in word;
      tlbp:                         in std_logic;
      tlbw:                         in std_logic;
      tlbr:                         in std_logic;
      cop_ack:                      out std_logic;
      cop_nack:                     out std_logic;
      cop_index:                    out word;
      cop_ent:                      out tlb_raw_t;
      tlbw_done:                    out std_logic;

      mce:                          out std_logic
   );
end entity;

architecture jtlb of jtlb is
   constant ADDRBITS:               integer := log2c(JTLB_SIZE);
   attribute altera_attribute:      string;

   signal ent_addr:                 std_logic_vector(ADDRBITS - 1 downto 0);
   signal ent_d, ent_q, ent_r:      tlb_raw_t;
   signal ent_we:                   std_logic;

   signal pattern, mask:            std_logic_vector(26 downto 0);
   signal index:                    std_logic_vector(ADDRBITS - 1 downto 0);
   signal write:                    std_logic;
   signal match_raw, match:         std_logic;
   signal match_index_raw, match_index: std_logic_vector(ADDRBITS - 1 downto 0);
   signal multimatch:               std_logic;
   attribute altera_attribute of match: signal is "MULTICYCLE=" & integer'image(CAM_LATENCY);
   attribute altera_attribute of match_index: signal is "MULTICYCLE=" & integer'image(CAM_LATENCY);
   attribute altera_attribute of multimatch: signal is "MULTICYCLE=" & integer'image(CAM_LATENCY);

   signal uraw:                     utlb_raw_t;

   -- these functions are hacks to make it easier to deal with weird array
   -- slices that aren't based at 0
   function aligned_and(x: std_logic_vector; y: std_logic_vector) return std_logic_vector is
      variable result: std_logic_vector(x'length - 1 downto 0);
   begin
      assert(x'length = y'length) report "aligned_and arguments not same length" severity error;
      result := x(x'high downto x'low) and y(y'high downto y'low);
      return result;
   end function;
   function aligned_or(x: std_logic_vector; y: std_logic_vector) return std_logic_vector is
      variable result: std_logic_vector(x'length - 1 downto 0);
   begin
      assert(x'length = y'length) report "aligned_or arguments not same length" severity error;
      result := x(x'high downto x'low) or y(y'high downto y'low);
      return result;
   end function;
   function aligned_cat(x: std_logic_vector; y: std_logic_vector) return std_logic_vector is
      variable result: std_logic_vector(x'length + y'length - 1 downto 0);
   begin
      result := x(x'high downto x'low) & y(y'high downto y'low);
      return result;
   end function;
   function is_4k(x: tlb_raw_t) return boolean is
      variable mask: std_logic_vector(18 downto 0);
   begin
      mask := tlb_unpack(x).mask;
      return all_bits_clear(mask);
   end function;
   function get_tlb_offbits(ent: tlb_raw_t; offbits: integer) return std_logic_vector is
      variable vpn2: std_logic_vector(18 downto 0);
   begin
      vpn2 := tlb_unpack(ent).vpn2;
      return vpn2(offbits - 2 downto 0) & '0';
   end function;

   signal inv_all:                  std_logic;
begin
   -- TLB entry RAM
   ents: altsyncram generic map(
      WIDTH_A => ent_d'length,
      WIDTHAD_A => ADDRBITS,
      NUMWORDS_A => JTLB_SIZE,
      OPERATION_MODE => "SINGLE_PORT"
      --LPM_HINT => "ENABLE_RUNTIME_MOD=YES,INSTANCE_NAME=jtlb"
   )
   port map(
      clock0 => clock,
      address_a => ent_addr,
      q_a => ent_r,
      wren_a => ent_we,
      data_a => ent_d
   );

   -- CAM
   cam: entity work.cam generic map(
      SIZE => JTLB_SIZE,
      IN_LENGTH => 27,
      OUT_LENGTH => ADDRBITS,
      DETECT_MULTIPLE_MATCH => DETECT_MULTIPLE_MATCH
   )
   port map(
      clock => clock,
      rst => rst,
      pattern => pattern,
      mask => mask,
      index => index,
      write => write,
      match => match_raw,
      match_index => match_index_raw,
      multimatch => multimatch
   );
   -- CAM output register
   process(clock) is begin
      if(rising_edge(clock)) then
         match <= match_raw;
         match_index <= match_index_raw;
      end if;
   end process;

   -- misc glue
   itlb_ent <= uraw;
   dtlb_ent <= uraw;
   cop_ent <= ent_q;
   cop_index <= (31 downto ADDRBITS => '0') & ent_addr;

   -- master state machine
   process(clock) is
      type state_t is (s_idle, s_probe1, s_probe2, s_probe3, s_probe4, s_probe5, s_nack, s_read1, s_read2, s_read3, s_return, s_flush1, s_flush2, s_flush3, s_flush4, s_flush5, s_flush6, s_flushwait, s_reset);
      variable state: state_t;
      type inv_state_t is (i_idle, i_1);
      variable inv_state: inv_state_t;
      type who_t is (dtlb, itlb, cop0);
      variable who: who_t;
      variable vaddr: word;
      variable asid: std_logic_vector(7 downto 0);
      variable counter: integer range CAM_LATENCY + 1 downto 0;
      variable uent: utlb_ent_t;
      variable itlb_needs_flush, dtlb_needs_flush: std_logic;
      variable itlb_count: integer range 2 ** ITLB_OFFSET_BITS - 1 downto 0;
      variable dtlb_count: integer range 2 ** DTLB_OFFSET_BITS - 1 downto 0;

      procedure do_ack is begin
         case who is
            when dtlb => dtlb_ack <= '1';
            when itlb => itlb_ack <= '1';
            when cop0 => cop_ack <= '1';
         end case;
      end procedure;

      procedure do_nack is begin
         case who is
            when dtlb => dtlb_nack <= '1';
            when itlb => itlb_nack <= '1';
            when cop0 => cop_ack <= '1';
         end case;
      end procedure;

      -- address translation magic happens here; this maps jtlb-style
      -- double-page entries with variable page size to utlb-style
      -- single-page entries with fixed 4K page size
      procedure build_uent(ent: tlb_ent_t) is
         variable oddeven: integer range 12 to 31;
         variable hent: tlb_hent_t;
         variable vbits, pbits: std_logic_vector(31 downto 12);
         variable mask: std_logic_vector(31 downto 12);
         variable paddr: word;
      begin
         -- select which halfpage we are interested in
         oddeven := ffc(ent.mask) - 1;
         if(vaddr(oddeven) = '0') then
            hent := ent.h(0);
         else
            hent := ent.h(1);
         end if;

         -- figure out which bits of paddr come from vpn and which from ppn
         mask := tlb_entmask_to_xlatmask(ent.mask); -- tricky.
         vbits := aligned_and(vaddr(31 downto 12), mask);
         pbits := aligned_and(hent.pfn, not mask);
         paddr := aligned_cat(aligned_or(vbits, pbits), vaddr(11 downto 0));

         -- generate a 4k mapping based on computed paddr
         uent.vpn := vaddr(31 downto 12);
         uent.asid := ent.asid;
         uent.pfn := paddr(31 downto 12);
         uent.c := hent.c;
         uent.d := hent.d(2);
         uent.v := hent.v(1);
         uent.g := hent.g(0);
         uent.m := '0';
         uent.p := '1';
      end procedure;
   begin
      if(rising_edge(clock)) then
         write <= '0';
         ent_we <= '0';
         itlb_ack <= '0';
         itlb_nack <= '0';
         itlb_inv <= '0';
         dtlb_ack <= '0';
         dtlb_nack <= '0';
         dtlb_inv <= '0';
         cop_ack <= '0';
         cop_nack <= '0';
         tlbw_done <= '0';

         case inv_state is
            when i_idle =>
               if(inv_all = '1') then
                  inv_state := i_1;
                  itlb_count := itlb_count'high;
                  dtlb_count := dtlb_count'high;
                  itlb_inv_addr <= (others => '0');
                  dtlb_inv_addr <= (others => '0');
                  itlb_inv <= '1';
                  dtlb_inv <= '1';
               end if;
            when i_1 =>
               if(itlb_count > 0) then
                  itlb_count := itlb_count - 1;
                  itlb_inv_addr <= itlb_inv_addr + 1;
                  itlb_inv <= '1';
               end if;
               if(dtlb_count > 0) then
                  dtlb_count := dtlb_count - 1;
                  dtlb_inv_addr <= dtlb_inv_addr + 1;
                  dtlb_inv <= '1';
               end if;
               if(itlb_count = 0 and dtlb_count = 0) then
                  inv_state := i_idle;
                  inv_all <= '0';
               end if;
         end case;

         case state is
            when s_idle =>
               counter := CAM_LATENCY + 1;
               if(tlbw = '1') then -- JTLB write (must have highest priority)
                  -- CAM stuff
                  index <= r_index(ADDRBITS - 1 downto 0);
                  pattern <= r_entryhi(7 downto 0) & r_entryhi(31 downto 13);
                  if(NO_LARGE_PAGES) then
                     mask <=
                        (7 downto 0 => not (r_entrylo0(0) and r_entrylo1(0))) &
                        (18 downto 0 => '1');
                  else
                     mask <=
                        (7 downto 0 => not (r_entrylo0(0) and r_entrylo1(0))) &
                        not tlb_entmask_to_cmpmask(r_pagemask(31 downto 13));
                  end if;
                  write <= '1';

                  -- RAM stuff
                  ent_addr <= r_index(ADDRBITS - 1 downto 0);
                  ent_d <= r_pagemask & r_entryhi & r_entrylo1 & r_entrylo0;
                  if(NO_LARGE_PAGES) then
                     ent_d(127 downto 96) <= (others => '0');
                  end if;
                  ent_d(76) <= r_entrylo0(0) and r_entrylo1(0); -- set G bit

                  if(PRECISE_FLUSH) then
                     state := s_flush1;
                  else
                     ent_we <= '1';
                     inv_all <= '1';
                     state := s_flushwait;
                  end if;
               elsif(tlbp = '1') then -- JTLB probe
                  who := cop0;
                  vaddr := r_entryhi(31 downto 12) & (11 downto 0 => '0');
                  asid := r_entryhi(7 downto 0);
                  pattern <= asid & vaddr(31 downto 13);
                  state := s_probe1;
               elsif(tlbr = '1') then -- JTLB read
                  ent_addr <= r_index(ADDRBITS - 1 downto 0);
                  state := s_read1;
               elsif(dtlb_probe = '1') then -- DTLB probe
                  who := dtlb;
                  vaddr := dtlb_vaddr(31 downto 12) & (11 downto 0 => '0');
                  asid := dtlb_asid;
                  pattern <= asid & vaddr(31 downto 13);
                  state := s_probe1;
               elsif(itlb_probe = '1') then -- ITLB probe
                  who := itlb;
                  vaddr := itlb_vaddr(31 downto 12) & (11 downto 0 => '0');
                  asid := itlb_asid;
                  pattern <= asid & vaddr(31 downto 13);
                  state := s_probe1;
               end if;
            when s_flush1 =>
               state := s_flush2;
            when s_flush2 =>
               ent_q <= ent_r;
               ent_we <= '1';
               state := s_flush3;
            when s_flush3 =>
               if(NO_LARGE_PAGES or (is_4k(ent_d) and is_4k(ent_q))) then
                  -- flush the first of two overwritten 4K mappings
                  itlb_inv_addr <= get_tlb_offbits(ent_d, ITLB_OFFSET_BITS);
                  dtlb_inv_addr <= get_tlb_offbits(ent_d, DTLB_OFFSET_BITS);
                  itlb_inv <= '1';
                  dtlb_inv <= '1';
                  state := s_flush4;
               else
                  -- not a 4K mapping; gotta flush 'em all
                  inv_all <= '1';
                  state := s_flushwait;
               end if;
            when s_flush4 =>
               -- flush the second of two overwritten 4K mappings
               itlb_inv_addr(0) <= '1';
               dtlb_inv_addr(0) <= '1';
               itlb_inv <= '1';
               dtlb_inv <= '1';

               -- check if old/new entries alias the same ITLB/DTLB set
               if(get_tlb_offbits(ent_q, ITLB_OFFSET_BITS) /= get_tlb_offbits(ent_d, ITLB_OFFSET_BITS)) then
                  itlb_needs_flush := '1';
               else
                  itlb_needs_flush := '0';
               end if;
               if(get_tlb_offbits(ent_q, DTLB_OFFSET_BITS) /= get_tlb_offbits(ent_d, DTLB_OFFSET_BITS)) then
                  dtlb_needs_flush := '1';
               else
                  dtlb_needs_flush := '0';
               end if;
               if(itlb_needs_flush = '1' or dtlb_needs_flush = '1') then
                  -- vpn2 has changed and does not alias same entry in
                  -- ITLB and/or DTLB; need to flush two more 4K mappings
                  state := s_flush5;
               else
                  tlbw_done <= '1';
                  state := s_return;
               end if;
            when s_flush5 =>
               itlb_inv_addr <= get_tlb_offbits(ent_q, ITLB_OFFSET_BITS);
               dtlb_inv_addr <= get_tlb_offbits(ent_q, DTLB_OFFSET_BITS);
               itlb_inv <= itlb_needs_flush;
               dtlb_inv <= dtlb_needs_flush;
               state := s_flush6;
            when s_flush6 =>
               itlb_inv_addr(0) <= '1';
               dtlb_inv_addr(0) <= '1';
               itlb_inv <= itlb_needs_flush;
               dtlb_inv <= dtlb_needs_flush;
               tlbw_done <= '1';
               state := s_return;
            when s_probe1 =>
               if(who /= cop0 and vaddr(31 downto 29) = "100") then -- kseg0
                  ent_q <= "0001111111111111111" & (108 downto 96 => '0') &
                           "1000000000000000000" & '1' & "0000" & "00000000" &
                           "000000" & "00010000000000000000" & "100" & "111" &
                           "000000" & "00000000000000000000" & "100" & "111";
                  state := s_probe4;
               elsif(who /= cop0 and vaddr(31 downto 29) = "101") then -- kseg1
                  ent_q <= "0001111111111111111" & (108 downto 96 => '0') &
                           "1010000000000000000" & '1' & "0000" & "00000000" &
                           "000000" & "00010000000000000000" & "010" & "111" &
                           "000000" & "00000000000000000000" & "010" & "111";
                  state := s_probe4;
               end if;
                  
               if(counter = 0) then
                  if(multimatch = '1') then
                     mce <= '1';
                  end if;
                  if(match = '1') then
                     ent_addr <= match_index;
                     state := s_probe2;
                  else -- insert dummy miss entry
                     uent.vpn := vaddr(31 downto 12);
                     uent.asid := asid;
                     uent.g := '0';
                     uent.m := '1';
                     uent.p := '1';
                     state := s_nack;
                  end if;
               end if;
               counter := counter - 1;
            when s_probe2 =>
               state := s_probe3;
            when s_probe3 =>
               ent_q <= ent_r;
               state := s_probe4;
            when s_probe4 =>
               build_uent(tlb_unpack(ent_q));
               if((not CHECK_CAM) or tlb_matches(tlb_unpack(ent_q), vaddr, asid)) then
                  state := s_probe5;
               else
                  -- this shouldn't really happen, but...
                  uent.vpn := vaddr(31 downto 12);
                  uent.asid := asid;
                  uent.g := '0';
                  uent.m := '1';
                  uent.p := '1';
                  state := s_nack;
                  mce <= '1';
               end if;
            when s_probe5 =>
               -- output the utlb entry to the appropriate utlb
               uraw <= utlb_pack(uent);
               do_ack;
               state := s_return;
            when s_nack =>
               uraw <= utlb_pack(uent);
               do_nack;
               state := s_return;
            when s_read1 =>
               state := s_read2;
            when s_read2 =>
               ent_q <= ent_r;
               state := s_read3;
            when s_read3 =>
               cop_ack <= '1';
               state := s_return;
            when s_flushwait =>
               if(inv_all = '0') then
                  tlbw_done <= '1';
                  state := s_return;
               end if;
            when s_return =>
               state := s_idle;
            when s_reset =>
               ent_addr <= ent_addr + 1;
               ent_we <= '1';
               index <= index + 1;
               write <= '1';
               if(all_bits_set(ent_addr)) then
                  state := s_return;
               end if;
            when others =>
               state := s_idle;
         end case;

         if(rst = '1') then
            inv_state := i_idle;
            inv_all <= '0';

            mce <= '0';

            -- initialize entire tlb with virt=0x80000000; can never match
            ent_addr <= (others => '0');
            ent_d <= (others => '-');
            ent_d(tlb_ent_t.mask'range) <= (others => '0');
            ent_d(tlb_ent_t.vpn2'range) <= "1000000000000000000";
            ent_we <= '1';
            index <= (others => '0');
            pattern <= (7 downto 0 => '0') & (18 => '1', 17 downto 0 => '0');
            mask <= (7 downto 0 => '1') & (18 downto 0 => '1');
            write <= '1';
            state := s_reset;
         end if;
      end if;
   end process;
end architecture;
