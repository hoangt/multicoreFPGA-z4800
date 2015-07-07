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

library ieee; use ieee.std_logic_1164.all, ieee.std_logic_arith.all;

package z48common is
   subtype word is std_logic_vector(31 downto 0);
   subtype vword is std_logic_vector(32 downto 0);
   subtype dword is std_logic_vector(63 downto 0);
   subtype reg_t is std_logic_vector(4 downto 0);
   type dworda is array(1 downto 0) of word;
   type reg2_t is array(1 downto 0) of reg_t;
   type op_t is (i_nop, i_ssnop, i_lui, i_jr, i_br, i_ld, i_st, i_alu, i_cop0, i_cop1, i_cop2, i_cop3, i_cache, i_sync, i_pflush, i_muldiv, i_trap);
   type aluop_t is (a_nop, a_nop1, a_add, a_sub, a_mul, a_and, a_or, a_nor, a_xor, a_div, a_slt, a_shl, a_sha, a_mtlo, a_mthi, a_mflo, a_mfhi);
   type cond_t is (c_true, c_eq, c_ge, c_lt, c_gt, c_le, c_ne);
   type cop0op_t is (c0_nop, c0_mfc, c0_mtc, c0_tlbp, c0_tlbr, c0_tlbwi, c0_tlbwr, c0_eret);
   type mem_t is (m_none, m_lw, m_lh, m_lb, m_sw, m_sh, m_sb, m_lwl, m_lwr, m_swl, m_swr);
   type trap_t is (t_none, t_invalid, t_int, t_trap, t_syscall, t_break, t_itlb_refill, t_itlb_tlbl, t_itlb_adel);

   type inst_t is record
      valid: std_logic;
      cond: cond_t;
      op: op_t;
      aluop: aluop_t;
      cop0op: cop0op_t;
      mem: mem_t;
      trap: trap_t;
      is_aluop: std_logic;
      source: reg2_t;
      reads: std_logic_vector(1 downto 0);
      dest: reg_t;
      immed: word;
      use_immed: std_logic;
      writes_reg: std_logic;
      u: std_logic;
      has_delay_slot: std_logic;
      in_delay_slot: std_logic;
      in_annul_slot: std_logic;
      right_shift: std_logic;
      late: std_logic;
      cascade0, cascade1: std_logic;
      likely: std_logic;
      trap_ov: std_logic;
      sc: std_logic;
      ll: std_logic;
      noflush: std_logic;
   end record inst_t;
   type preg_t is record
      pc: word;
      pred: std_logic;
      new_pc: word;
      i: inst_t;
   end record preg_t;
   type res_t is record
      valid: std_logic;
      result: vword;
      operand0: word;
      operand1: word;
      d_unaligned: std_logic;
      m_shr: std_logic;
      m_shl: std_logic;
      m_dist: std_logic_vector(1 downto 0);
      eaddr: word;
      v: std_logic;
      z: std_logic;
      n: std_logic;
      predict: std_logic;
      mispredict: std_logic;
      new_pc: word;
      use_new_pc: std_logic;
      t: std_logic;
      nt: std_logic;
      except: std_logic;
      exc: std_logic_vector(4 downto 0);
      except_under_stall: std_logic;
   end record res_t;
   type fwd_t is record
      data: vword;
      dreg: reg_t;
      enable: std_logic;
   end record fwd_t;

   constant MAX_STAGES: integer := 10;

   constant S_NP: integer := 0;
   constant S_IC: integer := 1;
   constant S_DG: integer := 2;
   constant S_RR: integer := 3;
   constant S_EX: integer := 4;

   type pregs_t is array(S_DG to MAX_STAGES) of preg_t;
   type ress_t is array(S_EX to MAX_STAGES) of res_t;
   type p_fwd_t is array(S_EX to MAX_STAGES) of fwd_t;
   type fwds_t is array(0 to 1) of p_fwd_t;

   type snoop_t is record
      pc: word;
      next_pc: word;
      decode_pc0: word;
      decode_pc1: word;
      curpc0: word;
      curpc1: word;
      p4valid0: std_logic;
      p4valid1: std_logic;
      r4valid0: std_logic;
      r4valid1: std_logic;
   end record snoop_t;
   type stat_flags_t is record
      predict, mispredict: std_logic;
      not_stalled: std_logic;
      fwd_hazard, d_mem_halt: std_logic;
      exec: std_logic;
      alustall: std_logic;
      uncond_branch: std_logic;
      compute_branch: std_logic;
      clever_flush: std_logic;
   end record stat_flags_t;
   type exception_t is record
      code: integer range 0 to 31;
      epc: word;
      bd: std_logic;
      raise: std_logic;
      vaddr: word;
      refill: std_logic;
      badvaddr: std_logic;
      ce: integer range 0 to 3;
   end record exception_t;
   type icache_flag_t is record
      itlb_miss: std_logic;
      itlb_invalid: std_logic;
      itlb_permerr: std_logic;
      i_unaligned: std_logic;
   end record;
   type icache_flags_t is array(1 downto 0) of icache_flag_t;

   type std_logic_vector2d is array(natural range <>, natural range <>) of std_logic;

   function array_unpack(x: std_logic_vector;l: natural;s: natural) return std_logic_vector2d;
   function array_pack(x: std_logic_vector2d;l: natural;s: natural) return std_logic_vector;

   subtype tlb_raw_t is std_logic_vector(127 downto 0);
   type tlb_hent_t is record
      pfn: std_logic_vector(25 downto 6);
      c: std_logic_vector(5 downto 3);
      d: std_logic_vector(2 downto 2);
      v: std_logic_vector(1 downto 1);
      g: std_logic_vector(0 downto 0);
   end record;
   type tlb_hpair_t is array(0 to 1) of tlb_hent_t;
   type tlb_ent_t is record
      mask: std_logic_vector(127 downto 109);
      vpn2: std_logic_vector(95 downto 77);
      g: std_logic_vector(76 downto 76);
      asid: std_logic_vector(71 downto 64);

      h: tlb_hpair_t;
   end record;
   function tlb_pack(x: tlb_ent_t) return tlb_raw_t;
   function tlb_unpack(x: tlb_raw_t) return tlb_ent_t;

   type utlb_ent_t is record
      p: std_logic;
      m: std_logic;
      vpn: std_logic_vector(31 downto 12);
      g: std_logic;
      asid: std_logic_vector(7 downto 0);
      pfn: std_logic_vector(31 downto 12);
      c: std_logic_vector(2 downto 0);
      d: std_logic;
      v: std_logic;
   end record;
   subtype utlb_raw_t is std_logic_vector(55 downto 0);
   function utlb_pack(x: utlb_ent_t) return utlb_raw_t;
   function utlb_unpack(x: utlb_raw_t) return utlb_ent_t;
   constant UTLB_P_BIT: integer := utlb_raw_t'high;

   function get_vpn2(x: word) return std_logic_vector;
   
   constant TLBC_UNCACHED: std_logic_vector(2 downto 0) := "010";
   constant TLBC_EXCLUSIVE: std_logic_vector(2 downto 0) := "100";

   -- cop0 stuff
   type mode_t is (M_KERNEL, M_SUPERVISOR, M_USER);

   constant Index:                  integer := 0;
   constant Random:                 integer := 1;
   constant EntryLo0:               integer := 2;
   constant EntryLo1:               integer := 3;
   constant Context:                integer := 4;
   constant PageMask:               integer := 5;
   constant Wired:                  integer := 6;
   constant BadVAddr:               integer := 8;
   constant Count:                  integer := 9;
   constant EntryHi:                integer := 10;
   constant Compare:                integer := 11;
   constant Status:                 integer := 12;
   constant Cause:                  integer := 13;
   constant EPC:                    integer := 14;
   constant PRId:                   integer := 15;
   constant Config:                 integer := 16;

   constant RegImpl:                word := (
      Index => '1',
      Random => '1',
      EntryLo0 => '1',
      EntryLo1 => '1',
      Context => '1',
      PageMask => '1',
      Wired => '1',
      BadVAddr => '1',
      Count => '1',
      EntryHi => '1',
      Compare => '1',
      Status => '1',
      Cause => '1',
      EPC => '1',
      PRId => '1',
      Config => '1',
      others => '0'
   );

   constant STATUS_IE:              integer := 0;
   constant STATUS_EXL:             integer := 1;
   constant STATUS_ERL:             integer := 2;
   constant STATUS_KSU_L:           integer := 3;
   constant STATUS_KSU_H:           integer := 4;
   constant STATUS_UX:              integer := 5;
   constant STATUS_SX:              integer := 6;
   constant STATUS_KX:              integer := 7;
   constant STATUS_IM0:             integer := 8;
   constant STATUS_IM1:             integer := 9;
   constant STATUS_IM2:             integer := 10;
   constant STATUS_IM3:             integer := 11;
   constant STATUS_IM4:             integer := 12;
   constant STATUS_IM5:             integer := 13;
   constant STATUS_IM6:             integer := 14;
   constant STATUS_IM7:             integer := 15;
   constant STATUS_DE:              integer := 16;
   constant STATUS_CE:              integer := 17;
   constant STATUS_CH:              integer := 18;
   constant STATUS_SR:              integer := 20;
   constant STATUS_TS:              integer := 21;
   constant STATUS_BEV:             integer := 22;
   constant STATUS_RE:              integer := 25;
   constant STATUS_FR:              integer := 26;
   constant STATUS_RP:              integer := 27;
   constant STATUS_CU0:             integer := 28;
   constant STATUS_CU1:             integer := 29;
   constant STATUS_CU2:             integer := 30;
   constant STATUS_CU3:             integer := 31;

   constant CAUSE_EXC_L:            integer := 2;
   constant CAUSE_EXC_H:            integer := 6;
   constant CAUSE_IP0:              integer := 8;
   constant CAUSE_IP1:              integer := 9;
   constant CAUSE_IP2:              integer := 10;
   constant CAUSE_IP3:              integer := 11;
   constant CAUSE_IP4:              integer := 12;
   constant CAUSE_IP5:              integer := 13;
   constant CAUSE_IP6:              integer := 14;
   constant CAUSE_IP7:              integer := 15;
   constant CAUSE_CE_L:             integer := 28;
   constant CAUSE_CE_H:             integer := 29;
   constant CAUSE_BD:               integer := 31;

   constant EXC_INT:                integer := 0;
   constant EXC_MOD:                integer := 1;
   constant EXC_TLBL:               integer := 2;
   constant EXC_TLBS:               integer := 3;
   constant EXC_ADEL:               integer := 4;
   constant EXC_ADES:               integer := 5;
   constant EXC_IBE:                integer := 6;
   constant EXC_DBE:                integer := 7;
   constant EXC_SYS:                integer := 8;
   constant EXC_BP:                 integer := 9;
   constant EXC_RI:                 integer := 10;
   constant EXC_CPU:                integer := 11;
   constant EXC_OV:                 integer := 12;
   constant EXC_TR:                 integer := 13;
   constant EXC_VCEI:               integer := 14;
   constant EXC_FPE:                integer := 15;
   constant EXC_WATCH:              integer := 23;
   constant EXC_VCED:               integer := 31;

   function fact(x: integer) return integer;
   function log2c(x: integer) return integer;
   function ffs(x: std_logic_vector) return integer;
   function ffc(x: std_logic_vector) return integer;
   function tlb_entmask_to_cmpmask(x: std_logic_vector(31 downto 13)) return std_logic_vector;
   function tlb_entmask_to_xlatmask(x: std_logic_vector(31 downto 13)) return std_logic_vector;
   function tlb_matches(x: tlb_ent_t; a: word; as: std_logic_vector(7 downto 0)) return boolean;
   function int(x: std_logic_vector) return integer;
   function vec(x: integer; n: integer) return std_logic_vector;

   type regport_addr_t is array(integer range <>) of reg_t;
   type regport_data_t is array(integer range <>) of vword;
   type worda_t is array(integer range <>) of word;
   type worda2d_t is array(integer range <>, integer range <>) of word;
   type intarray_t is array(integer range <>) of integer;

   constant CACHE_STATE_BITS: natural := 3;

   subtype snoop_req_t is std_logic_vector(CACHE_STATE_BITS + 32 - 1 downto 0);
   subtype snoop_ack_t is std_logic_vector(CACHE_STATE_BITS - 1 downto 0);
   type snoop_reqa_t is array(integer range <>) of snoop_req_t;
   type snoop_acka_t is array(integer range <>) of snoop_ack_t;

   subtype cache_state_t is std_logic_vector(CACHE_STATE_BITS - 1 downto 0);
   constant T_STATE_INVALID:     std_logic_vector := "000";
   constant T_STATE_SHARED:      std_logic_vector := "001";
   constant T_STATE_EXCLUSIVE:   std_logic_vector := "010";
   constant T_STATE_MODIFIED:    std_logic_vector := "011";
   constant T_STATE_LOCKED:      std_logic_vector := "100";

   function cache_state_test_access_ok(curstate: cache_state_t; minstate: cache_state_t) return boolean;
   function cache_state_test_at_least(curstate: cache_state_t; minstate: cache_state_t) return boolean;
   function cache_state_test_less_than(curstate: cache_state_t; minstate: cache_state_t) return boolean;
   function cache_state_test_eq(curstate: cache_state_t; minstate: cache_state_t) return boolean;
   function cache_state_test_locked(state: cache_state_t) return boolean;
   function cache_state_test_unlocked(state: cache_state_t) return boolean;
   function cache_state_lock(curstate: cache_state_t) return cache_state_t;
   function cache_state_unlock(curstate: cache_state_t) return cache_state_t;

   function all_bits_set(x: std_logic_vector) return boolean;
   function all_bits_clear(x: std_logic_vector) return boolean;
   function any_bit_set(x: std_logic_vector) return boolean;
   function any_bit_clear(x: std_logic_vector) return boolean;

   function compare_eq(x: std_logic_vector; y: std_logic_vector) return boolean;
   function compare_ne(x: std_logic_vector; y: std_logic_vector) return boolean;
   function compare_gt(x: std_logic_vector; y: std_logic_vector) return boolean;
   function compare_ge(x: std_logic_vector; y: std_logic_vector) return boolean;
   function compare_lt(x: std_logic_vector; y: std_logic_vector) return boolean;
   function compare_le(x: std_logic_vector; y: std_logic_vector) return boolean;

   function sdc_multicycle_voodoo(reg_name: string; cycles: integer) return string;
