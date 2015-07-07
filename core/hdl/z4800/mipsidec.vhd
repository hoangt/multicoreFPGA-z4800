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


entity mipsidec is
   generic(
      BRANCH_PREDICTOR:          boolean;
      STATIC_PREDICTOR:          boolean;
      DYNAMIC_PREDICTOR:         boolean;
      BRANCH_NOHINT:             boolean;
      RETURN_ADDR_PREDICTOR:     boolean;
      CLEVER_FLUSH:              boolean;
      BTB:                       boolean
   );
   port(
      ireg:             in          word;
      pc:               in          word;
      irq:              in          std_logic := '0';
      flags:            in          icache_flag_t := (others => '0');

      inst:             buffer      inst_t;
      new_pc:           out         word;
      use_new_pc:       out         std_logic;

      rastack_top:      in          word;
      rastack_pop:      out         std_logic;

      btb_target:       in          word := (others => '-');
      btb_valid:        in          std_logic := '0';

      dbp_in:           in          std_logic
   );
end mipsidec;

architecture mipsidec of mipsidec is
   type Rt is record
      opcode: std_logic_vector(5 downto 0);
      rs: std_logic_vector(4 downto 0);
      rt: std_logic_vector(4 downto 0);
      rd: std_logic_vector(4 downto 0);
      shamt: std_logic_vector(4 downto 0);
      funct: std_logic_vector(5 downto 0);
   end record;

   type It is record
      opcode: std_logic_vector(5 downto 0);
      rs: std_logic_vector(4 downto 0);
      rt: std_logic_vector(4 downto 0);
      imm16: std_logic_vector(15 downto 0);
   end record;
   
   type Jt is record
      opcode: std_logic_vector(5 downto 0);
      imm26: std_logic_vector(25 downto 0);
   end record;

   signal R: Rt;
   signal I: It;
   signal J: Jt;
   signal opcode, funct, regimm: std_logic_vector(7 downto 0);
   signal branch_offset: word;
   signal branch_target: word;
   signal branch_direction: std_logic;
   signal pc_plus_four: word;
   signal is_branch, is_cond_branch: std_logic;
   signal synth_branch: std_logic;
   signal is_j, is_jr: std_logic;
   signal prediction: std_logic;
   signal use_ret_predictor: std_logic;
   signal use_btb: std_logic;
   signal noflush: std_logic;
   constant zero: std_logic_vector(4 downto 0) := "00000"; -- refers to r0
