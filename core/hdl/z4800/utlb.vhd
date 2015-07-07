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


entity utlb is
   generic(
      OFFSET_BITS:               natural;
      WAYS:                      natural;
      REPLACE_TYPE:              string;
      SUB_REPLACE_TYPE:          string;
      HYBRID_BLOCK_FACTOR:       natural;
      POISON_INVALID_MAPPINGS:   boolean := false
   );
   port(
      clock:                     in std_logic;
      rst:                       in std_logic;
      addrstall:                 in std_logic := '0';

      vaddr:                     in word;
      probe:                     in std_logic := '1';
      kill:                      in std_logic := '0';
      write:                     in std_logic := '0';
      asid:                      in std_logic_vector(7 downto 0);
      mode:                      in mode_t;

      jtlb_vaddr:                buffer word;
      jtlb_probe:                buffer std_logic;
      jtlb_ack:                  in std_logic;
      jtlb_nack:                 in std_logic;
      jtlb_ent:                  in utlb_raw_t;
      jtlb_inv_addr:             in std_logic_vector(OFFSET_BITS - 1 downto 0);
      jtlb_inv:                  in std_logic;

      paddr:                     out word;
      stall:                     buffer std_logic;
      miss:                      buffer std_logic;
      invalid:                   buffer std_logic;
      modified:                  buffer std_logic;
      cacheable:                 buffer std_logic;
      permerr:                   buffer std_logic;
      mapped:                    buffer std_logic;
      fault:                     buffer std_logic;

      perf_hit:                  out std_logic;
      perf_miss:                 out std_logic
   );
end entity;

architecture utlb of utlb is
   constant WAY_BITS:            integer := log2c(WAYS);

   type utlb_q_t is array(WAYS - 1 downto 0) of utlb_raw_t;
   signal q:                     utlb_q_t;
   type utlb_e_t is array(WAYS - 1 downto 0) of utlb_ent_t;
   signal e:                     utlb_e_t;
   signal d, d_a:                utlb_raw_t;
   signal we:                    std_logic_vector(WAYS - 1 downto 0);
   signal addr_a, addr_b, addr_f:std_logic_vector(OFFSET_BITS - 1 downto 0);
   signal as_b:                  std_logic;

   signal e_present, e_match, e_invalid, e_dirty, e_permok, e_cacheable, e_miss: std_logic_vector(WAYS - 1 downto 0);
   signal e_paddr:               worda_t(WAYS - 1 downto 0);
   signal m_valid, m_match, m_invalid, m_dirty, m_permok, m_cacheable, m_miss: std_logic;
   signal m_paddr:               word;
   signal m_index:               integer range WAYS - 1 downto 0;

   signal raddr:                 word;
   signal rasid:                 std_logic_vector(7 downto 0);

   function offset(x: std_logic_vector) return std_logic_vector is begin
      return x(OFFSET_BITS - 1 + 12 downto 12);
   end function;

   signal jtlb_miss:             std_logic;
   signal access_ok:             std_logic;
   signal replace_way:           std_logic_vector(WAY_BITS - 1 downto 0);
   signal init_wait:             std_logic;