end package z48common;

package body z48common is
   function array_unpack(x: std_logic_vector;l: natural;s: natural) return std_logic_vector2d is
      variable ret: std_logic_vector2d(l - 1 downto 0, s - 1 downto 0);
   begin
      for i in 0 to l - 1 loop
         for j in 0 to s - 1 loop
            ret(i, j) := x(i * s + j);
         end loop;
      end loop;
      return ret;
   end function;

   function array_pack(x: std_logic_vector2d;l: natural;s: natural) return std_logic_vector is
      variable ret: std_logic_vector(l * s - 1 downto 0);
      variable k: integer;
   begin
      k := 0;
      for i in 0 to l - 1 loop
         for j in 0 to s - 1 loop
            ret(k) := x(i, j);
            k := k + 1;
         end loop;
      end loop;
      return ret;
   end function;

   function tlb_pack(x: tlb_ent_t) return tlb_raw_t is
      variable t: tlb_raw_t;
   begin
      t := (others => '0');
      t(x.mask'range) := x.mask;
      t(x.vpn2'range) := x.vpn2;
      t(x.g'range) := x.g;
      t(x.asid'range) := x.asid;

      t(x.h(0).pfn'high + 0 downto x.h(0).pfn'low + 0) := x.h(0).pfn;
      t(x.h(0).c'high + 0 downto x.h(0).c'low + 0) := x.h(0).c;
      t(x.h(0).d'high + 0 downto x.h(0).d'low + 0) := x.h(0).d;
      t(x.h(0).v'high + 0 downto x.h(0).v'low + 0) := x.h(0).v;
      t(x.h(0).g'high + 0 downto x.h(0).g'low + 0) := x.h(0).g;

      t(x.h(1).pfn'high + 32 downto x.h(1).pfn'low + 32) := x.h(1).pfn;
      t(x.h(1).c'high + 32 downto x.h(1).c'low + 32) := x.h(1).c;
      t(x.h(1).d'high + 32 downto x.h(1).d'low + 32) := x.h(1).d;
      t(x.h(1).v'high + 32 downto x.h(1).v'low + 32) := x.h(1).v;
      t(x.h(1).g'high + 32 downto x.h(1).g'low + 32) := x.h(1).g;

      return t;
   end function;

   function tlb_unpack(x: tlb_raw_t) return tlb_ent_t is
      variable t: tlb_ent_t;
   begin
      t.mask := x(t.mask'range);
      t.vpn2 := x(t.vpn2'range);
      t.g := x(t.g'range);
      t.asid := x(t.asid'range);

      t.h(0).pfn := x(t.h(0).pfn'high + 0 downto t.h(0).pfn'low + 0);
      t.h(0).c := x(t.h(0).c'high + 0 downto t.h(0).c'low + 0);
      t.h(0).d := x(t.h(0).d'high + 0 downto t.h(0).d'low + 0);
      t.h(0).v := x(t.h(0).v'high + 0 downto t.h(0).v'low + 0);
      t.h(0).g := x(t.h(0).g'high + 0 downto t.h(0).g'low + 0);

      t.h(1).pfn := x(t.h(1).pfn'high + 32 downto t.h(1).pfn'low + 32);
      t.h(1).c := x(t.h(1).c'high + 32 downto t.h(1).c'low + 32);
      t.h(1).d := x(t.h(1).d'high + 32 downto t.h(1).d'low + 32);
      t.h(1).v := x(t.h(1).v'high + 32 downto t.h(1).v'low + 32);
      t.h(1).g := x(t.h(1).g'high + 32 downto t.h(1).g'low + 32);

      return t;
   end function;

   function utlb_pack(x: utlb_ent_t) return utlb_raw_t is
      variable t: utlb_raw_t;
      variable i: integer range t'high + 1 downto t'low;
   begin
      i := 0;

      t(i) := x.v; i := i + 1;
      t(i) := x.d; i := i + 1;
      t(i + 2 downto i) := x.c; i := i + 3;
      t(i + 19 downto i) := x.pfn; i := i + 20;
      t(i + 7 downto i) := x.asid; i := i + 8;
      t(i) := x.g; i := i + 1;
      t(i + 19 downto i) := x.vpn; i := i + 20;
      t(i) := x.m; i := i + 1;

      t(UTLB_P_BIT) := x.p;

      return t;
   end function;

   function utlb_unpack(x: utlb_raw_t) return utlb_ent_t is
      variable t: utlb_ent_t;
      variable i: integer range x'high + 1 downto x'low;
   begin
      i := 0;

      t.v := x(i); i := i + 1;
      t.d := x(i); i := i + 1;
      t.c := x(i + 2 downto i); i := i + 3;
      t.pfn := x(i + 19 downto i); i := i + 20;
      t.asid := x(i + 7 downto i); i := i + 8;
      t.g := x(i); i := i + 1;
      t.vpn := x(i + 19 downto i); i := i + 20;
      t.m := x(i); i := i + 1;

      t.p := x(UTLB_P_BIT);

      return t;
   end function;

   function get_vpn2(x: word) return std_logic_vector is begin
      return x(31 downto 13);
   end function;

   function fact(x: integer) return integer is
      variable ret: integer := 1;
   begin
      for i in x downto 2 loop
         ret := ret * i;
      end loop;
      return ret;
   end function;

   -- log2c rounds up when called for non-power-of-2 values; in other
   -- words, log2c(n) returns the number of bits to represent n as an
   -- unsigned binary value (or, the ceil of the floating-point log2)
   function log2c(x: integer) return integer is
      variable ret: integer := 0;
      variable i: integer := 1;
   begin
      -- this implementation may look clumsy, but it's intended to
      -- be evaluated only at compile time to determine static bounds;
      -- performance is irrelevant
      while(i < x) loop
         i := i * 2;
         ret := ret + 1;
      end loop;
      return ret;
   end function;

   function ffs(x: std_logic_vector) return integer is begin
      for i in x'low to x'high loop
         if(x(i) = '1') then
            return i;
         end if;
      end loop;
      return x'low;
   end function;
   function ffc(x: std_logic_vector) return integer is begin
      for i in x'low to x'high loop
         if(x(i) = '0') then
            return i;
         end if;
      end loop;
      return x'low;
   end function;

   function tlb_entmask_to_cmpmask(x: std_logic_vector(31 downto 13)) return std_logic_vector is begin
      return x;
   end function;
   function tlb_entmask_to_xlatmask(x: std_logic_vector(31 downto 13)) return std_logic_vector is begin
      return '0' & x;
   end function;

   function tlb_matches(x: tlb_ent_t; a: word; as: std_logic_vector(7 downto 0)) return boolean is begin
      return   (
                  (x.vpn2 and not tlb_entmask_to_cmpmask(x.mask)) = (get_vpn2(a) and not tlb_entmask_to_cmpmask(x.mask))
               ) and (
                  (x.g = "1") or (x.asid = as)
               );
   end function;
   function int(x: std_logic_vector) return integer is begin
      return conv_integer(unsigned(x));
   end function;
   function vec(x: integer; n: integer) return std_logic_vector is begin
      return conv_std_logic_vector(x, n);
   end function;

   function cache_state_test_access_ok(curstate: cache_state_t; minstate: cache_state_t) return boolean is begin
      return cache_state_test_unlocked(curstate) and cache_state_test_at_least(curstate, minstate);
   end function;
   function cache_state_test_at_least(curstate: cache_state_t; minstate: cache_state_t) return boolean is begin
      return compare_ge(cache_state_unlock(curstate), cache_state_unlock(minstate));
   end function;
   function cache_state_test_less_than(curstate: cache_state_t; minstate: cache_state_t) return boolean is begin
      return not cache_state_test_at_least(curstate, minstate);
   end function;
   function cache_state_test_eq(curstate: cache_state_t; minstate: cache_state_t) return boolean is begin
      return cache_state_unlock(curstate) = cache_state_unlock(minstate);
   end function;
   function cache_state_test_locked(state: cache_state_t) return boolean is begin
      return   ((state and not T_STATE_LOCKED) /= T_STATE_INVALID) and
               ((state and T_STATE_LOCKED) = T_STATE_LOCKED);
   end function;
   function cache_state_test_unlocked(state: cache_state_t) return boolean is begin
      return not cache_state_test_locked(state);
   end function;
   function cache_state_lock(curstate: cache_state_t) return cache_state_t is begin
      return curstate or T_STATE_LOCKED;
   end function;
   function cache_state_unlock(curstate: cache_state_t) return cache_state_t is begin
      return curstate and not T_STATE_LOCKED;
   end function;

   function all_bits_set(x: std_logic_vector) return boolean is begin
      return x = (x'range => '1');
   end function;
   function all_bits_clear(x: std_logic_vector) return boolean is begin
      return x = (x'range => '0');
   end function;
   function any_bit_set(x: std_logic_vector) return boolean is begin
      return not all_bits_clear(x);
   end function;
   function any_bit_clear(x: std_logic_vector) return boolean is begin
      return not all_bits_set(x);
   end function;

   function compare_eq(x: std_logic_vector; y: std_logic_vector) return boolean is begin
      assert(x'length = y'length) report "Vectors have mismatched lengths" severity error;
      return x = y;
   end function;
   function compare_ne(x: std_logic_vector; y: std_logic_vector) return boolean is begin
      return not compare_eq(x, y);
   end function;
   function compare_gt(x: std_logic_vector; y: std_logic_vector) return boolean is begin
      assert(x'length = y'length) report "Vectors have mismatched lengths" severity error;
      return int(x) > int(y);
   end function;
   function compare_ge(x: std_logic_vector; y: std_logic_vector) return boolean is begin
      assert(x'length = y'length) report "Vectors have mismatched lengths" severity error;
      return int(x) >= int(y);
   end function;
   function compare_lt(x: std_logic_vector; y: std_logic_vector) return boolean is begin
      assert(x'length = y'length) report "Vectors have mismatched lengths" severity error;
      return int(x) < int(y);
   end function;
   function compare_le(x: std_logic_vector; y: std_logic_vector) return boolean is begin
      assert(x'length = y'length) report "Vectors have mismatched lengths" severity error;
      return int(x) <= int(y);
   end function;

   function sdc_multicycle_voodoo(reg_name: string; cycles: integer) return string is begin
      return
         "MULTICYCLE=" & integer'image(cycles) & ";" &
         "SDC_STATEMENT=""set_multicycle_path -end -setup -to [get_registers *|muldiv:*|" & reg_name & "*] " & integer'image(cycles) & """" & ";" &
         "SDC_STATEMENT=""set_multicycle_path -end -hold -to [get_registers *|muldiv:*|" & reg_name & "*] " & integer'image(cycles - 1) & """";
   end function;
end package body;