begin
   R.opcode <= ireg(31 downto 26);
   R.rs <= ireg(25 downto 21);
   R.rt <= ireg(20 downto 16);
   R.rd <= ireg(15 downto 11);
   R.shamt <= ireg(10 downto 6);
   R.funct <= ireg(5 downto 0);

   I.opcode <= ireg(31 downto 26);
   I.rs <= ireg(25 downto 21);
   I.rt <= ireg(20 downto 16);
   I.imm16 <= ireg(15 downto 0);

   J.opcode <= ireg(31 downto 26);
   J.imm26 <= ireg(25 downto 0);

   opcode <= "00" & ireg(31 downto 26);
   funct <= "00" & R.funct;
   regimm <= "000" & I.rt;

   pc_plus_four <= pc + 4;
   branch_offset <= (31 downto 18 => I.imm16(15)) & I.imm16 & "00";
   branch_target <=  pc_plus_four(31 downto 28) & J.imm26 & "00" when is_j = '1' else
                     signed(pc_plus_four) + signed(branch_offset);
   branch_direction <= '1' when unsigned(branch_target) < unsigned(pc_plus_four) else '0';
   use_ret_predictor <= '1' when RETURN_ADDR_PREDICTOR and is_jr = '1' and R.rs = "11111" else '0';
   use_btb <= '1' when BTB and is_jr = '1' and btb_valid = '1' else '0';
   rastack_pop <= use_ret_predictor;
   prediction <=  '1' when inst.likely = '1' and not BRANCH_NOHINT else -- branch-likely instrs
                  dbp_in when DYNAMIC_PREDICTOR else -- externel pred input
                  branch_direction when STATIC_PREDICTOR else -- static direction-based predictor
                  '1';
   synth_branch <= '1' when opcode = x"04" and ireg(25 downto 21) = ireg(20 downto 16) else '0'; -- detect synthetic unconditional branch
   new_pc <=   rastack_top when use_ret_predictor = '1' else
               btb_target when use_btb = '1' else
               branch_target;
   use_new_pc <=  '0' when not BRANCH_PREDICTOR else
                  (is_cond_branch and prediction) or
                  is_branch or
                  use_ret_predictor or
                  use_btb or
                  synth_branch;

   -- make pipeline smart: if branch does not actually disrupt program flow,
   -- pipeline never has to be flushed (!)
   -- this handles stuff like:
   --          beqzl    $v0, 1f
   --          addiu    $v0, $v0, 1    ; if(!v0) v0++;
   -- 1:       ...
   noflush <=  '0' when not CLEVER_FLUSH else
               '0' when is_branch = '0' and is_cond_branch = '0' else
               '1' when I.imm16 = x"0001" else
               '0';

   process(opcode, funct, regimm, R, I, J, ireg, pc_plus_four, irq, flags, noflush) is
      procedure invalid_instruction is begin
         inst.op <= i_trap;
         inst.trap <= t_invalid;
      end procedure;
   begin
      inst <= (
         valid => '1',
         cond => c_true,
         op => i_nop,
         aluop => a_nop,
         cop0op => c0_nop,
         mem => m_none,
         trap => t_none,
         is_aluop => '0',
         source => ("00000", "00000"),
         reads => "00",
         dest => "00000",
         immed => x"00000000",
         use_immed => '0',
         writes_reg => '0',
         u => '0',
         has_delay_slot => '0',
         in_delay_slot => '0',
         in_annul_slot => '0',
         right_shift => '0',
         late => '0',
         cascade0 => '0',
         cascade1 => '0',
         likely => '0',
         trap_ov => '0',
         ll => '0',
         sc => '0',
         noflush => noflush
      );
      is_branch <= '0';
      is_cond_branch <= '0';
      is_j <= '0';
      is_jr <= '0';

      case opcode is
         when x"00" =>
            inst.source <= (R.rt, R.rs);
            inst.dest <= R.rd;
            inst.reads <= "11";
            case funct is
               when x"20" => -- add
                  inst.op <= i_alu;
                  inst.aluop <= a_add;
                  inst.reads <= "11";
                  inst.writes_reg <= '1';
                  inst.trap_ov <= '1';
               when x"21" => -- addu
                  inst.op <= i_alu;
                  inst.aluop <= a_add;
                  inst.reads <= "11";
                  inst.writes_reg <= '1';
               when x"22" => -- sub
                  inst.op <= i_alu;
                  inst.aluop <= a_sub;
                  inst.reads <= "11";
                  inst.writes_reg <= '1';
                  inst.trap_ov <= '1';
               when x"23" => -- subu
                  inst.op <= i_alu;
                  inst.aluop <= a_sub;
                  inst.reads <= "11";
                  inst.writes_reg <= '1';
               when x"24" => -- and
                  inst.op <= i_alu;
                  inst.aluop <= a_and;
                  inst.reads <= "11";
                  inst.writes_reg <= '1';
               when x"25" => -- or
                  inst.op <= i_alu;
                  inst.aluop <= a_or;
                  inst.reads <= "11";
                  inst.writes_reg <= '1';
               when x"26" => -- xor
                  inst.op <= i_alu;
                  inst.aluop <= a_xor;
                  inst.reads <= "11";
                  inst.writes_reg <= '1';
               when x"27" => -- nor
                  inst.op <= i_alu;
                  inst.aluop <= a_nor;
                  inst.reads <= "11";
                  inst.writes_reg <= '1';
               when x"00" => -- sll
                  if(ireg = x"00000080") then -- special synthetic pipe flush
                     -- deep optimization magic here. we implement pflush as
                     -- an aluop (sll r0, r0, 2) AND an always-mispredicted
                     -- taken branch (to pc + 4) without a delay slot.
                     -- the mispredict will force-flush the iqueue and pipe.
                     inst.op <= i_pflush;
                  elsif(ireg = x"00000040") then -- ssnop
                     inst.op <= i_ssnop;
                  else
                     inst.op <= i_alu;
                  end if;
                  inst.aluop <= a_shl;
                  inst.source(0) <= R.rt;
                  inst.reads <= "01";
                  inst.immed <= (31 downto 5 => '0') & R.shamt;
                  inst.use_immed <= '1';
                  inst.writes_reg <= '1';
                  inst.right_shift <= '0';
               when x"02" => -- srl
                  inst.op <= i_alu;
                  inst.aluop <= a_shl;
                  inst.source(0) <= R.rt;
                  inst.reads <= "01";
                  inst.immed <= (31 downto 5 => '0') & R.shamt;
                  inst.use_immed <= '1';
                  inst.writes_reg <= '1';
                  inst.right_shift <= '1';
               when x"03" => -- sra
                  inst.op <= i_alu;
                  inst.aluop <= a_sha;
                  inst.source(0) <= R.rt;
                  inst.reads <= "01";
                  inst.immed <= (31 downto 5 => '0') & R.shamt;
                  inst.use_immed <= '1';
                  inst.writes_reg <= '1';
                  inst.right_shift <= '1';
               when x"04" => -- sllv
                  inst.op <= i_alu;
                  inst.aluop <= a_shl;
                  inst.source <= (R.rs, R.rt);
                  inst.reads <= "11";
                  inst.writes_reg <= '1';
                  inst.right_shift <= '0';
               when x"06" => -- srlv
                  inst.op <= i_alu;
                  inst.aluop <= a_shl;
                  inst.source <= (R.rs, R.rt);
                  inst.reads <= "11";
                  inst.writes_reg <= '1';
                  inst.right_shift <= '1';
               when x"07" => -- srav
                  inst.op <= i_alu;
                  inst.aluop <= a_sha;
                  inst.source <= (R.rs, R.rt);
                  inst.reads <= "11";
                  inst.writes_reg <= '1';
                  inst.right_shift <= '1';
               when x"2a" => -- slt
                  inst.op <= i_alu;
                  inst.aluop <= a_slt;
                  inst.reads <= "11";
                  inst.writes_reg <= '1';
               when x"2b" => -- sltu
                  inst.op <= i_alu;
                  inst.aluop <= a_slt;
                  inst.u <= '1';
                  inst.reads <= "11";
                  inst.writes_reg <= '1';
               when x"08" => -- jr
                  inst.op <= i_jr;
                  inst.source(0) <= R.rs;
                  inst.reads <= "01";
                  inst.has_delay_slot <= '1';
                  is_jr <= '1';
               when x"09" => -- jalr
                  inst.op <= i_jr;
                  inst.source(0) <= R.rs;
                  inst.reads <= "01";
                  inst.has_delay_slot <= '1';
                  is_jr <= '1';
                  inst.writes_reg <= '1';
               when x"0c" => -- syscall
                  inst.op <= i_trap;
                  inst.trap <= t_syscall;
               when x"18" => -- mult
                  inst.op <= i_muldiv;
                  inst.aluop <= a_mul;
                  inst.reads <= "11";
               when x"19" => -- multu
                  inst.op <= i_muldiv;
                  inst.aluop <= a_mul;
                  inst.reads <= "11";
                  inst.u <= '1';
               when x"10" => -- mfhi
                  inst.op <= i_muldiv;
                  inst.aluop <= a_mfhi;
                  inst.dest <= R.rd;
                  inst.writes_reg <= '1';
                  inst.late <= '1';
               when x"12" => -- mflo
                  inst.op <= i_muldiv;
                  inst.aluop <= a_mflo;
                  inst.dest <= R.rd;
                  inst.writes_reg <= '1';
                  inst.late <= '1';
               when x"11" => -- mthi
                  inst.op <= i_muldiv;
                  inst.aluop <= a_mthi;
                  inst.source(0) <= R.rs;
                  inst.reads <= "01";
               when x"13" => -- mtlo
                  inst.op <= i_muldiv;
                  inst.aluop <= a_mtlo;
                  inst.source(0) <= R.rs;
                  inst.reads <= "01";
               when x"1a" => -- div
                  inst.op <= i_muldiv;
                  inst.aluop <= a_div;
                  inst.reads <= "11";
               when x"1b" => -- divu
                  inst.op <= i_muldiv;
                  inst.aluop <= a_div;
                  inst.reads <= "11";
                  inst.u <= '1';
               when x"34" => -- teq
                  inst.op <= i_trap;
                  inst.trap <= t_trap;
                  inst.cond <= c_eq;
                  inst.reads <= "11";
               when x"30" => -- tge
                  inst.op <= i_trap;
                  inst.trap <= t_trap;
                  inst.cond <= c_ge;
                  inst.reads <= "11";
               when x"31" => -- tgeu
                  inst.op <= i_trap;
                  inst.trap <= t_trap;
                  inst.cond <= c_ge;
                  inst.reads <= "11";
                  inst.u <= '1';
               when x"32" => -- tlt
                  inst.op <= i_trap;
                  inst.trap <= t_trap;
                  inst.cond <= c_lt;
                  inst.reads <= "11";
               when x"33" => -- tltu
                  inst.op <= i_trap;
                  inst.trap <= t_trap;
                  inst.cond <= c_lt;
                  inst.reads <= "11";
                  inst.u <= '1';
               when x"36" => -- tne
                  inst.op <= i_trap;
                  inst.trap <= t_trap;
                  inst.cond <= c_ne;
                  inst.reads <= "11";
               when x"0f" => -- sync
                  inst.op <= i_sync;
               when x"0d" => -- break
                  inst.op <= i_trap;
                  inst.trap <= t_break;
               when others =>
                  invalid_instruction;
            end case;
         when x"01" => -- regimm
            if(regimm = x"01" or regimm = x"11" or regimm = x"13" or
               regimm = x"03" or regimm = x"00" or regimm = x"10" or
               regimm = x"12" or regimm = x"02") then
            -- bgez, bgezal, bgezall, bgezl, bltz, bltzal, bltzall, bltzl
               inst.op <= i_br;
               inst.writes_reg <= ireg(20);
               if(ireg(16) = '1') then
                  inst.cond <= c_ge;
               else
                  inst.cond <= c_lt;
               end if;
               inst.source <= (zero, I.rs);
               inst.reads <= "11";
               inst.dest <= "11111";
               inst.has_delay_slot <= '1';
               is_cond_branch <= '1';
               inst.likely <= ireg(17);
            end if;
            case regimm is
               when x"0c" => -- teqi
                  inst.op <= i_trap;
                  inst.trap <= t_trap;
                  inst.aluop <= a_sub;
                  inst.cond <= c_eq;
                  inst.source(0) <= I.rs;
                  inst.reads(0) <= '1';
                  inst.immed <= (31 downto 16 => I.imm16(15)) & I.imm16;
                  inst.use_immed <= '1';
               when x"08" => -- tgei
                  inst.op <= i_trap;
                  inst.trap <= t_trap;
                  inst.aluop <= a_sub;
                  inst.cond <= c_ge;
                  inst.source(0) <= I.rs;
                  inst.reads(0) <= '1';
                  inst.immed <= (31 downto 16 => I.imm16(15)) & I.imm16;
                  inst.use_immed <= '1';
               when x"09" => -- tgeiu
                  inst.op <= i_trap;
                  inst.trap <= t_trap;
                  inst.aluop <= a_sub;
                  inst.cond <= c_ge;
                  inst.source(0) <= I.rs;
                  inst.reads(0) <= '1';
                  inst.immed <= (31 downto 16 => I.imm16(15)) & I.imm16;
                  inst.use_immed <= '1';
                  inst.u <= '1';
               when x"0a" => -- tlti
                  inst.op <= i_trap;
                  inst.trap <= t_trap;
                  inst.aluop <= a_sub;
                  inst.cond <= c_lt;
                  inst.source(0) <= I.rs;
                  inst.reads(0) <= '1';
                  inst.immed <= (31 downto 16 => I.imm16(15)) & I.imm16;
                  inst.use_immed <= '1';
               when x"0b" => -- tltiu
                  inst.op <= i_trap;
                  inst.trap <= t_trap;
                  inst.aluop <= a_sub;
                  inst.cond <= c_lt;
                  inst.source(0) <= I.rs;
                  inst.reads(0) <= '1';
                  inst.immed <= (31 downto 16 => I.imm16(15)) & I.imm16;
                  inst.use_immed <= '1';
                  inst.u <= '1';
               when x"0e" => -- tnei
                  inst.op <= i_trap;
                  inst.trap <= t_trap;
                  inst.aluop <= a_sub;
                  inst.cond <= c_ne;
                  inst.source(0) <= I.rs;
                  inst.reads(0) <= '1';
                  inst.immed <= (31 downto 16 => I.imm16(15)) & I.imm16;
                  inst.use_immed <= '1';
               when x"01" =>
               when x"11" =>
               when x"13" => 
               when x"03" =>
               when x"00" =>
               when x"10" =>
               when x"12" =>
               when x"02" =>
               when others =>
                  invalid_instruction;
            end case;
         when x"08" => -- addi
            inst.op <= i_alu;
            inst.aluop <= a_add;
            inst.source(0) <= I.rs;
            inst.reads(0) <= '1';
            inst.dest <= I.rt;
            inst.immed <= (31 downto 16 => I.imm16(15)) & I.imm16;
            inst.use_immed <= '1';
            inst.writes_reg <= '1';
            inst.trap_ov <= '1';
         when x"09" => -- addiu
            inst.op <= i_alu;
            inst.aluop <= a_add;
            inst.source(0) <= I.rs;
            inst.reads(0) <= '1';
            inst.dest <= I.rt;
            inst.immed <= (31 downto 16 => I.imm16(15)) & I.imm16;
            inst.use_immed <= '1';
            inst.writes_reg <= '1';
         when x"2f" => -- cache
            inst.op <= i_cache;
            inst.source <= (I.rs, I.rt); -- rt contains invop
            inst.reads <= "10";
            inst.immed <= (31 downto 16 => I.imm16(15)) & I.imm16;
            case I.rt(4 downto 2) is -- trap on unimplemented cache ops
               when "001" => -- R4K: index ld tag
                  invalid_instruction;
               when "010" => -- R4K: index st tag
                  invalid_instruction;
               when "011" => -- R4K: create d excl
                  invalid_instruction;
               when "111" => -- R4K: hit set virt
                  invalid_instruction;
               when others =>
                  null;
            end case;
         when x"23" => -- lw
            inst.op <= i_ld;
            inst.mem <= m_lw;
            inst.source(1) <= I.rs;
            inst.reads <= "10";
            inst.dest <= I.rt;
            inst.immed <= (31 downto 16 => I.imm16(15)) & I.imm16;
            inst.writes_reg <= '1';
            inst.late <= '1';
         when x"21" => -- lh
            inst.op <= i_ld;
            inst.mem <= m_lh;
            inst.source(1) <= I.rs;
            inst.reads <= "10";
            inst.dest <= I.rt;
            inst.immed <= (31 downto 16 => I.imm16(15)) & I.imm16;
            inst.writes_reg <= '1';
            inst.late <= '1';
         when x"25" => -- lhu
            inst.op <= i_ld;
            inst.mem <= m_lh;
            inst.source(1) <= I.rs;
            inst.reads <= "10";
            inst.dest <= I.rt;
            inst.immed <= (31 downto 16 => I.imm16(15)) & I.imm16;
            inst.writes_reg <= '1';
            inst.late <= '1';
            inst.u <= '1';
         when x"20" => -- lb
            inst.op <= i_ld;
            inst.mem <= m_lb;
            inst.source(1) <= I.rs;
            inst.reads <= "10";
            inst.dest <= I.rt;
            inst.immed <= (31 downto 16 => I.imm16(15)) & I.imm16;
            inst.writes_reg <= '1';
            inst.late <= '1';
         when x"24" => -- lbu
            inst.op <= i_ld;
            inst.mem <= m_lb;
            inst.source(1) <= I.rs;
            inst.reads <= "10";
            inst.dest <= I.rt;
            inst.immed <= (31 downto 16 => I.imm16(15)) & I.imm16;
            inst.writes_reg <= '1';
            inst.late <= '1';
            inst.u <= '1';
         when x"22" => -- lwl
            inst.op <= i_ld;
            inst.mem <= m_lwl;
            inst.source <= (I.rs, I.rt);
            inst.reads <= "11";
            inst.dest <= I.rt;
            inst.immed <= (31 downto 16 => I.imm16(15)) & I.imm16;
            inst.writes_reg <= '1';
            inst.late <= '1';
         when x"26" => -- lwr
            inst.op <= i_ld;
            inst.mem <= m_lwr;
            inst.source <= (I.rs, I.rt);
            inst.reads <= "11";
            inst.dest <= I.rt;
            inst.immed <= (31 downto 16 => I.imm16(15)) & I.imm16;
            inst.writes_reg <= '1';
            inst.late <= '1';
         when x"2b" => -- sw
            inst.op <= i_st;
            inst.mem <= m_sw;
            inst.source <= (I.rs, I.rt);
            inst.reads <= "11";
            inst.immed <= (31 downto 16 => I.imm16(15)) & I.imm16;
         when x"29" => -- sh
            inst.op <= i_st;
            inst.mem <= m_sh;
            inst.source <= (I.rs, I.rt);
            inst.reads <= "11";
            inst.immed <= (31 downto 16 => I.imm16(15)) & I.imm16;
         when x"28" => -- sb
            inst.op <= i_st;
            inst.mem <= m_sb;
            inst.source <= (I.rs, I.rt);
            inst.reads <= "11";
            inst.immed <= (31 downto 16 => I.imm16(15)) & I.imm16;
         when x"2a" => -- swl
            inst.op <= i_st;
            inst.mem <= m_swl;
            inst.source <= (I.rs, I.rt);
            inst.reads <= "11";
            inst.immed <= (31 downto 16 => I.imm16(15)) & I.imm16;
         when x"2e" => -- swr
            inst.op <= i_st;
            inst.mem <= m_swr;
            inst.source <= (I.rs, I.rt);
            inst.reads <= "11";
            inst.immed <= (31 downto 16 => I.imm16(15)) & I.imm16;
         when x"0f" => -- lui
            inst.op <= i_lui;
            inst.aluop <= a_nop1;
            inst.dest <= I.rt;
            inst.immed <= I.imm16 & (15 downto 0 => '0');
            inst.use_immed <= '1';
            inst.writes_reg <= '1';
         when x"0c" => -- andi
            inst.op <= i_alu;
            inst.aluop <= a_and;
            inst.source(0) <= I.rs;
            inst.reads(0) <= '1';
            inst.dest <= I.rt;
            inst.immed <= (31 downto 16 => '0') & I.imm16;
            inst.use_immed <= '1';
            inst.writes_reg <= '1';
         when x"0d" => -- ori
            inst.op <= i_alu;
            inst.aluop <= a_or;
            inst.source(0) <= I.rs;
            inst.reads(0) <= '1';
            inst.dest <= I.rt;
            inst.immed <= (31 downto 16 => '0') & I.imm16;
            inst.use_immed <= '1';
            inst.writes_reg <= '1';
         when x"0e" => -- xori
            inst.op <= i_alu;
            inst.aluop <= a_xor;
            inst.source(0) <= I.rs;
            inst.reads(0) <= '1';
            inst.dest <= I.rt;
            inst.immed <= (31 downto 16 => '0') & I.imm16;
            inst.use_immed <= '1';
            inst.writes_reg <= '1';
         when x"0a" => -- slti
            inst.op <= i_alu;
            inst.aluop <= a_slt;
            inst.source(0) <= I.rs;
            inst.reads(0) <= '1';
            inst.dest <= I.rt;
            inst.immed <= (31 downto 16 => I.imm16(15)) & I.imm16;
            inst.use_immed <= '1';
            inst.writes_reg <= '1';
         when x"0b" => -- sltiu
            inst.op <= i_alu;
            inst.aluop <= a_slt;
            inst.u <= '1';
            inst.source(0) <= I.rs;
            inst.reads(0) <= '1';
            inst.dest <= I.rt;
            inst.immed <= (31 downto 16 => I.imm16(15)) & I.imm16;
            inst.use_immed <= '1';
            inst.writes_reg <= '1';
         when x"04" => -- beq
            inst.op <= i_br;
            inst.cond <= c_eq;
            inst.source <= (I.rt, I.rs);
            inst.reads <= "11";
            inst.has_delay_slot <= '1';
            is_cond_branch <= '1';
         when x"14" => -- beql
            inst.op <= i_br;
            inst.cond <= c_eq;
            inst.source <= (I.rt, I.rs);
            inst.reads <= "11";
            inst.has_delay_slot <= '1';
            is_cond_branch <= '1';
            inst.likely <= '1';
         when x"07" => -- bgtz
            inst.op <= i_br;
            inst.cond <= c_gt;
            inst.source <= (zero, I.rs);
            inst.reads <= "11";
            inst.has_delay_slot <= '1';
            is_cond_branch <= '1';
         when x"17" => -- bgtzl
            inst.op <= i_br;
            inst.cond <= c_gt;
            inst.source <= (zero, I.rs);
            inst.reads <= "11";
            inst.has_delay_slot <= '1';
            is_cond_branch <= '1';
            inst.likely <= '1';
         when x"06" => -- blez
            inst.op <= i_br;
            inst.cond <= c_le;
            inst.source <= (zero, I.rs);
            inst.reads <= "11";
            inst.has_delay_slot <= '1';
            is_cond_branch <= '1';
         when x"16" => -- blezl
            inst.op <= i_br;
            inst.cond <= c_le;
            inst.source <= (zero, I.rs);
            inst.reads <= "11";
            inst.has_delay_slot <= '1';
            is_cond_branch <= '1';
            inst.likely <= '1';
         when x"05" => -- bne
            inst.op <= i_br;
            inst.cond <= c_ne;
            inst.source <= (I.rs, I.rt);
            inst.reads <= "11";
            inst.has_delay_slot <= '1';
            is_cond_branch <= '1';
         when x"15" => -- bnel
            inst.op <= i_br;
            inst.cond <= c_ne;
            inst.source <= (I.rs, I.rt);
            inst.reads <= "11";
            inst.has_delay_slot <= '1';
            is_cond_branch <= '1';
            inst.likely <= '1';
         when x"02" => -- j
            inst.op <= i_br;
            inst.dest <= "11111";
            inst.has_delay_slot <= '1';
            is_branch <= '1';
            is_j <= '1';
         when x"03" => -- jal
            inst.op <= i_br;
            inst.dest <= "11111";
            inst.writes_reg <= '1';
            inst.has_delay_slot <= '1';
            is_branch <= '1';
            is_j <= '1';
         when x"30" => -- ll (encodes as lwc0)
            inst.op <= i_ld;
            inst.ll <= '1';
            inst.mem <= m_lw;
            inst.source(1) <= I.rs;
            inst.reads <= "10";
            inst.dest <= I.rt;
            inst.immed <= (31 downto 16 => I.imm16(15)) & I.imm16;
            inst.writes_reg <= '1';
            inst.late <= '1';
         when x"31" => -- lwc1
            inst.op <= i_cop1;
         when x"32" => -- lwc2
            inst.op <= i_cop2;
         when x"33" => -- lwc3
            inst.op <= i_cop3;
         when x"34" => -- lld (encodes as ldc0)
            invalid_instruction;
         when x"35" => -- ldc1
            inst.op <= i_cop1;
         when x"36" => -- ldc2
            inst.op <= i_cop2;
         when x"37" => -- ldc3
            inst.op <= i_cop3;
         when x"38" => -- sc (encodes as swc0)
            inst.op <= i_st;
            inst.sc <= '1';
            inst.mem <= m_sw;
            inst.source <= (I.rs, I.rt);
            inst.reads <= "11";
            inst.immed <= (31 downto 16 => I.imm16(15)) & I.imm16;
            inst.dest <= I.rt;
            inst.writes_reg <= '1';
            inst.late <= '1';
         when x"39" => -- swc1
            inst.op <= i_cop1;
         when x"3a" => -- swc2
            inst.op <= i_cop2;
         when x"3b" => -- swc3
            inst.op <= i_cop3;
         when x"3c" => -- scd (encodes as sdc0)
            invalid_instruction;
         when x"3d" => -- sdc1
            inst.op <= i_cop1;
         when x"3e" => -- sdc2
            inst.op <= i_cop2;
         when x"3f" => -- sdc3
            inst.op <= i_cop3;
         when x"10" => -- coprocessor 0 stuff
            if(ireg(25) = '0') then
               case R.rs is
                  when "00000" => -- mfc0
                     inst.op <= i_cop0;
                     inst.cop0op <= c0_mfc;
                     inst.source(0) <= R.rd; -- rd is not a GPR addr
                     inst.dest <= R.rt;
                     inst.writes_reg <= '1';
                     inst.late <= '1';
                  when "00100" => -- mtc0
                     inst.op <= i_cop0;
                     inst.aluop <= a_nop1;
                     inst.cop0op <= c0_mtc;
                     inst.source <= (R.rt, R.rd); -- rd is not a GPR addr
                     inst.reads(1) <= '1';
                  when others =>
                     invalid_instruction;
               end case;
            else
               case ireg(5 downto 0) is
                  when "011000" => -- eret
                     inst.op <= i_cop0;
                     inst.cop0op <= c0_eret;
                  when "001000" => -- tlbp
                     inst.op <= i_cop0;
                     inst.cop0op <= c0_tlbp;
                  when "000001" => -- tlbr
                     inst.op <= i_cop0;
                     inst.cop0op <= c0_tlbr;
                  when "000010" => -- tlbwi
                     inst.op <= i_cop0;
                     inst.cop0op <= c0_tlbwi;
                  when "000110" => -- tlbwr
                     inst.op <= i_cop0;
                     inst.cop0op <= c0_tlbwr;
                  when others =>
                     invalid_instruction;
               end case;
            end if;
         when x"11" => -- coprocessor 1 stuff
            inst.op <= i_cop1;
         when x"12" => -- coprocessor 2 stuff
            inst.op <= i_cop2;
         when x"13" => -- coprocessor 3 stuff
            inst.op <= i_cop3;
         when others =>
            invalid_instruction;
      end case;

      if(irq = '1' or flags.i_unaligned = '1' or flags.itlb_permerr = '1' or flags.itlb_miss = '1' or flags.itlb_invalid = '1') then
         inst.cond <= c_true;
         inst.op <= i_trap;
         inst.aluop <= a_nop;
         inst.cop0op <= c0_nop;
         inst.mem <= m_none;
         inst.reads <= "00";
         inst.writes_reg <= '0';
         inst.has_delay_slot <= '0';
         inst.late <= '0';
         inst.likely <= '0';
         inst.trap_ov <= '0';
         inst.sc <= '0';
         inst.ll <= '0';
         inst.noflush <= '0';
         if(irq = '1') then
            inst.trap <= t_int;
         elsif(flags.i_unaligned = '1' or flags.itlb_permerr = '1') then
            inst.trap <= t_itlb_adel;
         elsif(flags.itlb_invalid = '1') then
            inst.trap <= t_itlb_tlbl;
         elsif(flags.itlb_miss = '1') then
            inst.trap <= t_itlb_refill;
         else
            inst.trap <= t_break;
         end if;
      end if;
   end process;
end architecture mipsidec;
