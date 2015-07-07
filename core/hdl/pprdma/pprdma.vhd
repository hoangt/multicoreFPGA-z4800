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

library ieee, altera_mf;
use ieee.std_logic_1164.all, ieee.std_logic_unsigned.all, ieee.std_logic_arith.all, altera_mf.altera_mf_components.all;

entity pprdma is
   generic(
      SADDR_WIDTH:      natural := 28;
      PHY_WIDTH:        natural := 8;
      LOG_WIDTH:        natural := 32;
      SFIFO_DEPTH:      natural := 32;
      TFIFO_DEPTH:      natural := 32;
      CFIFO_DEPTH:      natural := 8;
      READ_THRESH:      natural := 8;
      READ_LIMIT:       natural := 16;
      LINK_BP_THRESH:   natural := 8;
      LINK_BP_SYNCH:    natural := 2
   );
   port(
      clk:              in       std_logic;
      rst:              in       std_logic;

      o_clk:            buffer   std_logic;
      o_data:           out      std_logic_vector(PHY_WIDTH - 1 downto 0);
      o_nstb:           out      std_logic;
      o_sel:            out      std_logic_vector(1 downto 0);
      o_nrd:            out      std_logic;
      o_nwr:            out      std_logic;
      o_bp:             buffer   std_logic;

      i_clk:            in       std_logic;
      i_data:           in       std_logic_vector(PHY_WIDTH - 1 downto 0);
      i_nstb:           in       std_logic;
      i_sel:            in       std_logic_vector(1 downto 0);
      i_nrd:            in       std_logic;
      i_nwr:            in       std_logic;
      i_bp:             in       std_logic;

      m_addr:           out      std_logic_vector(31 downto 0);
      m_rd:             out      std_logic;
      m_wr:             out      std_logic;
      m_halt:           in       std_logic;
      m_be:             out      std_logic_vector(LOG_WIDTH / 8 - 1 downto 0);
      m_out:            out      std_logic_vector(LOG_WIDTH - 1 downto 0);
      m_in:             in       std_logic_vector(LOG_WIDTH - 1 downto 0);
      m_valid:          in       std_logic;

      s_addr:           in       std_logic_vector(SADDR_WIDTH - 1 downto 0);
      s_rd:             in       std_logic;
      s_wr:             in       std_logic;
      s_halt:           buffer   std_logic;
      s_be:             in       std_logic_vector(LOG_WIDTH / 8 - 1 downto 0);
      s_out:            out      std_logic_vector(LOG_WIDTH - 1 downto 0);
      s_in:             in       std_logic_vector(LOG_WIDTH - 1 downto 0);
      s_valid:          buffer   std_logic
   );
end entity;

