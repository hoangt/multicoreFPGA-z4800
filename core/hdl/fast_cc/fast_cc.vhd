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

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
library altera_mf;
use altera_mf.altera_mf_components.all;

entity fast_cc is
   generic(
      ADDRBITS                   :  natural := 16;
      WIDTH                      :  natural := 32;
      SMFIFO_DEPTH               :  natural := 8;
      MSFIFO_DEPTH               :  natural := 16;
      CLOCKS_SYNCHED             :  boolean := false;
      SYNCH_STAGES               :  integer := 3;
      ENABLE_BURST               :  boolean := false;
      BURST_BITS                 :  natural := 5;
      BURST_WRAP                 :  boolean := false;
      SINGLE_BURST               :  boolean := false
   );
   port(
      a_rst                      :  in       std_logic;

      s_clk                      :  in       std_logic;
      s_addr                     :  in       std_logic_vector(ADDRBITS - 1 downto 0);
      s_rd                       :  in       std_logic;
      s_wr                       :  in       std_logic;
      s_in                       :  in       std_logic_vector(WIDTH - 1 downto 0);
      s_out                      :  out      std_logic_vector(WIDTH - 1 downto 0);
      s_be                       :  in       std_logic_vector(WIDTH / 8 - 1 downto 0);
      s_halt                     :  buffer   std_logic;
      s_valid                    :  out      std_logic;
      s_burstcount               :  in       std_logic_vector(BURST_BITS - 1 downto 0);
      s_drained                  :  out      std_logic;

      m_clk                      :  in       std_logic;
      m_addr                     :  out      std_logic_vector(31 downto 0);
      m_rd                       :  buffer   std_logic;
      m_wr                       :  buffer   std_logic;
      m_in                       :  in       std_logic_vector(WIDTH - 1 downto 0);
      m_out                      :  out      std_logic_vector(WIDTH - 1 downto 0);
      m_be                       :  out      std_logic_vector(WIDTH / 8 - 1 downto 0);
      m_halt                     :  in       std_logic;
      m_valid                    :  in       std_logic;
      m_burstcount               :  out      std_logic_vector(BURST_BITS - 1 downto 0)
   );
end;

architecture fast_cc of fast_cc is
   function log2c(x: integer) return integer is
      variable ret: integer := 0;
      variable i: integer := 1;
   begin
      while(i < x) loop
         i := i * 2;
         ret := ret + 1;
      end loop;
      return ret;
   end function;
   function tfstr(x: boolean) return string is begin
      if(x) then
         return "true";
      else
         return "false";
      end if;
   end function;

   constant BYTES                :  natural := WIDTH / 8;
   constant BYTEBITS             :  natural := log2c(BYTES);

   constant SMFIFO_ADDRL         :  integer := 0;
   constant SMFIFO_ADDRH         :  integer := SMFIFO_ADDRL + ADDRBITS - 1;
   constant SMFIFO_DATAL         :  integer := SMFIFO_ADDRH + 1;
   constant SMFIFO_DATAH         :  integer := SMFIFO_DATAL + WIDTH - 1;
   constant SMFIFO_BEL           :  integer := SMFIFO_DATAH + 1;
   constant SMFIFO_BEH           :  integer := SMFIFO_BEL + BYTES - 1;
   constant SMFIFO_RD            :  integer := SMFIFO_BEH + 1;
   constant SMFIFO_WR            :  integer := SMFIFO_RD + 1;
   constant SMFIFO_BURSTL        :  integer := SMFIFO_WR + 1;
   constant SMFIFO_BURSTH        :  integer := SMFIFO_BURSTL + BURST_BITS - 1;

   signal smfifo_in, smfifo_out  :  std_logic_vector(BURST_BITS + 2 + BYTES + WIDTH + ADDRBITS - 1 downto 0);
   signal smfifo_rdempty         :  std_logic;
   signal m_wantissue            :  std_logic;

   signal req_inflight, req_count:  integer range 0 to MSFIFO_DEPTH;
   signal msfifo_full, msfifo_rdempty: std_logic;
   signal msfifo_full_r          :  std_logic;
   signal msfifo_wrusedw         :  std_logic_vector(log2c(MSFIFO_DEPTH) - 1 downto 0);
   function get_thresh return integer is
      variable BURST_THRESH: integer;
   begin
      if(ENABLE_BURST) then
         if(SINGLE_BURST) then
            BURST_THRESH := (2 ** (BURST_BITS - 1));
         else
            BURST_THRESH := (2 ** (BURST_BITS - 1)) * 2;
         end if;
      else
         BURST_THRESH := 1;
      end if;
      if(CLOCKS_SYNCHED) then
         return MSFIFO_DEPTH - (2 + BURST_THRESH);
      else
         return MSFIFO_DEPTH - (2 + BURST_THRESH + SYNCH_STAGES);
      end if;
   end function;
   constant MSFIFO_THRESH        :  integer := get_thresh;
