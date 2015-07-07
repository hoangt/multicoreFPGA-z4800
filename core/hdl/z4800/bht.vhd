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

entity bht is
   generic(
      BITS:                         natural;
      TABLE_SIZE:                   natural;
      INIT_STATE:                   std_logic_vector
   );
   port(
      clk:                          in    std_logic;
      rst:                          in    std_logic;
      
      a_nexpc:                      in    word;
      a_prediction:                 out   std_logic;
      b_nexpc:                      in    word;
      b_prediction:                 out   std_logic;

      t:                            in    std_logic;
      nt:                           in    std_logic;
      pred_pc:                      in    word
   );
end entity;

architecture bht of bht is
   constant ADDRBITS:               natural := log2c(TABLE_SIZE);

   signal hist_addr_a, hist_addr_b: std_logic_vector(ADDRBITS - 1 downto 0);
   signal hist_addr_c, hist_addr_d: std_logic_vector(ADDRBITS - 1 downto 0);
   signal hist_q_a, hist_q_b, hist_q_c, hist_data_d: std_logic_vector(BITS - 1 downto 0);
   signal a_hist, b_hist, hist_data: std_logic_vector(BITS - 1 downto 0);
   signal hist_we_d:                std_logic;

   signal pred_pc_r:                word;
   signal t_r, nt_r:                std_logic;

   function saturating_inc(x: std_logic_vector) return std_logic_vector is
      variable r: std_logic_vector(x'range);
   begin
      r := x;
      if(any_bit_clear(r)) then
         r := r + 1;
      end if;
      return r;
   end function;

   function saturating_dec(x: std_logic_vector) return std_logic_vector is
      variable r: std_logic_vector(x'range);
   begin
      r := x;
      if(any_bit_set(r)) then
         r := r - 1;
      end if;
      return r;
   end function;

   function addr_hash(addr: std_logic_vector) return std_logic_vector is
      constant ADDRL: natural := 3;
      constant ADDRH: natural := ADDRL + ADDRBITS - 1;
      variable a: std_logic_vector(ADDRBITS - 1 downto 0);
   begin
      a := addr(ADDRH downto ADDRL);
      return a;
   end function;
begin
   bhta: entity work.ramwrap generic map(
      WIDTH_A => BITS,
      WIDTHAD_A => ADDRBITS,
      WIDTH_B => BITS,
      WIDTHAD_B => ADDRBITS,
      MIXED_PORT_FORWARDING => true,
      OPERATION_MODE => "DUAL_PORT"
   )
   port map(
      clock0 => clk,
      clock1 => clk,
      address_a => hist_addr_d,
      address_b => hist_addr_a,
      data_a => hist_data_d,
      wren_a => hist_we_d,
      q_b => hist_q_a
   );
   bhtb: entity work.ramwrap generic map(
      WIDTH_A => BITS,
      WIDTHAD_A => ADDRBITS,
      WIDTH_B => BITS,
      WIDTHAD_B => ADDRBITS,
      MIXED_PORT_FORWARDING => true,
      OPERATION_MODE => "DUAL_PORT"
   )
   port map(
      clock0 => clk,
      clock1 => clk,
      address_a => hist_addr_d,
      address_b => hist_addr_b,
      data_a => hist_data_d,
      wren_a => hist_we_d,
      q_b => hist_q_b
   );
   bhtc: entity work.ramwrap generic map(
      WIDTH_A => BITS,
      WIDTHAD_A => ADDRBITS,
      WIDTH_B => BITS,
      WIDTHAD_B => ADDRBITS,
      MIXED_PORT_FORWARDING => true,
      OPERATION_MODE => "DUAL_PORT"
   )
   port map(
      clock0 => clk,
      clock1 => clk,
      address_a => hist_addr_d,
      address_b => hist_addr_c,
      data_a => hist_data_d,
      wren_a => hist_we_d,
      q_b => hist_q_c
   );

   a_hist <= hist_q_a xor INIT_STATE;
   b_hist <= hist_q_b xor INIT_STATE;
   hist_data_d <= hist_data xor INIT_STATE;

   hist_addr_a <= addr_hash(a_nexpc);
   a_prediction <= a_hist(a_hist'high);
   hist_addr_b <= addr_hash(b_nexpc);
   b_prediction <= b_hist(b_hist'high);

   hist_addr_c <= addr_hash(pred_pc);
   hist_addr_d <= addr_hash(pred_pc_r);
   hist_data <=
      saturating_inc(hist_q_c xor INIT_STATE) when t_r = '1' else
      saturating_dec(hist_q_c xor INIT_STATE) when nt_r = '1' else
      (others => '-');
   hist_we_d <= t_r or nt_r;

   process(clk) is begin
      if(rising_edge(clk)) then
         pred_pc_r <= pred_pc;
         t_r <= t;
         nt_r <= nt;

         -- synch reset
         if(rst = '1') then
            t_r <= '0';
            nt_r <= '0';
         end if;
      end if;
   end process;
end architecture;
