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


entity z48rqueue is
   generic(
      RESET_VECTOR_MASTER:       word;
      RESET_VECTOR_SLAVE:        word;
      THREADS_LOG2:              natural;
      WINDOW_LOG2:               natural
   );
   port(
      clock:                     in       std_logic;
      reset:                     in       std_logic;

      thread_irq:                in       std_logic_vector((2 ** THREADS_LOG2) - 1 downto 0);

      icache_data:               in       dword;
      icache_flags:              in       icache_flags_t;
      icache_valid:              in       std_logic;

      icache_next_vaddr:         out      word;
      icache_next_thread:        out      std_logic_vector(THREADS_LOG2 - 1 downto 0);
      icache_enable_fetch:       out      std_logic;
   );
end entity;

architecture z48rqueue of z48rqueue is
   constant ABITS:               natural := THREADS_LOG2 + WINDOW_LOG2;
   constant THREADS:             natural := 2 ** THREADS_LOG2;
   constant FLAGS:               natural := 4;
   constant ENT_WIDTH:           natural := FLAGS + 32;

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


   signal thread_next_pc:        word;
   type thread_next_pcs_t is array(THREADS - 1 downto 0) of word;
   signal thread_next_pcs:       thread_next_pcs_t;

   signal icache_cur_thread:     std_logic_vector(THREADS_LOG2 - 1 downto 0);
   signal icache_cur_pcs:        thread_next_pcs_t;
   signal icache_cur_pc:         word;

   signal icache_next_thread:    std_logic_vector(THREADS_LOG2 - 1 downto 0);
   signal icache_next_pc:        word;
   signal icache_next_addr:      word;

   signal queue_fill_next_addr:  std_logic_vector(ABITS - 1 downto 0);
   signal queue_fill_data:       std_logic_vector(ENT_WIDTH * 2 - 1 downto 0);
   signal queue_fill_we:         std_logic;

   signal predec_inst_a:         inst_t;
   signal predec_inst_b:         inst_t;

   subtype queue_ptr_t is std_logic_vector(WINDOW_LOG2 - 1 downto 0);
   subtype queue_ptrs_t is array(THREADS - 1 downto 0) of queue_ptr_t;
   signal queue_fill_ptrs:       queue_ptrs_t;
   signal queue_play_ptrs:       queue_ptrs_t;
   signal queue_commit_ptrs:     queue_ptrs_t;

   subtype queue_play_addr_t is std_logic_vector(ABITS - 1 downto 0);
   signal queue_play_addr_a:     queue_play_addr_t;
   signal queue_play_addr_b:     queue_play_addr_t;
   subtype queue_play_data_t is std_logic_vector(ENT_WIDTH - 1 downto 0);
   signal queue_play_data_a:     queue_play_data_t;
   signal queue_play_data_b:     queue_play_data_t;

   signal thread_has_instrs:     std_logic_vector(THREADS - 1 downto 0);
   signal cur_thread:            std_logic_vector(THREADS_LOG2 - 1 downto 0);
   signal cur_thread_irq:        std_logic;
   signal next_thread:           std_logic_vector(THREADS_LOG2 - 1 downto 0);
begin

   queue_fill_data <=
      flag_pack(icache_flags(1)) & icache_data(63 downto 32) &
      flag_pack(icache_flags(0)) & icache_data(31 downto 0);

   queue_fill_we <= icache_valid;

   icache_cur_pc <= icache_cur_pcs(int(icache_cur_thread));

   predecA: entity work.mipsidec port map(
      iword => icache_data(31 downto 0),
      flags => icache_flags(0),
      thread => icache_cur_thread,
      vaddr => icache_cur_vaddr,

      inst => predec_inst_a
   );
   predecB: entity work.mipsidec port map(
      iword => icache_data(63 downto 32),
      flags => icache_flags(1),
      thread => icache_cur_thread,
      vaddr => icache_cur_vaddr,

      inst => predec_inst_b
   );

   icache_next_thread <= icache_cur_thread + 1;
   icache_next_pc <= (icache_cur_pc(31 downto 2) & "00") + 8;
   icache_next_addr <=
      icache_next_pc when icache_next_thread = icache_cur_thread else
      icache_cur_pcs(int(icache_next_thread));

   queueA: altsyncram generic map(
      WIDTH_A => ENT_WIDTH * 2,
      WIDTHAD_A => ABITS - 1,
      WIDTH_B => ENT_WIDTH,
      WIDTHAD_B => ABITS,
      OPERATION_MODE => "DUAL_PORT"
   )
   port map(
      clock0 => clock,
      clock1 => clock,
      address_a => queue_fill_next_addr(ABITS - 1 downto 1),
      data_a => queue_fill_data,
      wren_a => queue_fill_we,
      address_b => queue_play_addr_a,
      q_b => queue_play_data_a
   );
   queueB: altsyncram generic map(
      WIDTH_A => ENT_WIDTH * 2,
      WIDTHAD_A => ABITS - 1,
      WIDTH_B => ENT_WIDTH,
      WIDTHAD_B => ABITS,
      OPERATION_MODE => "DUAL_PORT"
   )
   port map(
      clock0 => clock,
      clock1 => clock,
      address_a => queue_fill_next_addr(ABITS - 1 downto 1),
      data_a => queue_fill_data,
      wren_a => queue_fill_we,
      address_b => queue_play_addr_b,
      q_b => queue_play_data_b
   );

   idecA: entity work.mipsidec port map(
      iword => queue_play_data_a(31 downto 0),
      flags => flag_unpack(queue_play_data_a(35 downto 32)),
      thread => icache_cur_thread,
      vaddr => icache_cur_vaddr,
      irq => cur_thread_irq,

      inst => queue_inst_a
   );
   idecB: entity work.mipsidec port map(
      iword => queue_play_data_b(31 downto 0),
      flags => flag_unpack(queue_play_data_b(35 downto 32)),
      thread => icache_cur_thread,
      vaddr => icache_cur_vaddr,
      irq => '0',

      inst => queue_inst_b
   );

   per_thread_comb: for i in THREADS - 1 downto 0 loop
      
      thread_has_instrs(i) <=
         '0' when queue_fill_ptrs(i) = queue_play_ptrs(i) else
         '1';
   end generate;
   cur_thread_irq <= thread_irqs(int(cur_thread));


   process(clock) is begin
      if(rising_edge(clock)) then
         if(reset = '1') then
            for i in THREADS - 1 downto 0 loop
               thread_next_pcs(i) <= RESET_VECTOR_SLAVE;
               queue_fill_ptrs(i) <= (others => '0');
               queue_play_ptrs(i) <= (others => '0');
               queue_commit_ptrs(i) <= (others => '0');
            end loop;
            thread_next_pcs(0) <= RESET_VECTOR_MASTER;
         end if;
      end if;
   end process;
end architecture;
