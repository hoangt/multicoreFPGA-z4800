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
use ieee.std_logic_unsigned.all;
library altera_mf;
use altera_mf.altera_mf_components.all;
library z48common;
use z48common.z48common.all;

entity eth_dma is
   generic(
      BUS_WIDTH               :  natural := 64;
      BUS_BYTES               :  natural := 8;
      BUS_BYTES_LOG2          :  natural := 3;
      RX_RING_BITS            :  natural := 6;
      RX_ERROR_BITS           :  natural := 6;
      TX_RING_BITS            :  natural := 6;
      TX_ERROR_BITS           :  natural := 1;
      TX_FIFO_DEPTH           :  natural := 128
   );
   port(
      clk                     :  in       std_logic;
      rst                     :  in       std_logic;

      rxr_addr                :  in       std_logic_vector(RX_RING_BITS - 1 downto 0);
      rxr_rd                  :  in       std_logic;
      rxr_wr                  :  in       std_logic;
      rxr_in                  :  in       std_logic_vector(63 downto 0);
      rxr_out                 :  out      std_logic_vector(63 downto 0);
      rxr_be                  :  in       std_logic_vector(7 downto 0);

      rxs_data                :  in       std_logic_vector(BUS_WIDTH - 1 downto 0);
      rxs_empty               :  in       std_logic_vector(BUS_BYTES_LOG2 - 1 downto 0);
      rxs_error               :  in       std_logic_vector(RX_ERROR_BITS - 1 downto 0);
      rxs_sop                 :  in       std_logic;
      rxs_eop                 :  in       std_logic;
      rxs_valid               :  in       std_logic;
      rxs_ready               :  buffer   std_logic;

      rxd_addr                :  out      std_logic_vector(31 downto 0);
      rxd_wr                  :  out      std_logic;
      rxd_out                 :  out      std_logic_vector(BUS_WIDTH - 1 downto 0);
      rxd_halt                :  in       std_logic;



      txr_addr                :  in       std_logic_vector(TX_RING_BITS - 1 downto 0);
      txr_rd                  :  in       std_logic;
      txr_wr                  :  in       std_logic;
      txr_in                  :  in       std_logic_vector(63 downto 0);
      txr_out                 :  out      std_logic_vector(63 downto 0);
      txr_be                  :  in       std_logic_vector(7 downto 0);

      txd_addr                :  out      std_logic_vector(31 downto 0);
      txd_rd                  :  buffer   std_logic;
      txd_in                  :  in       std_logic_vector(BUS_WIDTH - 1 downto 0);
      txd_halt                :  in       std_logic;
      txd_valid               :  in       std_logic;

      txs_data                :  out      std_logic_vector(BUS_WIDTH - 1 downto 0);
      txs_empty               :  out      std_logic_vector(BUS_BYTES_LOG2 - 1 downto 0);
      txs_error               :  out      std_logic_vector(TX_ERROR_BITS - 1 downto 0);
      txs_sop                 :  out      std_logic;
      txs_eop                 :  out      std_logic;
      txs_valid               :  buffer   std_logic;
      txs_ready               :  in       std_logic;



      csr_addr                :  in       std_logic_vector(1 downto 0);
      csr_rd                  :  in       std_logic;
      csr_wr                  :  in       std_logic;
      csr_in                  :  in       std_logic_vector(31 downto 0);
      csr_out                 :  out      std_logic_vector(31 downto 0);

      phy_irqpin              :  in       std_logic;

      phy_irq                 :  out      std_logic;
      rx_irq                  :  out      std_logic;
      tx_irq                  :  out      std_logic
   );
end;

