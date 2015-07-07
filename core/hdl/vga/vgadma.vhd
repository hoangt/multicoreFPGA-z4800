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
use ieee.std_logic_1164.all, ieee.std_logic_arith.all, ieee.std_logic_unsigned.all, altera_mf.altera_mf_components.all;

entity vgadma is
   generic(
      HDISP                   :  natural := 1024;
      HSYNCSTART              :  natural := 1056;
      HSYNCEND                :  natural := 1296;
      HTOTAL                  :  natural := 1328;
      VDISP                   :  natural := 768;
      VSYNCSTART              :  natural := 783;
      VSYNCEND                :  natural := 791;
      VTOTAL                  :  natural := 807;
      HSYNC_ACT_HIGH          :  boolean := false;
      VSYNC_ACT_HIGH          :  boolean := false;
      BLANK_ACT_HIGH          :  boolean := false;
      MASTER_WIDTH            :  natural := 32;
      PBITS                   :  natural := 0;
      RBITS                   :  natural := 5;
      GBITS                   :  natural := 6;
      BBITS                   :  natural := 5;
      FIFO_DEPTH              :  natural := 128;
      FIFO_FILL_START         :  natural := 80;
      BURST_BITS              :  natural := 4
   );
   port(
      sclk                    :  in       std_logic;
      mclk                    :  in       std_logic;
      pclk                    :  in       std_logic;
      rst                     :  in       std_logic;

      hsync, vsync, blank     :  out      std_logic;
      r, g, b                 :  out      std_logic_vector(9 downto 0);

      m_addr                  :  buffer   std_logic_vector(31 downto 0);
      m_rd                    :  buffer   std_logic;
      m_halt                  :  in       std_logic;
      m_valid                 :  in       std_logic;
      m_data                  :  in       std_logic_vector(MASTER_WIDTH - 1 downto 0);
      m_burstcount            :  out      std_logic_vector(BURST_BITS - 1 downto 0);

      s_addr                  :  in       std_logic_vector(1 downto 0);
      s_rd                    :  in       std_logic;
      s_wr                    :  in       std_logic;
      s_in                    :  in       std_logic_vector(31 downto 0);
      s_out                   :  out      std_logic_vector(31 downto 0)
   );
end;

architecture vgadma of vgadma is
   constant BURST_LENGTH      :  natural := 2 ** (BURST_BITS - 1);
   constant FIFO_FILL_END     :  natural := FIFO_DEPTH - BURST_LENGTH;
   constant PIXBITS           :  natural := PBITS + RBITS + GBITS + BBITS;

   constant B_L               :  natural := 0;
   constant B_H               :  natural := B_L + BBITS - 1;
   constant G_L               :  natural := B_H + 1;
   constant G_H               :  natural := G_L + GBITS - 1;
   constant R_L               :  natural := G_H + 1;
   constant R_H               :  natural := R_L + RBITS - 1;

   function bool_to_std_logic(x: boolean) return std_logic is begin
      if(x) then
         return '1';
      else
         return '0';
      end if;
   end function;

   constant HSYNC_POLARITY    :  std_logic := bool_to_std_logic(HSYNC_ACT_HIGH);
   constant VSYNC_POLARITY    :  std_logic := bool_to_std_logic(VSYNC_ACT_HIGH);
   constant BLANK_POLARITY    :  std_logic := bool_to_std_logic(BLANK_ACT_HIGH);

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

   constant USEDW_BITS        :  natural := log2(FIFO_DEPTH + 1);

   type regs_t is array(2 downto 0) of std_logic_vector(31 downto 0);
   signal sregs, mregs, pregs :  regs_t;

   constant REG_CONTROL       :  integer := 0;
   constant REG_CONTROL_GO    :  integer := 0;
   constant REG_DMA_BASE      :  integer := 1;
   constant REG_DMA_MOD       :  integer := 2;

   signal sregs_changed       :  std_logic;
   signal sregs_changed2      :  std_logic;

   signal m_last              :  std_logic_vector(31 downto 0);
   signal m_go                :  std_logic;
   signal nr_outstanding      :  integer range 0 to FIFO_DEPTH;

   signal wrempty, wrfull     :  std_logic;

   signal m_addr_next         :  std_logic_vector(31 downto 0);

   signal wrusedw             :  std_logic_vector(USEDW_BITS - 1 downto 0);
   signal rddata              :  std_logic_vector(PIXBITS - 1 downto 0);
   signal rdempty, rdfull     :  std_logic;
   signal rdreq               :  std_logic;
   signal rdvalid             :  std_logic;
   signal h                   :  integer range 0 to HTOTAL;
   signal v                   :  integer range 0 to VTOTAL;
   signal xhsync, xvsync      :  std_logic;
   signal xblank              :  std_logic;