begin
   sets: for i in q'range generate
      -- raw set RAM
      set: altsyncram generic map(
         WIDTH_A => d'length,
         WIDTHAD_A => OFFSET_BITS,
         WIDTH_B => d'length,
         WIDTHAD_B => OFFSET_BITS,
         OPERATION_MODE => "DUAL_PORT"
      )
      port map(
         clock0 => clock,
         clock1 => clock,
         address_a => addr_a,
         address_b => addr_b,
         addressstall_b => as_b,
         q_b => q(i),
         data_a => d_a,
         wren_a => we(i) or jtlb_inv
      );
      inv_mux: process(d, jtlb_inv, jtlb_inv_addr, addr_f) is begin
         addr_a <= addr_f;
         d_a <= d;
         if(jtlb_inv = '1') then
            addr_a <= jtlb_inv_addr;
            d_a(UTLB_P_BIT) <= '0';
         end if;
      end process;

      -- per-way comparison and translation logic
      e(i) <= utlb_unpack(q(i));
      e_present(i) <= e(i).p;
      e_match(i) <=
         '1' when
            compare_eq(
               e(i).vpn(31 downto 12 + OFFSET_BITS),
               raddr(31 downto 12 + OFFSET_BITS)
            ) and (
               e(i).g = '1' or
               compare_eq(e(i).asid, asid)
            )
         else '0';
      e_invalid(i) <= not e(i).v;
      e_dirty(i) <= e(i).d;
      e_permok(i) <=
         '0' when mode = M_USER and raddr(31) = '1' else
         '1' when mode = M_SUPERVISOR and raddr(31) = '0' else
         '1' when mode = M_SUPERVISOR and raddr(31 downto 29) = "110" else
         '0' when mode = M_SUPERVISOR else
         '1';
      e_cacheable(i) <= '0' when e(i).c = TLBC_UNCACHED else '1';
      e_paddr(i) <= e(i).pfn & raddr(11 downto 0);
      e_miss(i) <= e(i).m;
   end generate;

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

      ref_addr => offset(raddr),
      ref_way => vec(m_index, WAY_BITS),
      ref_valid => probe and m_match,

      fill_addr => offset(raddr),
      fill_way => replace_way
   );

   -- mux all sets down to one result
   process(init_wait, e_present, e_match, e_invalid, e_dirty, e_permok, e_cacheable, e_paddr, e_miss) is begin
      m_match <= '0';
      m_invalid <= '0';
      m_dirty <= '0';
      m_permok <= '0';
      m_cacheable <= '1';
      m_paddr <= (others => '-');
      m_miss <= '0';
      m_index <= 0;
      for i in e'range loop
         if(e_present(i) = '1' and e_match(i) = '1') then
            m_match <= '1';
            m_invalid <= e_invalid(i);
            m_dirty <= e_dirty(i);
            m_permok <= e_permok(i);
            m_cacheable <= e_cacheable(i);
            m_paddr <= e_paddr(i);
            m_miss <= e_miss(i);
            m_index <= i;
         end if;
      end loop;
      if(init_wait = '1') then
         m_match <= '0';
      end if;
   end process;

   -- internal RAM inputs
   as_b <= addrstall;
   addr_b <= offset(vaddr);

   -- outputs
   paddr <= x"5baddab5" when POISON_INVALID_MAPPINGS and mapped = '0' else m_paddr;
   stall <= probe and not m_match;
   invalid <= probe and m_match and m_invalid and not miss;
   modified <= probe and m_match and write and not m_dirty and not miss;
   cacheable <= m_match and m_cacheable;
   permerr <= probe and m_match and not m_permok and not miss;
   miss <=  probe and m_match and m_miss;
   access_ok <= not (
      miss or
      m_invalid or
      (write and not m_dirty) or
      (not m_permok)
   );
   mapped <= probe and m_match and access_ok;
   fault <= probe and m_match and not access_ok;

   -- controlling state machine
   process(clock) is
      type state_t is (s_idle, s_probe, s_return1, s_return2, s_reset);
      variable state: state_t;
      variable way: integer range 0 to WAYS - 1;
      variable uent: utlb_ent_t;
   begin
      if(rising_edge(clock)) then
         we <= (others => '0');
         jtlb_miss <= '0';
         if(addrstall = '0') then
            raddr <= vaddr;
            rasid <= asid;
         end if;

         case state is
            when s_idle =>
               if(stall = '1' and kill = '0') then
                  addr_f <= offset(raddr);
                  jtlb_vaddr <= raddr;
                  jtlb_probe <= '1';
                  state := s_probe;
               end if;
            when s_probe =>
               d <= jtlb_ent;
               if(jtlb_ack = '1' or jtlb_nack = '1') then
                  we(int(replace_way)) <= '1';
                  if(jtlb_nack = '1' and jtlb_vaddr = raddr) then
                     jtlb_miss <= '1';
                  end if;
                  jtlb_probe <= '0';
                  state := s_return1;
               end if;
            when s_return1 =>
               state := s_return2;
            when s_return2 =>
               init_wait <= '0';
               state := s_idle;
            when s_reset =>
               if(jtlb_inv = '0') then
                  addr_f <= addr_f + 1;
                  we <= (others => '1');
                  if(all_bits_set(addr_f)) then
                     state := s_return1;
                  end if;
               else
                  we <= (others => '1'); -- retry write, jtlb stole our port
               end if;
            when others =>
               state := s_idle;
         end case;

         if(rst = '1') then
            state := s_reset;
            jtlb_probe <= '0';
            jtlb_miss <= '0';
            d(UTLB_P_BIT) <= '0';
            addr_f <= (others => '0');
            we <= (others => '1');
            init_wait <= '1';
         end if;
      end if;
   end process;

   perf_hit <= probe and not addrstall and not miss;
   perf_miss <= probe and not addrstall and miss;
end architecture;