architecture eth_dma of eth_dma is
   constant CSR_RCONTROL_RXRST:  natural := 0;
   constant CSR_RCONTROL_RXENA:  natural := 1;
   constant CSR_RCONTROL_RXIE :  natural := 2;
   constant CSR_RCONTROL_RXIS :  natural := 3;
   constant CSR_RCONTROL_PHYIE:  natural := 30;
   constant CSR_RCONTROL_PHYIS:  natural := 31;

   constant CSR_TCONTROL_TXRST:  natural := 0;
   constant CSR_TCONTROL_TXENA:  natural := 1;
   constant CSR_TCONTROL_TXIE :  natural := 2;
   constant CSR_TCONTROL_TXIS :  natural := 3;

   constant LENGTH_BITS       :  natural := 16;

   constant DESC_ADDRL        :  natural := 0;
   constant DESC_ADDRH        :  natural := DESC_ADDRL + 32 - 1;
   constant DESC_LENL         :  natural := DESC_ADDRH + 1;
   constant DESC_LENH         :  natural := DESC_LENL + LENGTH_BITS - 1;
   constant DESC_ERRL         :  natural := DESC_LENH + 1;
   constant DESC_ERRH         :  natural := DESC_ERRL + 8 - 1;
   constant DESC_STATUS_HW    :  natural := DESC_ERRH + 1;

   function swab(x: std_logic_vector) return std_logic_vector is
      variable high           :  std_logic_vector(x'length / 2 - 1 downto 0);
      variable low            :  std_logic_vector(x'length / 2 - 1 downto 0);
   begin
      assert(2 ** log2c(x'length) = x'length) report "can't swab non-power-of-2 vector" severity error;
      if(x'length < 16) then
         return x;
      else
         high := x(x'length - 1 downto x'length / 2);
         low := x(x'length / 2 - 1 downto 0);
         return swab(low) & swab(high);
      end if;
   end function;

   signal rx_desc_addr        :  std_logic_vector(RX_RING_BITS - 1 downto 0);
   signal rx_desc_curaddr     :  std_logic_vector(RX_RING_BITS - 1 downto 0);
   signal rx_desc_q           :  std_logic_vector(63 downto 0);
   signal rx_desc_data        :  std_logic_vector(63 downto 0);
   signal rx_desc_wren        :  std_logic;

   signal rx_offset           :  std_logic_vector(15 downto 0);

   signal rx_len_hit          :  std_logic;

   signal rx_start            :  std_logic;
   signal rx_run              :  std_logic;
   signal rx_running          :  std_logic;
   signal rx_end              :  std_logic;
   signal rx_err              :  std_logic;
   signal rx_done             :  std_logic;

   signal rx_irq_count        :  std_logic_vector(RX_RING_BITS + 1 - 1 downto 0);
   signal rx_irq_done         :  std_logic;
   signal rx_soft_reset       :  std_logic;
   signal rcontrol            :  std_logic_vector(31 downto 0);


   constant TX_FIFO_DEPTH_LOG2:  natural := log2c(TX_FIFO_DEPTH);
   constant TX_CONTROL_EOP    :  natural := 0;
   constant TX_CONTROL_SOP    :  natural := TX_CONTROL_EOP + 1;
   constant TX_CONTROL_MODL   :  natural := TX_CONTROL_SOP + 1;
   constant TX_CONTROL_MODH   :  natural := TX_CONTROL_MODL + BUS_BYTES_LOG2 - 1;
   constant TX_CONTROL_EMPL   :  natural := TX_CONTROL_MODH + 1;
   constant TX_CONTROL_EMPH   :  natural := TX_CONTROL_EMPL + BUS_BYTES_LOG2 - 1;
   constant TX_CONTROL_WIDTH  :  natural := TX_CONTROL_EMPH + 1;

   signal tx_desc_addr        :  std_logic_vector(TX_RING_BITS - 1 downto 0);
   signal tx_desc_curaddr     :  std_logic_vector(TX_RING_BITS - 1 downto 0);
   signal tx_desc_q           :  std_logic_vector(63 downto 0);
   signal tx_desc_data        :  std_logic_vector(63 downto 0);
   signal tx_desc_wren        :  std_logic;

   signal tx_unal_len         :  std_logic_vector(LENGTH_BITS - 1 downto 0);
   signal tx_empty            :  std_logic_vector(BUS_BYTES_LOG2 - 1 downto 0);
   signal tx_sop              :  std_logic;
   signal tx_eop              :  std_logic;
   signal tx_done             :  std_logic;

   attribute keep             :  boolean;
   attribute keep of tx_sop   :  signal is true;
   attribute keep of tx_eop   :  signal is true;

   signal tx_data_empty       :  std_logic;
   signal tx_control_empty    :  std_logic;
   signal tx_control_full     :  std_logic;
   signal tx_control_in       :  std_logic_vector(TX_CONTROL_WIDTH - 1 downto 0);
   signal tx_control_out      :  std_logic_vector(TX_CONTROL_WIDTH - 1 downto 0);

   signal tx_align_empty      :  std_logic_vector(BUS_BYTES_LOG2 - 1 downto 0);
   signal tx_align_offset     :  std_logic_vector(BUS_BYTES_LOG2 - 1 downto 0);
   signal tx_align_data       :  std_logic_vector(BUS_WIDTH - 1 downto 0);
   signal tx_align_sop        :  std_logic;
   signal tx_align_eop        :  std_logic;
   signal tx_align_ready      :  std_logic;
   signal tx_align_valid      :  std_logic;

   signal txd_read_issue      :  std_logic;

   signal tx_irq_count        :  std_logic_vector(TX_RING_BITS + 1 - 1 downto 0);
   signal tx_irq_done         :  std_logic;
   signal tx_soft_reset       :  std_logic;
   signal tcontrol            :  std_logic_vector(31 downto 0);
begin

------------------------------------RX DMA-------------------------------------
   rx_descs: altsyncram generic map(
      WIDTH_A => 64,
      WIDTHAD_A => RX_RING_BITS,
      WIDTH_B => 64,
      WIDTHAD_B => RX_RING_BITS,
      WIDTH_BYTEENA_B => 8
   )
   port map(
      clock0 => clk,
      clock1 => clk,
      address_a => rx_desc_addr,
      q_a => rx_desc_q,
      data_a => rx_desc_data,
      wren_a => rx_desc_wren,
      address_b => rxr_addr,
      q_b => rxr_out,
      data_b => rxr_in,
      wren_b => rxr_wr,
      byteena_b => rxr_be
   );

   rxd_addr <= rx_desc_q(DESC_ADDRH downto DESC_ADDRL) + rx_offset;
   rxd_wr <= rx_desc_q(DESC_STATUS_HW) and rxs_valid;
   rxs_ready <= rx_desc_q(DESC_STATUS_HW) and not (rxd_halt or rx_done);

   rxd_out <= swab(rxs_data);

   rx_len_hit <=
      '1' when  
         unsigned(rx_offset + BUS_BYTES) = 
         unsigned(rx_desc_q(DESC_LENH downto DESC_LENL)) else
      '0';
   
   rx_start <= rcontrol(CSR_RCONTROL_RXENA) and rxs_sop and rxs_ready and rxs_valid;
   rx_run <= rx_start or rx_running;
   rx_end <= rx_run and ((rxs_eop and rxs_ready and rxs_valid) or rx_len_hit);
   rx_err <=
      '1' when
         rxs_ready = '1' and rxs_valid = '1' and
         rxs_error /= (rxs_error'range => '0') else
      '0';

   rx_update_desc: process(rx_desc_q, rx_offset, rx_err, rxs_error, rx_end, rxs_empty) is begin
      rx_desc_data <= rx_desc_q;
      rx_desc_wren <= '0';
      if(rx_err = '1') then
         rx_desc_data(DESC_ERRL + rxs_error'high downto DESC_ERRL) <= rx_desc_q(DESC_ERRL + rxs_error'high downto DESC_ERRL) or rxs_error;
         rx_desc_wren <= '1';
      end if;
      if(rx_end = '1') then
         rx_desc_data(DESC_STATUS_HW) <= '0';
         rx_desc_data(DESC_LENH downto DESC_LENL) <= rx_offset + BUS_BYTES - rxs_empty;
         rx_desc_wren <= '1';
      end if;
   end process;

   rx_desc_addr <=
      (others => '0') when rst = '1' or rx_soft_reset = '1' else
      rx_desc_curaddr + 1 when rx_done = '1' else
      rx_desc_curaddr;

   rx: process(clk) is begin
      if(rising_edge(clk)) then
         if(rx_start = '1') then
            rx_running <= '1';
         end if;
         if(rx_run = '1' and rxd_halt = '0') then
            rx_offset <= rx_offset + BUS_BYTES;
         end if;
         if(rx_end = '1') then
            rx_offset <= (others => '0');
            rx_running <= '0';
         end if;
         rx_done <= rx_end;

         if(rx_end = '1' and rx_irq_done = '0') then
            rx_irq_count <= rx_irq_count + 1;
         elsif(rx_end = '0' and rx_irq_done = '1') then
            rx_irq_count <= rx_irq_count - 1;
         end if;

         rx_desc_curaddr <= rx_desc_addr;

         if(rst = '1' or rx_soft_reset = '1') then
            rx_running <= '0';
            rx_done <= '0';
            rx_offset <= (others => '0');
            rx_irq_count <= (others => '0');
         end if;
      end if;
   end process;

   rx_irq <= rcontrol(CSR_RCONTROL_RXIE) and rcontrol(CSR_RCONTROL_RXIS);

------------------------------------TX DMA-------------------------------------
   tx_descs: altsyncram generic map(
      WIDTH_A => 64,
      WIDTHAD_A => TX_RING_BITS,
      WIDTH_B => 64,
      WIDTHAD_B => TX_RING_BITS,
      WIDTH_BYTEENA_B => 8
   )
   port map(
      clock0 => clk,
      clock1 => clk,
      address_a => tx_desc_addr,
      q_a => tx_desc_q,
      data_a => tx_desc_data,
      wren_a => tx_desc_wren,
      address_b => txr_addr,
      q_b => txr_out,
      data_b => txr_in,
      wren_b => txr_wr,
      byteena_b => txr_be
   );

   tx_data_fifo: scfifo generic map(
      LPM_WIDTH => BUS_WIDTH,
      LPM_NUMWORDS => TX_FIFO_DEPTH,
      LPM_WIDTHU => TX_FIFO_DEPTH_LOG2,
      LPM_SHOWAHEAD => "ON"
   )
   port map(
      clock => clk,
      sclr => rst,
      data => txd_in,
      wrreq => txd_valid,
      rdreq => tx_align_ready and tx_align_valid,
      empty => tx_data_empty,
      q => tx_align_data
   );

   tx_control_in <= tx_empty & tx_desc_q(DESC_ADDRL + BUS_BYTES_LOG2 - 1 downto DESC_ADDRL) & tx_sop & tx_eop;
   tx_control_fifo: scfifo generic map(
      LPM_WIDTH => TX_CONTROL_WIDTH,
      LPM_NUMWORDS => TX_FIFO_DEPTH,
      LPM_WIDTHU => TX_FIFO_DEPTH_LOG2,
      LPM_SHOWAHEAD => "ON"
   )
   port map(
      clock => clk,
      sclr => rst,
      data => tx_control_in,
      wrreq => txd_read_issue,
      rdreq => tx_align_ready and tx_align_valid,
      empty => tx_control_empty,
      full => tx_control_full,
      q => tx_control_out
   );
   tx_align_empty <=
      (others => '0') when tx_control_out(TX_CONTROL_EOP) = '0' else
      tx_control_out(TX_CONTROL_EMPH downto TX_CONTROL_EMPL);
   tx_align_offset <= tx_control_out(TX_CONTROL_MODH downto TX_CONTROL_MODL);
   tx_align_sop <= tx_control_out(TX_CONTROL_SOP);
   tx_align_eop <= tx_control_out(TX_CONTROL_EOP);
   tx_align_valid <= not tx_data_empty and not tx_control_empty;

   tx_align: entity work.eth_align port map(
      clk => clk,
      rst => rst,

      in_empty => tx_align_empty,
      in_offset => tx_align_offset,
      in_data => tx_align_data,
      in_sop => tx_align_sop,
      in_eop => tx_align_eop,
      in_ready => tx_align_ready,
      in_valid => tx_align_valid,

      out_empty => txs_empty,
      swab(out_data) => txs_data,
      out_sop => txs_sop,
      out_eop => txs_eop,
      out_ready => txs_ready,
      out_valid => txs_valid
   );
   txs_error <= (others => '0');
   
   txd_read_issue <= txd_rd and not txd_halt;

   txd_addr <= tx_desc_q(DESC_ADDRH downto DESC_ADDRL) and (31 downto BUS_BYTES_LOG2 => '1', BUS_BYTES_LOG2 - 1 downto 0 => '0');
   txd_rd <= tcontrol(CSR_TCONTROL_TXENA) and tx_desc_q(DESC_STATUS_HW) and not tx_control_full;

   -- voodoo magic; guru meditation recommended
   tx_empty <= (not tx_desc_q(DESC_LENL + BUS_BYTES_LOG2 - 1 downto DESC_LENL)) + 1; 
   tx_unal_len <=
      tx_desc_q(DESC_LENH downto DESC_LENL) + (
         (LENGTH_BITS - 1 downto BUS_BYTES_LOG2 => '0') &
         tx_desc_q(DESC_ADDRL + BUS_BYTES_LOG2 - 1 downto DESC_ADDRL)
      );
   tx_eop <= -- assert EOP if we can get all remaining bytes in one go
      '1' when tx_unal_len(LENGTH_BITS - 1 downto BUS_BYTES_LOG2) = 0 else
      '1' when tx_unal_len(LENGTH_BITS - 1 downto 0) = BUS_BYTES else
      '0';

   tx_update_desc: process(tx_desc_q, tx_eop) is begin
      tx_desc_data <= tx_desc_q;
      tx_desc_data(DESC_ADDRH downto DESC_ADDRL) <= tx_desc_q(DESC_ADDRH downto DESC_ADDRL) + BUS_BYTES;
      tx_desc_data(DESC_LENH downto DESC_LENL) <= tx_desc_q(DESC_LENH downto DESC_LENL) - BUS_BYTES;
      if(tx_eop = '1') then
         tx_desc_data(DESC_STATUS_HW) <= '0';
      end if;
   end process;
   tx_desc_wren <= txd_read_issue;

   tx_desc_addr <=
      (others => '0') when rst = '1' or tx_soft_reset = '1' else
      tx_desc_curaddr + 1 when tx_done = '1' else
      tx_desc_curaddr;

   tx: process(clk) is
   begin
      if(rising_edge(clk)) then
         tx_done <= '0';
         if(txd_read_issue = '1') then
            tx_done <= tx_eop;
            tx_sop <= tx_eop;
         end if;

         if(txd_read_issue = '1' and tx_eop = '1' and tx_irq_done = '0') then
            tx_irq_count <= tx_irq_count + 1;
         elsif((txd_read_issue = '0' or tx_eop = '0') and tx_irq_done = '1') then
            tx_irq_count <= tx_irq_count - 1;
         end if;

         tx_desc_curaddr <= tx_desc_addr;

         if(rst = '1' or tx_soft_reset = '1') then
            tx_done <= '0';
            tx_sop <= '1';
            tx_irq_count <= (others => '0');
            tx_desc_curaddr <= (others => '0');
         end if;
      end if;
   end process;

   tx_irq <= tcontrol(CSR_TCONTROL_TXIE) and tcontrol(CSR_TCONTROL_TXIS);

-------------------------------------CSRS--------------------------------------


   csrs: process(clk) is begin
      if(rising_edge(clk)) then
         rx_soft_reset <= rcontrol(CSR_RCONTROL_RXRST);
         tx_soft_reset <= tcontrol(CSR_TCONTROL_TXRST);

         rx_irq_done <= '0';
         tx_irq_done <= '0';

         case csr_addr is
            when "00" =>
               csr_out <= rcontrol;
               if(csr_wr = '1') then
                  rcontrol <= csr_in;
               end if;
            when "01" =>
               csr_out <= tcontrol;
               if(csr_wr = '1') then
                  tcontrol <= csr_in;
               end if;
            when "10" =>
               csr_out <= (RX_RING_BITS => '1', others => '0');
               rx_irq_done <= csr_wr;
            when "11" =>
               csr_out <= (TX_RING_BITS => '1', others => '0');
               tx_irq_done <= csr_wr;
            when others =>
               csr_out <= (others => '-');
         end case;

         if(rx_irq_count /= (rx_irq_count'range => '0')) then
            rcontrol(CSR_RCONTROL_RXIS) <= '1';
         else
            rcontrol(CSR_RCONTROL_RXIS) <= '0';
         end if;
         if(tx_irq_count /= (tx_irq_count'range => '0')) then
            tcontrol(CSR_TCONTROL_TXIS) <= '1';
         else
            tcontrol(CSR_TCONTROL_TXIS) <= '0';
         end if;
         rcontrol(CSR_RCONTROL_PHYIS) <= phy_irqpin;

         if(rst = '1') then
            rcontrol <= (others => '0');
            tcontrol <= (others => '0');
         end if;
         if(rx_soft_reset = '1') then
            rcontrol <= (others => '0');
         end if;
         if(tx_soft_reset = '1') then
            tcontrol <= (others => '0');
         end if;
      end if;
   end process;

   phy_irq <= rcontrol(CSR_RCONTROL_PHYIE) and rcontrol(CSR_RCONTROL_PHYIS);
end;