architecture pprdma of pprdma is
   -- register map:
   -- 0: address register (32)
   -- 1: local data register (LOG_WIDTH)
   -- 2: remote data register (LOG_WIDTH)
   -- 3: local ctl register (CTL_WIDTH)

   -- ctl reg map:
   -- +-- BEs --+ 1 .. 0
   -- |         | |    |
   -- b b ...   b addrmode

   -- address modes:
   -- 0: no increment
   -- 1: post-increment
   -- 2: post-decrement
   -- 3: unused

   function log2(x: integer) return integer is
      variable ret: integer := 0;
      variable i: integer := 1;
   begin
      while(i < x) loop
         i := i * 2;
         ret := ret + 1;
      end loop;
      return ret;
   end function;

   constant READ_HIGHWATER:   natural := TFIFO_DEPTH - READ_THRESH;
   constant SFIFO_HIGHWATER:  natural := SFIFO_DEPTH - LINK_BP_THRESH;

   constant CTL_WIDTH:        natural := LOG_WIDTH / 8 + 2;
   constant CTL_ADDRMODE_L:   natural := 0;
   constant CTL_ADDRMODE_H:   natural := CTL_ADDRMODE_L + 1;
   constant CTL_BE_L:         natural := CTL_ADDRMODE_H + 1;
   constant CTL_BE_H:         natural := CTL_BE_L + LOG_WIDTH / 8 - 1;

   constant ADDR_INC:         natural := LOG_WIDTH / 8;

   signal reg0_ar, rreg0_ar:  std_logic_vector(31 downto 0);
   signal reg1_ldr, rreg1_ldr:std_logic_vector(LOG_WIDTH - 1 downto 0);
   signal reg2_rdr, rreg2_rdr:std_logic_vector(LOG_WIDTH - 1 downto 0);
   signal reg3_ctr, rreg3_ctr:std_logic_vector(CTL_WIDTH - 1 downto 0);

   signal sfifo_in, sfifo_out:std_logic_vector(5 + PHY_WIDTH - 1 downto 0);
   signal sfifo_rd, sfifo_wr: std_logic;
   signal sfifo_rdempty:      std_logic;
   signal sfifo_wrusedw:      std_logic_vector(log2(SFIFO_DEPTH) - 1 downto 0);
   signal rx_data:            std_logic_vector(PHY_WIDTH - 1 downto 0);
   signal rx_sel:             std_logic_vector(1 downto 0);
   signal rx_stb:             std_logic;
   signal rx_rd:              std_logic;
   signal rx_wr:              std_logic;

   signal tx_data:            std_logic_vector(PHY_WIDTH - 1 downto 0);
   signal tx_sel:             std_logic_vector(1 downto 0);
   signal tx_stb:             std_logic;
   signal tx_rd, tx_rd_next:  std_logic;
   signal tx_wr, tx_wr_next:  std_logic;

   signal tfifo_out:          std_logic_vector(PHY_WIDTH - 1 downto 0);
   signal tfifo_rdempty:      std_logic;
   signal tfifo_rd:           std_logic;
   signal tfifo_in:           std_logic_vector(LOG_WIDTH - 1 downto 0);
   signal tfifo_wrfull:       std_logic;
   signal tfifo_wr:           std_logic;

   signal cfifo_in:           std_logic_vector(LOG_WIDTH / 8 + LOG_WIDTH + 2 + 32 - 1 downto 0);
   signal cfifo_out:          std_logic_vector(cfifo_in'range);
   signal cfifo_rd:           std_logic;
   signal cfifo_rdempty:      std_logic;
   signal cfifo_wr:           std_logic;
   signal cfifo_wrfull:       std_logic;
   signal cfifo_out_addr:     std_logic_vector(31 downto 0);
   signal cfifo_out_rd:       std_logic;
   signal cfifo_out_wr:       std_logic;
   signal cfifo_out_be:       std_logic_vector(LOG_WIDTH / 8 - 1 downto 0);
   signal cfifo_out_data:     std_logic_vector(LOG_WIDTH - 1 downto 0);

   signal i_bp_synch:         std_logic_vector(LINK_BP_SYNCH - 1 downto 0);

   function shiftin(reg: std_logic_vector; data: std_logic_vector) return std_logic_vector is begin
      if(reg'length = data'length) then
         return data;
      elsif(reg'length > data'length) then
         return data & reg(reg'high downto data'length);
      else
         return data(reg'high downto reg'low);
      end if;
   end function;

   function rotate(x: std_logic_vector; n: natural) return std_logic_vector is begin
      return x(n - 1 downto 0) & x(x'high downto n);
   end function;

   function pad32(x: std_logic_vector; n: natural) return std_logic_vector is begin
      return (31 downto x'length + n => '0') & x & (n - 1 downto 0 => '0');
   end function;

   signal slave_reads_active: integer range 0 to READ_LIMIT;
   signal slave_read_halt:    std_logic;

   attribute altera_attribute: string;

   attribute altera_attribute of i_data: signal is "FAST_INPUT_REGISTER=ON";
   attribute altera_attribute of i_nstb: signal is "FAST_INPUT_REGISTER=ON";
   attribute altera_attribute of i_sel: signal is "FAST_INPUT_REGISTER=ON";
   attribute altera_attribute of i_nrd: signal is "FAST_INPUT_REGISTER=ON";
   attribute altera_attribute of i_nwr: signal is "FAST_INPUT_REGISTER=ON";
   attribute altera_attribute of i_bp: signal is "FAST_INPUT_REGISTER=ON";

   attribute altera_attribute of o_data: signal is "FAST_OUTPUT_REGISTER=ON";
   attribute altera_attribute of o_nstb: signal is "FAST_OUTPUT_REGISTER=ON";
   attribute altera_attribute of o_sel: signal is "FAST_OUTPUT_REGISTER=ON";
   attribute altera_attribute of o_nrd: signal is "FAST_OUTPUT_REGISTER=ON";
   attribute altera_attribute of o_nwr: signal is "FAST_OUTPUT_REGISTER=ON";
   attribute altera_attribute of o_bp: signal is "FAST_OUTPUT_REGISTER=ON";
begin
   assert(LOG_WIDTH >= PHY_WIDTH) report "Logical width must be at least as wide as physical width" severity error;
   assert(SFIFO_HIGHWATER > 1) report "SFIFO_DEPTH and/or LINK_BP_THRESH fubar" severity error;

   slave_read_counter: process(clk) is
      variable n: integer range slave_reads_active'range;
   begin
      if(rising_edge(clk)) then
         n := slave_reads_active;
         if(s_rd = '1' and s_halt = '0') then
            n := n + 1;
         end if;
         if(s_valid = '1') then
            n := n - 1;
         end if;
         slave_reads_active <= n;
         if(n = READ_LIMIT) then
            slave_read_halt <= '1';
         else
            slave_read_halt <= '0';
         end if;
         if(rst = '1') then
            slave_reads_active <= 0;
            slave_read_halt <= '0';
         end if;
      end if;
   end process;

   rx: process(clk) is
      procedure bump_address is begin
         case reg3_ctr(CTL_ADDRMODE_H downto CTL_ADDRMODE_L) is
            when "00" => null;
            when "01" => reg0_ar <= reg0_ar + ADDR_INC;
            when "10" => reg0_ar <= reg0_ar - ADDR_INC;
            when "11" => null;
         end case;
      end procedure;
      variable rdcnt: integer range 0 to LOG_WIDTH / PHY_WIDTH;
      variable tcnt: integer range 0 to LOG_WIDTH / PHY_WIDTH;
      variable reads_active: integer range 0 to READ_HIGHWATER;
      variable rd_ok, wr_ok: std_logic;
   begin
      if(rising_edge(clk)) then
         sfifo_rd <= '0';
         -- snarf data from rdr and present to slave port
         s_valid <= '0';
         if(rdcnt = rdcnt'high) then
            s_valid <= '1';
            s_out <= reg2_rdr;
            rdcnt := 0;
         end if;

         -- deassert master read/write from previous cycle if complete
         if(m_halt = '0') then
            m_rd <= '0';
            m_wr <= '0';
         end if;

         -- drive master read signals
         rd_ok := '1';
         if(rx_rd = '1' and m_halt = '0' and reads_active < READ_HIGHWATER) then
            m_rd <= '1';
            m_addr <= reg0_ar;
            m_be <= (others => '1');
            bump_address;
            reads_active := reads_active + 1;
         elsif(rx_rd = '1') then
            rd_ok := '0';
         end if;

         -- drive master write signals
         wr_ok := '1';
         if(rx_wr = '1' and m_halt = '0') then
            m_wr <= '1';
            m_addr <= reg0_ar;
            m_out <= reg1_ldr;
            m_be <= reg3_ctr(CTL_BE_H downto CTL_BE_L);
            bump_address;
         elsif(rx_wr = '1') then
            wr_ok := '0';
         end if;

         -- process incoming register writes (can override bump_address)
         if(rx_stb = '1' and rd_ok = '1' and wr_ok = '1') then
            case rx_sel is
               when "00" => reg0_ar <= shiftin(reg0_ar, rx_data);
               when "01" => reg1_ldr <= shiftin(reg1_ldr, rx_data);
               when "10" =>
                  reg2_rdr <= shiftin(reg2_rdr, rx_data);
                  rdcnt := rdcnt + 1;
               when "11" => reg3_ctr <= shiftin(reg3_ctr, rx_data);
               when others => null;
            end case;
         end if;

         if((rx_rd = '1' or rx_wr = '1' or rx_stb = '1') and (rd_ok = '1' and wr_ok = '1')) then
            sfifo_rd <= '1';
         end if;

         -- count transmitted reads
         if(tfifo_rd = '1') then
            tcnt := tcnt + 1;
            if(tcnt = tcnt'high) then
               tcnt := 0;
               reads_active := reads_active - 1;
            end if;
         end if;

         -- synch reset
         if(rst = '1') then
            m_rd <= '0';
            m_wr <= '0';
            reg0_ar <= (others => '0');
            reg1_ldr <= (others => '0');
            reg2_rdr <= (others => '0');
            reg3_ctr <= (CTL_BE_H downto CTL_BE_L => '1') & "01";
            rdcnt := 0;
            tcnt := 0;
            reads_active := 0;
         end if;
      end if;
   end process;
            
   tx: process(clk) is
      procedure bump_address is begin
         case rreg3_ctr(CTL_ADDRMODE_H downto CTL_ADDRMODE_L) is
            when "00" => null;
            when "01" => rreg0_ar <= rreg0_ar + ADDR_INC;
            when "10" => rreg0_ar <= rreg0_ar - ADDR_INC;
            when "11" => null;
         end case;
      end procedure;
      variable tar: std_logic_vector(31 downto 0);
      variable tarv: boolean;
      variable tdr: std_logic_vector(LOG_WIDTH - 1 downto 0);
      variable tdrv: boolean;
      variable txd: std_logic_vector(tx_data'range);
   begin
      if(rising_edge(clk)) then
         tfifo_rd <= '0';
         cfifo_rd <= '0';
         tx_rd_next <= '0';
         tx_wr_next <= '0';
         tx_rd <= tx_rd_next;
         tx_wr <= tx_wr_next;
         tx_stb <= '0';
         if(i_bp_synch(0) = '0') then
            if(tfifo_rdempty = '0') then
               tx_sel <= "10"; -- write remote rdr
               tx_data <= tfifo_out;
               tx_stb <= '1';
               tfifo_rd <= '1';
            elsif(cfifo_rdempty = '0') then
               -- one-shot load tar & tdr if they need it
               if(tarv = false) then
                  tar := cfifo_out_addr;
                  tarv := true;
               end if;
               if(tdrv = false) then
                  tdr := cfifo_out_data;
                  tdrv := true;
               end if;
               if(rreg0_ar /= cfifo_out_addr) then
                  txd := tar(PHY_WIDTH - 1 downto 0);
                  tx_sel <= "00"; -- write remote ar
                  tx_data <= txd;
                  tx_stb <= '1';
                  tar := rotate(tar, PHY_WIDTH);
                  rreg0_ar <= shiftin(rreg0_ar, txd);
               else
                  tarv := false;
                  if(cfifo_out_wr = '1' and rreg1_ldr /= cfifo_out_data) then
                     txd := tdr(PHY_WIDTH - 1 downto 0);
                     tx_sel <= "01"; -- write remote ldr
                     tx_data <= txd;
                     tx_stb <= '1';
                     tdr := rotate(tdr, PHY_WIDTH);
                     rreg1_ldr <= shiftin(rreg1_ldr, txd);
                  else
                     tdrv := false;
                     if(rreg3_ctr /= cfifo_out_be & "01") then
                        txd := (others => '0');
                        txd(CTL_BE_H downto CTL_BE_L) := cfifo_out_be;
                        txd(CTL_ADDRMODE_H downto CTL_ADDRMODE_L) := "01";
                        tx_sel <= "11"; -- write remote ctr
                        tx_data <= txd;
                        tx_stb <= '1';
                        rreg3_ctr <= shiftin(rreg3_ctr, txd);
                     end if;
                     tx_rd_next <= cfifo_out_rd;
                     tx_wr_next <= cfifo_out_wr;
                     cfifo_rd <= '1';
                     bump_address;
                  end if;
               end if;
            end if;
         end if;
            
         -- synch reset
         if(rst = '1') then
            rreg0_ar <= (others => '0');
            rreg1_ldr <= (others => '0');
            rreg2_rdr <= (others => '0');
            rreg3_ctr <= (CTL_BE_H downto CTL_BE_L => '1') & "01";
            tarv := false;
            tdrv := false;
            tx_rd <= '0';
            tx_rd_next <= '0';
            tx_wr <= '0';
            tx_wr_next <= '0';
            tx_stb <= '0';
         end if;
      end if;
   end process;

   cfifo: dcfifo generic map(
      LPM_WIDTH => cfifo_in'length,
      LPM_WIDTHU => log2(CFIFO_DEPTH),
      LPM_NUMWORDS => CFIFO_DEPTH,
      LPM_SHOWAHEAD => "ON",
      CLOCKS_ARE_SYNCHRONIZED => "true"
   )
   port map(
      aclr => rst,
      wrclk => clk,
      rdclk => not clk,
      data => cfifo_in,
      q => cfifo_out,
      rdreq => cfifo_rd,
      rdempty => cfifo_rdempty,
      wrreq => cfifo_wr,
      wrfull => cfifo_wrfull
   );

   cfifo_in <= s_be & s_in & s_wr & s_rd & pad32(s_addr, log2(LOG_WIDTH) - 3);
   cfifo_out_addr <= cfifo_out(31 downto 0);
   cfifo_out_rd <= cfifo_out(32);
   cfifo_out_wr <= cfifo_out(33);
   cfifo_out_data <= cfifo_out(34 + LOG_WIDTH - 1 downto 34);
   cfifo_out_be <= cfifo_out(cfifo_out'high downto cfifo_out'high - LOG_WIDTH / 8 + 1);
   s_halt <= cfifo_wrfull or slave_read_halt;
   cfifo_wr <= (not cfifo_wrfull) and (not slave_read_halt) and (s_rd or s_wr);

   tfifo: dcfifo_mixed_widths generic map(
      LPM_WIDTH => tfifo_in'length,
      LPM_WIDTH_R => tfifo_out'length,
      LPM_WIDTHU => log2(TFIFO_DEPTH),
      LPM_WIDTHU_R => log2(TFIFO_DEPTH * LOG_WIDTH / PHY_WIDTH),
      LPM_NUMWORDS => TFIFO_DEPTH,
      LPM_SHOWAHEAD => "ON",
      CLOCKS_ARE_SYNCHRONIZED => "true"
   )
   port map(
      aclr => rst,
      rdclk => not clk,
      wrclk => clk,
      data => tfifo_in,
      q => tfifo_out,
      rdreq => tfifo_rd,
      rdempty => tfifo_rdempty,
      wrreq => tfifo_wr,
      wrfull => tfifo_wrfull
   );

   tfifo_in <= m_in;
   tfifo_wr <= m_valid;

   sfifo: dcfifo generic map(
      LPM_WIDTH => sfifo_out'length,
      LPM_WIDTHU => log2(SFIFO_DEPTH),
      LPM_NUMWORDS => SFIFO_DEPTH,
      LPM_SHOWAHEAD => "ON",
      CLOCKS_ARE_SYNCHRONIZED => "false",
      RDSYNC_DELAYPIPE => 5,
      WRSYNC_DELAYPIPE => 5
   )
   port map(
      aclr => rst,
      rdclk => not clk,
      wrclk => not i_clk,
      data => sfifo_in,
      q => sfifo_out,
      rdreq => sfifo_rd,
      rdempty => sfifo_rdempty,
      wrreq => sfifo_wr,
      wrusedw => sfifo_wrusedw
   );
   rx_data <= sfifo_out(PHY_WIDTH - 1 downto 0);
   rx_sel <= sfifo_out(2 + PHY_WIDTH - 1 downto PHY_WIDTH);
   rx_stb <= not sfifo_out(sfifo_out'high - 2) and not sfifo_rdempty;
   rx_rd <= not sfifo_out(sfifo_out'high - 1) and not sfifo_rdempty;
   rx_wr <= not sfifo_out(sfifo_out'high) and not sfifo_rdempty;

   sfifo_in <= i_nwr & i_nrd & i_nstb & i_sel & i_data;
   sfifo_wr <= (not i_nwr) or (not i_nrd) or (not i_nstb);

   -- output registers/drivers
   o_clk <= clk;
   process(o_clk) is begin
      if(rising_edge(o_clk)) then
         o_data <= tx_data;
         o_nstb <= not tx_stb;
         o_sel <= tx_sel;
         o_nrd <= not tx_rd;
         o_nwr <= not tx_wr;

         if(rst = '1') then
            o_nstb <= '1';
            o_nrd <= '1';
            o_nwr <= '1';
         end if;
      end if;
   end process;

   -- drive outgoing backpressure signal
   process(i_clk) is begin
      if(falling_edge(i_clk)) then
         if(conv_integer(unsigned(sfifo_wrusedw)) >= SFIFO_HIGHWATER) then
            o_bp <= '1';
         else
            o_bp <= '0';
         end if;
      end if;
   end process;
   -- incoming backpressure clock domain resynch
   process(o_clk) is begin
      if(rising_edge(o_clk)) then
         i_bp_synch <= i_bp & i_bp_synch(i_bp_synch'high downto 1);
      end if;
   end process;
end architecture;
