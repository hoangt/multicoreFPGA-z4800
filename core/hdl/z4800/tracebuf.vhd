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

library ieee, lpm, z48common;
use ieee.std_logic_1164.all, ieee.std_logic_unsigned.all, ieee.std_logic_arith.all, lpm.lpm_components.all, z48common.z48common.all;

entity tracebuf is
   generic(
      TRACE_LENGTH:                 integer
   );
   port( 
      reset:                        in std_logic;
      clock:                        in std_logic;

      mem_addr:                     in std_logic_vector(15 downto 0);
      mem_in:                       in word;
      mem_out:                      out word;
      mem_be:                       in std_logic_vector(3 downto 0);
      mem_rd:                       in std_logic;
      mem_wr:                       in std_logic;
      mem_halt:                     out std_logic;

      p0p, p1p:                     in preg_t;
      p0r, p1r:                     in res_t;

      uto:                          in std_logic
   );
end entity;

architecture tracebuf of tracebuf is
   signal read_ad:                  regport_addr_t(0 downto 0);
   signal read_data:                regport_data_t(0 downto 0);

   signal write_ad:                 regport_addr_t(2 downto 0);
   signal write_data:               regport_data_t(2 downto 0);
   signal write_en:                 std_logic_vector(2 downto 0);

   type pa_t is array(1 downto 0) of preg_t;
   type ra_t is array(1 downto 0) of res_t;
   signal p:                        pa_t;
   signal r:                        ra_t;

   constant TRACE_EWIDTH:           integer := 256;
   constant TRACE_DWIDTH:           integer := 32;
   constant TRACE_ELENGTH:          integer := TRACE_LENGTH;
   constant TRACE_DLENGTH:          integer := TRACE_LENGTH * TRACE_EWIDTH / TRACE_DWIDTH;
   constant TRACE_EADDRBITS:        integer := log2c(TRACE_ELENGTH);
   constant TRACE_DADDRBITS:        integer := log2c(TRACE_DLENGTH);

   signal t_d_a, t_q_b:             std_logic_vector(TRACE_EWIDTH - 1 downto 0);
   signal t_q_c:                    std_logic_vector(TRACE_DWIDTH - 1 downto 0);
   signal t_addr_a, t_addr_b:       std_logic_vector(TRACE_EADDRBITS - 1 downto 0);
   signal t_addr_cur, t_addr_next:  std_logic_vector(TRACE_EADDRBITS - 1 downto 0);
   signal t_addr_s:                 std_logic_vector(TRACE_DADDRBITS - 1 downto 0);
   signal t_we_a:                   std_logic;

   subtype th_t is std_logic_vector(95 downto 0);
   type ta_t is array(1 downto 0) of th_t;
   signal t, told:                  ta_t;
   subtype nb_t is std_logic_vector(32 + 1 + 5 - 1 downto 0);
   signal nb, nbold:                nb_t;
   signal mem_addr_r:               std_logic_vector(mem_addr'range);
begin
   p(0) <= p0p;
   p(1) <= p1p;
   r(0) <= p0r;
   r(1) <= p1r;

   shadowregs: entity work.altregfile generic map(
      WRITE_PORTS => 3,
      READ_PORTS => 1,
      MIXED_BYPASS => false
   )
   port map(
      clock => clock,
      reset => reset,

      read_ad => read_ad,
      read_data => read_data,
      read_as => (others => '0'),

      write_ad => write_ad,
      write_data => write_data,
      write_en => write_en
   );

   tracebuf_a: entity work.ramwrap generic map(
      WIDTH_A => TRACE_EWIDTH,
      WIDTHAD_A => TRACE_EADDRBITS,
      NUMWORDS_A => TRACE_ELENGTH,
      WIDTH_B => TRACE_EWIDTH,
      WIDTHAD_B => TRACE_EADDRBITS,
      NUMWORDS_B => TRACE_ELENGTH,
      OPERATION_MODE => "DUAL_PORT"
   )
   port map(
      clock0 => clock,
      clock1 => clock,
      address_a => t_addr_a,
      address_b => t_addr_b,
      data_a => t_d_a,
      q_b => t_q_b,
      wren_a => t_we_a
   );
   tracebuf_b: entity work.ramwrap generic map(
      WIDTH_A => TRACE_EWIDTH,
      WIDTHAD_A => TRACE_EADDRBITS,
      NUMWORDS_A => TRACE_ELENGTH,
      WIDTH_B => TRACE_DWIDTH,
      WIDTHAD_B => TRACE_DADDRBITS,
      NUMWORDS_B => TRACE_DLENGTH,
      OPERATION_MODE => "DUAL_PORT"
   )
   port map(
      clock0 => clock,
      clock1 => clock,
      address_a => t_addr_a,
      address_b => t_addr_s,
      data_a => t_d_a,
      q_b => t_q_c,
      wren_a => t_we_a
   );

   t_d_a(t(0)'high downto t(0)'low) <= t(0);
   t_d_a(t(1)'high + t(0)'length downto t(1)'low + t(0)'length) <= t(1);
   --nb <= nbf.dreg & nbf.enable & nbf.data(31 downto 0);
   nb <= (others => '0');
   t_d_a(nb'high + t(1)'length + t(0)'length downto nb'low + t(1)'length + t(0)'length) <= nb;

   t_we_a <=
      '0' when uto = '1' and p(0).pc(31) = '1' and p(1).pc(31) = '1' else
      p(0).i.valid or p(1).i.valid or r(0).except or r(1).except; -- or nbf.enable;
   t_addr_next <= t_addr_cur + 1 when t_we_a = '1' else t_addr_cur;
   t_addr_s <= mem_addr(t_addr_s'high downto t_addr_s'low);
   t_addr_a <= t_addr_next;
   t_addr_b <= t_addr_cur + 1;

   read_ad(0) <= mem_addr(read_ad(0)'high downto read_ad(0)'low);
   mem_out <=  t_q_c when mem_addr_r(mem_addr_r'high) = '1' else
               read_data(0)(31 downto 0) when mem_addr_r(mem_addr_r'high downto 5) = (mem_addr_r'high downto 5 => '0') else
               (31 downto t_addr_cur'length => '0') & t_addr_cur when mem_addr_r(4 downto 0) = "00000" else
               vec(TRACE_LENGTH, 32) when mem_addr_r(4 downto 0) = "00001" else
               (others => '-');
               
   mem_halt <= '0';

   told(0) <= t_q_b(told(0)'high downto told(0)'low);
   told(1) <= t_q_b(told(1)'high + told(0)'length downto told(1)'low + told(0)'length);
   nbold <= t_q_b(nbold'high + told(1)'length + told(0)'length downto nbold'low + told(1)'length + told(0)'length);

   write_data(0) <= told(0)(64 downto 32);
   write_ad(0) <= told(0)(69 downto 65);
   write_en(0) <= told(0)(70) and told(0)(83);
   write_data(1) <= told(1)(64 downto 32);
   write_ad(1) <= told(1)(69 downto 65);
   write_en(1) <= told(1)(70) and told(1)(83);

   write_data(2) <= nbold(32 downto 0);
   write_ad(2) <= nbold(37 downto 33);
   write_en(2) <= nbold(32);

   process(clock) is begin
      if(rising_edge(clock)) then
         t_addr_cur <= t_addr_next;
         mem_addr_r <= mem_addr;

         -- synch reset
         if(reset = '1') then
            t_addr_cur <= (others => '1');
         end if;
      end if;
   end process;

   process(p, r) is
      variable j: integer;
   begin
      t <= (others => (others => '0'));
      for i in t'range loop
         j := 0;

         t(i)(31 + j downto j) <= p(i).pc; j := j + 32;

         t(i)(31 + j downto j) <= r(i).result(31 downto 0); j := j + 32;
         t(i)(j) <= r(i).result(32); j := j + 1;

         t(i)(4 + j downto j) <= p(i).i.dest; j := j + 5;
         t(i)(j) <= p(i).i.writes_reg; j := j + 1;
         t(i)(4 + j downto j) <= p(i).i.source(0); j := j + 5;
         t(i)(j) <= p(i).i.reads(0); j := j + 1;
         t(i)(4 + j downto j) <= p(i).i.source(1); j := j + 5;
         t(i)(j) <= p(i).i.reads(1); j := j + 1;
         t(i)(j) <= r(i).valid; j := j + 1;
         t(i)(j) <= p(i).i.valid; j := j + 1;
         t(i)(j) <= p(i).pred; j := j + 1;
         t(i)(4 + j downto j) <= r(i).exc; j := j + 5;
         t(i)(j) <= p(i).i.in_delay_slot; j := j + 1;
         t(i)(j) <= p(i).i.likely; j := j + 1;
         t(i)(j) <= r(i).predict; j := j + 1;
         t(i)(j) <= r(i).mispredict; j := j + 1;
         t(i)(j) <= r(i).except; j := j + 1;
      end loop;
   end process;
end architecture;
