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

library ieee, lpm, z48common; use ieee.std_logic_1164.all, ieee.std_logic_unsigned.all, ieee.std_logic_arith.all, lpm.lpm_components.all, z48common.z48common.all;


entity fetchpredict is
   generic(
      BRANCH_PREDICTOR:             boolean;
      BRANCH_NOHINT:                boolean;
      STATIC_PREDICTOR:             boolean;
      DYNAMIC_PREDICTOR:            boolean;
      BTB:                          boolean;
      UNALIGNED_DELAY_SLOT:         boolean;
      RETURN_ADDR_PREDICTOR:        boolean
   );
   port(
      clk:                          in    std_logic;
      rst:                          in    std_logic;
      pc:                           in    word;
      cache_in:                     in    dworda;
      cache_kill:                   in    std_logic;
      v:                            in    std_logic_vector(1 downto 0);
      nextaddr:                     out   word;
      delay_slot:                   buffer std_logic;
      ras_top:                      in    word;
      btb_target:                   in    word;
      btb_valid:                    in    std_logic;
      dbp_in:                       in    std_logic
   );
end entity;

architecture fetchpredict of fetchpredict is
   signal pc_base:                  word;
   type insta_t is array(1 downto 0) of inst_t;
   signal inst:                     insta_t;
   signal new_pc:                   dworda;
   signal use_new_pc:               std_logic_vector(1 downto 0);
   signal delayed_target:           word;
begin
   idec0: entity work.mipsidec generic map(
      BRANCH_PREDICTOR => BRANCH_PREDICTOR,
      BRANCH_NOHINT => BRANCH_NOHINT,
      STATIC_PREDICTOR => STATIC_PREDICTOR,
      DYNAMIC_PREDICTOR => DYNAMIC_PREDICTOR,
      RETURN_ADDR_PREDICTOR => RETURN_ADDR_PREDICTOR,
      CLEVER_FLUSH => false,
      BTB => BTB
   )
   port map(
      ireg => cache_in(0),
      pc => pc,
      inst => inst(0),
      new_pc => new_pc(0),
      use_new_pc => use_new_pc(0),
      rastack_top => ras_top,
      btb_target => btb_target,
      btb_valid => btb_valid,
      dbp_in => dbp_in
   );

   idec1: entity work.mipsidec generic map(
      BRANCH_PREDICTOR => BRANCH_PREDICTOR,
      BRANCH_NOHINT => BRANCH_NOHINT,
      STATIC_PREDICTOR => STATIC_PREDICTOR,
      DYNAMIC_PREDICTOR => DYNAMIC_PREDICTOR,
      RETURN_ADDR_PREDICTOR => RETURN_ADDR_PREDICTOR,
      CLEVER_FLUSH => false,
      BTB => BTB
   )
   port map(
      ireg => cache_in(1),
      pc => pc,
      inst => inst(1),
      new_pc => new_pc(1),
      use_new_pc => use_new_pc(1),
      rastack_top => ras_top,
      btb_target => btb_target,
      btb_valid => btb_valid,
      dbp_in => dbp_in
   );

   pc_base <= pc(31 downto 3) & "000";
   nextaddr <=
      delayed_target when UNALIGNED_DELAY_SLOT and delay_slot = '1' else
      new_pc(0) when use_new_pc(0) = '1' and v(0) = '1' else
      new_pc(1) when use_new_pc(1) = '1' and v(1) = '1' and inst(1).has_delay_slot = '0' else
      pc_base + 8;

   process(clk) is begin
      if(rising_edge(clk)) then
         if(UNALIGNED_DELAY_SLOT) then
            if(v(0) = '1' or v(1) = '1') then
               delay_slot <= '0';
            end if;
            if(v(1) = '1' and use_new_pc(1) = '1' and inst(1).has_delay_slot = '1') then
               delay_slot <= '1';
               delayed_target <= new_pc(1);
            end if;
            if(cache_kill = '1') then
               delay_slot <= '0';
            end if;
         else
            delay_slot <= '0';
         end if;

         if(rst = '1') then
            delay_slot <= '0';
         end if;
      end if;
   end process;
end architecture;