begin
   assert MSFIFO_THRESH >= 4 report "MSFIFO_DEPTH too low" severity error;

   smfifo: dcfifo generic map(
      LPM_WIDTH => smfifo_in'length,
      LPM_WIDTHU => log2c(SMFIFO_DEPTH),
      LPM_NUMWORDS => SMFIFO_DEPTH,
      LPM_SHOWAHEAD => "ON",
      CLOCKS_ARE_SYNCHRONIZED => tfstr(CLOCKS_SYNCHED),
      RDSYNC_DELAYPIPE => 2 + SYNCH_STAGES,
      WRSYNC_DELAYPIPE => 2 + SYNCH_STAGES
   )
   port map(
      aclr => a_rst,
      wrclk => s_clk,
      wrreq => (s_rd or s_wr) and not s_halt,
      data => smfifo_in,
      wrfull => s_halt,
      rdclk => m_clk,
      rdreq => (m_rd or m_wr) and not m_halt,
      q => smfifo_out,
      rdempty => smfifo_rdempty,
      wrempty => s_drained
   );

   smfifo_in(SMFIFO_ADDRH downto SMFIFO_ADDRL) <= s_addr;
   smfifo_in(SMFIFO_DATAH downto SMFIFO_DATAL) <= s_in;
   smfifo_in(SMFIFO_BEH downto SMFIFO_BEL) <= s_be;
   smfifo_in(SMFIFO_RD) <= s_rd;
   smfifo_in(SMFIFO_WR) <= s_wr;
   smfifo_in(SMFIFO_BURSTH downto SMFIFO_BURSTL) <= s_burstcount;

   m_addr <= (31 downto ADDRBITS + BYTEBITS => '0') & smfifo_out(SMFIFO_ADDRH downto SMFIFO_ADDRL) & (BYTEBITS - 1 downto 0 => '0');
   m_out <= smfifo_out(SMFIFO_DATAH downto SMFIFO_DATAL);
   m_be <= smfifo_out(SMFIFO_BEH downto SMFIFO_BEL);
   m_rd <= smfifo_out(SMFIFO_RD) and m_wantissue;
   m_wr <= smfifo_out(SMFIFO_WR) and m_wantissue;
   m_burstcount <= smfifo_out(SMFIFO_BURSTH downto SMFIFO_BURSTL);

   m_wantissue <= not smfifo_rdempty and not msfifo_full_r;

   msfifo: dcfifo generic map(
      LPM_WIDTH => WIDTH,
      LPM_WIDTHU => log2c(MSFIFO_DEPTH),
      LPM_NUMWORDS => MSFIFO_DEPTH,
      LPM_SHOWAHEAD => "ON",
      CLOCKS_ARE_SYNCHRONIZED => tfstr(CLOCKS_SYNCHED),
      RDSYNC_DELAYPIPE => 2 + SYNCH_STAGES,
      WRSYNC_DELAYPIPE => 2 + SYNCH_STAGES
   )
   port map(
      aclr => a_rst,
      wrclk => m_clk,
      wrreq => m_valid,
      data => m_in,
      wrusedw => msfifo_wrusedw,
      rdclk => s_clk,
      rdreq => not msfifo_rdempty,
      q => s_out,
      rdempty => msfifo_rdempty
   );
   s_valid <= not msfifo_rdempty;

   req_count <= req_inflight + conv_integer(unsigned(msfifo_wrusedw));
   msfifo_full <= '1' when req_count >= MSFIFO_THRESH else '0';

   process(a_rst, m_clk) is
      variable cnt: integer range req_inflight'range;
   begin
      if(a_rst = '1') then
         req_inflight <= 0;
      elsif(rising_edge(m_clk)) then
         cnt := req_inflight;
         if(m_rd = '1' and m_halt = '0') then
            if(ENABLE_BURST) then
               cnt := cnt + conv_integer(unsigned((smfifo_out(SMFIFO_BURSTH downto SMFIFO_BURSTL))));
            else
               cnt := cnt + 1;
            end if;
         end if;
         if(m_valid = '1') then
            cnt := cnt - 1;
         end if;
         req_inflight <= cnt;
         msfifo_full_r <= msfifo_full;
      end if;
   end process;
end;