begin
   assert(FIFO_FILL_START < FIFO_FILL_END) report "FIFO thresholds fubar" severity error;
   assert((HDISP * VDISP) mod BURST_LENGTH = 0) report "Active region size must be multiple of BURST_LENGTH" severity error;

   dmafifo: dcfifo_mixed_widths generic map(
      LPM_WIDTH => MASTER_WIDTH,
      LPM_WIDTH_R => PIXBITS,
      LPM_NUMWORDS => FIFO_DEPTH,
      LPM_SHOWAHEAD => "off",
      ADD_RAM_OUTPUT_REGISTER => "on",
      ADD_USEDW_MSB_BIT => "on",
      LPM_WIDTHU => USEDW_BITS,
      CLOCKS_ARE_SYNCHRONIZED => "false",
      RDSYNC_DELAYPIPE => 5,
      WRSYNC_DELAYPIPE => 5
   )
   port map(
      aclr => not mregs(REG_CONTROL)(REG_CONTROL_GO),
      wrclk => mclk,
      data => m_data,
      wrreq => m_valid,
      wrempty => wrempty,
      wrfull => wrfull,
      wrusedw => wrusedw,
      q => rddata,
      rdclk => pclk,
      rdempty => rdempty,
      rdfull => rdfull,
      rdreq => rdreq
   );

   slave: process(sclk) is begin
      if(rising_edge(sclk)) then
         sregs_changed2 <= sregs_changed;
         sregs_changed <= '0';
         s_out <= sregs(conv_integer(unsigned(s_addr)));
         if(s_wr = '1') then
            sregs(conv_integer(unsigned(s_addr))) <= s_in;
            sregs_changed <= '1';
            sregs_changed2 <= '0';
         end if;

         sregs(REG_CONTROL)(31 downto 1) <= (others => '0');
         if(rst = '1') then
            sregs(REG_CONTROL)(REG_CONTROL_GO) <= '0';
            sregs_changed <= '1';
            sregs_changed2 <= '0';
         end if;
      end if;
   end process;

   m_addr_next <= mregs(REG_DMA_BASE) when m_addr = m_last else
                  m_addr + ((MASTER_WIDTH / 8) * BURST_LENGTH);

   master: process(mclk) is
      variable go: boolean;
      variable nr_outstanding_new: integer range nr_outstanding'range;
   begin
      if(rising_edge(mclk)) then
         nr_outstanding_new := nr_outstanding;
         if(m_rd = '1' and m_halt = '0') then
            nr_outstanding_new := nr_outstanding_new + BURST_LENGTH;
         end if;
         if(m_valid = '1') then
            nr_outstanding_new := nr_outstanding_new - 1;
         end if;
         nr_outstanding <= nr_outstanding_new;

         m_go <= mregs(REG_CONTROL)(REG_CONTROL_GO);
         go := m_go = '0' and mregs(REG_CONTROL)(REG_CONTROL_GO) = '1';

         if(go) then
            m_addr <= mregs(REG_DMA_BASE);
         elsif(m_halt = '0' and m_rd = '1') then
            m_addr <= m_addr_next;
         end if;
         if(sregs_changed2 = '1') then
            mregs <= sregs;
         end if;

         if(go or m_addr = m_last) then
            m_last <= mregs(REG_DMA_BASE) + mregs(REG_DMA_MOD) - ((MASTER_WIDTH / 8) * BURST_LENGTH);
         end if;

         if(mregs(REG_CONTROL)(REG_CONTROL_GO) = '1' and ((conv_integer(unsigned(wrusedw)) + nr_outstanding_new) < FIFO_FILL_START)) then
            m_rd <= '1';
         end if;
         if(((conv_integer(unsigned(wrusedw)) + nr_outstanding_new) >= FIFO_FILL_END) and m_halt = '0') then
            m_rd <= '0';
         end if;
         if(rst = '1') then
            nr_outstanding <= 0;
         end if;
      end if;
   end process;

   rdreq <= pregs(REG_CONTROL)(REG_CONTROL_GO) and not xblank;

   sync: process(pclk) is begin
      if(rising_edge(pclk)) then
         rdvalid <= rdreq;
         if(sregs_changed2 = '1') then
            pregs <= sregs;
         end if;
         if(pregs(REG_CONTROL)(REG_CONTROL_GO) = '0') then
            h <= HTOTAL;
            v <= VTOTAL;
            xhsync <= not HSYNC_POLARITY;
            xvsync <= not VSYNC_POLARITY;
            xblank <= '1';
         elsif(rdempty = '0') then
            h <= h + 1;
            if(h < HDISP and v < VDISP) then
               xblank <= '0';
            else
               xblank <= '1';
            end if;
            if(h = HSYNCSTART) then
               xhsync <= HSYNC_POLARITY;
            elsif(h = HSYNCEND) then
               xhsync <= not HSYNC_POLARITY;
            elsif(h = HTOTAL) then
               h <= 0;
               v <= v + 1;
            end if;
            if(v = VSYNCSTART) then
               xvsync <= VSYNC_POLARITY;
            elsif(v = VSYNCEND) then
               xvsync <= not VSYNC_POLARITY;
            elsif(v = VTOTAL - 1 and h = HTOTAL) then
               v <= 0;
            end if;
         end if;

         blank <= xblank xor (not BLANK_POLARITY);
         hsync <= xhsync;
         vsync <= xvsync;
      end if;
   end process;

   r <= rddata(R_H downto R_L) & (9 - RBITS downto 0 => '0');
   g <= rddata(G_H downto G_L) & (9 - GBITS downto 0 => '0');
   b <= rddata(B_H downto B_L) & (9 - BBITS downto 0 => '0');

   m_burstcount <= (m_burstcount'high => '1', others => '0');
end;
