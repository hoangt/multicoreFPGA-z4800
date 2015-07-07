#Copyright (C) 2012 Will Simoneau <simoneau@ele.uri.edu>
#
#This program is free software; you can redistribute it and/or
#modify it under the terms of the GNU General Public License,
#version 2, as published by the Free Software Foundation.
#Other versions of the license may NOT be used without
#the written consent of the copyright holder(s).
#
#This program is distributed in the hope that it will be useful,
#but WITHOUT ANY WARRANTY; without even the implied warranty of
#MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#GNU General Public License for more details.
#
#You should have received a copy of the GNU General Public License
#along with this program; if not, write to the Free Software
#Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

package require -exact sopc 9.1

# helper functions shamelessly stolen from Altera's Nios .tcl file
proc proc_set_display_format {NAME DISPLAY_HINT} {
    set_parameter_property  $NAME   "DISPLAY_HINT"      $DISPLAY_HINT
}

proc proc_add_parameter {GROUP NAME DISPLAY_NAME DESCRIPTION TYPE DEFAULT args} {
    add_parameter           $NAME $TYPE $DEFAULT "$DESCRIPTION"
    set_parameter_property  $NAME "DISPLAY_NAME" "$DISPLAY_NAME"
    if {$args != ""} then {
        set_parameter_property  $NAME "ALLOWED_RANGES" $args
    }
    add_display_item    $GROUP   $NAME    parameter
}

# +-----------------------------------
# | module z4800
# | 
set_module_property NAME z4800
set_module_property VERSION 1.0
set_module_property INTERNAL false
set_module_property GROUP ""
set_module_property DISPLAY_NAME "Z4800 CPU"
set_module_property TOP_LEVEL_HDL_FILE z4800.vhd
set_module_property TOP_LEVEL_HDL_MODULE z4800
set_module_property INSTANTIATE_IN_SYSTEM_MODULE true
set_module_property EDITABLE false
set_module_property ANALYZE_HDL true
# | 
# +-----------------------------------

# +-----------------------------------
# | files
# | 
add_file altregfile.vhd {SYNTHESIS SIMULATION}
add_file xorregfile.vhd {SYNTHESIS SIMULATION}
add_file bht.vhd {SYNTHESIS SIMULATION}
add_file bshift.vhd {SYNTHESIS SIMULATION}
add_file bshift_stage.vhd {SYNTHESIS SIMULATION}
add_file dspshift.vhd {SYNTHESIS SIMULATION}
add_file btb.vhd {SYNTHESIS SIMULATION}
add_file cam.vhd {SYNTHESIS SIMULATION}
add_file camcell.vhd {SYNTHESIS SIMULATION}
add_file cop0.vhd {SYNTHESIS SIMULATION}
add_file fetchpredict.vhd {SYNTHESIS SIMULATION}
add_file fifo.vhd {SYNTHESIS SIMULATION}
add_file z4800.vhd {SYNTHESIS SIMULATION}
add_file z48core.vhd {SYNTHESIS SIMULATION}
add_file z48alu.vhd {SYNTHESIS SIMULATION}
add_file z48common.vhd {SYNTHESIS SIMULATION}
add_file z48debug.vhd {SYNTHESIS SIMULATION}
add_file z48group.vhd {SYNTHESIS SIMULATION}
add_file z48iqueue.vhd {SYNTHESIS SIMULATION}
add_file z48pipe.vhd {SYNTHESIS SIMULATION}
add_file z48rastack.vhd {SYNTHESIS SIMULATION}
add_file jtlb.vhd {SYNTHESIS SIMULATION}
add_file mipsidec.vhd {SYNTHESIS SIMULATION}
add_file muldiv.vhd {SYNTHESIS SIMULATION}
add_file mul_comb.vhd {SYNTHESIS SIMULATION}
add_file div_comb.vhd {SYNTHESIS SIMULATION}
add_file div_seq.vhd {SYNTHESIS SIMULATION}
add_file div_test.vhd {SYNTHESIS SIMULATION}
add_file ramwrap.vhd {SYNTHESIS SIMULATION}
add_file tracebuf.vhd {SYNTHESIS SIMULATION}
add_file utlb.vhd {SYNTHESIS SIMULATION}
add_file mbox.vhd {SYNTHESIS SIMULATION}
add_file perf.vhd {SYNTHESIS SIMULATION}
add_file mcheck.vhd {SYNTHESIS SIMULATION}
add_file ../fast_cc/fast_cc.vhd {SYNTHESIS SIMULATION}
add_file l1.vhd {SYNTHESIS SIMULATION}
add_file l1_replace.vhd {SYNTHESIS SIMULATION}
add_file l1_replace_random.vhd {SYNTHESIS SIMULATION}
add_file l1_replace_lru.vhd {SYNTHESIS SIMULATION}
add_file l1_replace_plru.vhd {SYNTHESIS SIMULATION}
add_file l1_replace_randomhybrid.vhd {SYNTHESIS SIMULATION}
add_file lfsr.vhd {SYNTHESIS SIMULATION}
add_file reg.vhd {SYNTHESIS SIMULATION}
add_file z48cc.vhd {SYNTHESIS SIMULATION}
add_file z48cc_glue.vhd {SYNTHESIS SIMULATION}
add_file z48cc_restart.vhd {SYNTHESIS SIMULATION}
# | 
# +-----------------------------------

# +-----------------------------------
# | parameters
# | 

# groups
set INTERFACES "Interfaces"
set ALU        "ALU"
set PIPELINE   "Pipeline"
set FETCH      "Fetch"
set DECODE     "Decode/Group"
set MMU        "MMU"
set ICACHE     "Instruction Cache"
set DCACHE     "Data Cache"
set L2         "Level-2 Cache"
set BUS        "Cache Bus"

proc_add_parameter INTERFACES HAVE_DEBUG "Debugger" "Enable debugger Avalon-MM interface" BOOLEAN "false"
proc_add_parameter INTERFACES HAVE_PERF "Performance counters" "Enable performance counter Avalon-MM interface" BOOLEAN "false"
proc_add_parameter INTERFACES HAVE_TRACE "Trace buffer" "Enable instruction trace buffer Avalon-MM interface" BOOLEAN "false"
proc_add_parameter INTERFACES TRACE_LENGTH "Trace buffer length" "Trace buffer length (#commits)" INTEGER "64" "4:65536"
proc_add_parameter INTERFACES HAVE_MCHECK "Machine check exceptions" "Adds extra error-checking/verification hardware" BOOLEAN "false"
proc_add_parameter INTERFACES HAVE_MBOX "SMP Mailbox/IPI IRQ controller" "Adds InterProcessor Interrupt support" BOOLEAN "false"
proc_add_parameter INTERFACES DEBUG_AUTOBOOT "Auto-boot when debugger present" "Automatically boots from system ROM on reset, instead of staying halted" BOOLEAN "false"

proc_add_parameter ALU HAVE_MULTIPLY "Multiplier" "Enables HW multiply support" BOOLEAN "true"
proc_add_parameter ALU MULTIPLY_TYPE "Multiplier type" "(COMB)" STRING "COMB"
proc_add_parameter ALU COMB_MULTIPLY_CYCLES "Multiply cycles" "Combinational latency of multiplier unit" INTEGER "5" "1:64"
proc_add_parameter ALU HAVE_DIVIDE "Divider" "Enables HW divider support" BOOLEAN "true"
proc_add_parameter ALU DIVIDE_TYPE "Divider type" "(COMB|SEQ)" STRING "COMB"
proc_add_parameter ALU COMB_DIVIDE_CYCLES "Combinational divider cycles" "Latency of divider unit" INTEGER "15" "1:64"
proc_add_parameter ALU SHIFT_TYPE "Shifter type" "Select barrel shifter implementation (BSHIFT|DSPSHIFT)" STRING "BSHIFT"

proc_add_parameter PIPELINE ALLOW_CASCADE "Operand cascading" "Allows DEPENDENT instructions to issue on same cycle" BOOLEAN "true"

proc_add_parameter PIPELINE FORWARD_DCACHE_EARLY "Dcache early forwarding" "Improves load-to-use penalty by 1 cycle" BOOLEAN "true"
proc_add_parameter PIPELINE FAST_MISPREDICT "Fast branch mispredicts" "Triggers mispredicts in EX stage instead of M1; trades IPC vs clock speed" BOOLEAN "false"
proc_add_parameter PIPELINE FAST_PREDICTOR_FEEDBACK "Fast branch predictor feedback" "Connects BHT to EX stage instead of M1" BOOLEAN "false"
proc_add_parameter PIPELINE FAST_REG_WRITE "Fast register write" "Merges last Dcache stage with register-write stage; reduces area at possible expense of clock speed" BOOLEAN "false"

proc_add_parameter FETCH IQUEUE_LENGTH "Iqueue length" "Longer queues give more aggressive prefetching at the expense of Icache churn" INTEGER "8" "8:256"
proc_add_parameter FETCH FETCH_ABORT_MISS "Fetch abort misses" "Allows fetch unit to abort in-progress miss transaction when target is known to be wrong" BOOLEAN "true"
proc_add_parameter FETCH FETCH_MISS_DELAYED "Fetch miss delayed" "Adds register from Iqueue miss logic to frontend; trades clock speed vs. Iqueue miss/branch/exception latency" BOOLEAN "false"

proc_add_parameter FETCH FETCH_BRANCH_PREDICTOR "Fetch branch predictor" "Allows frontend to prefetch target of branches" BOOLEAN "true"
proc_add_parameter FETCH FETCH_STATIC_PREDICTOR "Fetch static branch predictor" "Frontend predicts branch direction based on static heuristics" BOOLEAN "true"
proc_add_parameter FETCH FETCH_DYNAMIC_PREDICTOR "Fetch dynamic branch predictor" "Frontend predicts branch direction based on history" BOOLEAN "false"
proc_add_parameter FETCH FETCH_HAVE_BTB "Fetch branch target buffer" "Frontend predicts computed branch targets (function pointers)" BOOLEAN "false"
proc_add_parameter FETCH FETCH_RETURN_ADDR_PREDICTOR "Fetch return address stack/predictor" "Frontend prediction for function returns" BOOLEAN "false"
proc_add_parameter FETCH FETCH_UNALIGNED_DELAY_SLOT "Fetch unaligned delay slot decoder" "Frontend can predict target of branch+delayslot that crosses an Icache word boundary" BOOLEAN "false"
proc_add_parameter FETCH FETCH_BRANCH_NOHINT "Fetch ignores hints" "Ignores branch-likely hint instructions" BOOLEAN "false"

proc_add_parameter DECODE BRANCH_PREDICTOR "Branch predictor" "Predicts branch direction and target" BOOLEAN "true"
proc_add_parameter DECODE BRANCH_NOHINT "Branch predictor ignores hints" "Ignores branch-likely hint instructions" BOOLEAN "true"
proc_add_parameter DECODE STATIC_BRANCH_PREDICTOR "Static branch predictor" "Predict branch direction based on static heuristics" BOOLEAN "false"
proc_add_parameter DECODE DYNAMIC_BRANCH_PREDICTOR "Dynamic branch predictor" "Predict branch direction based on history" BOOLEAN "true"
proc_add_parameter DECODE DYNAMIC_BRANCH_SIZE "BHT size" "Size of Branch History Table" INTEGER "2048" "2:65536"
proc_add_parameter DECODE CLEVER_FLUSH "Branch flush micro-optimization" "Avoids pipeline flushes if taken/not-taken branch target are same address" BOOLEAN "true"
proc_add_parameter DECODE HAVE_RASTACK "Return address stack/predictor" "Improves prediction of function returns" BOOLEAN "true"
proc_add_parameter DECODE RASTACK_ENTRIES "Return address stack size" "Size of RAS predictor ring" INTEGER "8" "1:64"
proc_add_parameter DECODE HAVE_BTB "Branch target buffer" "Predicts computed branch targets (function pointers)" BOOLEAN "true"
proc_add_parameter DECODE BTB_TAGGED "Branch target buffer tagged" "Avoids making prediction based on wrong instruction" BOOLEAN "true"
proc_add_parameter DECODE BTB_VALID_BIT "Branch target buffer valid-bit" "Avoids making prediction for garbage entries" BOOLEAN "true"
proc_add_parameter DECODE BTB_SIZE "Branch target buffer size" "Size of BTB" INTEGER "128" "2:4096"

proc_add_parameter MMU JTLB_SIZE "JTLB size" "Number of software-visible MMU entries" INTEGER "16" "4:1024"
proc_add_parameter MMU JTLB_CAM_LATENCY "JTLB CAM latency" "Combinational latency of CAM" INTEGER "1" "1:16"
proc_add_parameter MMU JTLB_PRECISE_FLUSH "JTLB precise flushing" "Avoids flushing unrelated L1 TLB entries on JTLB write" BOOLEAN "true"
proc_add_parameter MMU NO_LARGE_PAGES "Support only 4K pages" "Simplifies JTLB hardware if OS will only use 4K pages" BOOLEAN "false"

proc_add_parameter ICACHE ITLB_OFFSET_BITS "ITLB offset bits" "log2c(#sets)" INTEGER "6" "1:16"
proc_add_parameter ICACHE ITLB_WAYS "ITLB ways" "ITLB associativity" INTEGER "1" "1:16"
proc_add_parameter ICACHE ITLB_REPLACE_TYPE "ITLB replacement algorithm" "(RANDOM|LRU|PLRU|RANDOMHYBRID)" STRING "LRU"
proc_add_parameter ICACHE ITLB_SUB_REPLACE_TYPE "ITLB hybrid sub-replacement algorithm" "(RANDOM|LRU|PLRU)" STRING "LRU"
proc_add_parameter ICACHE ITLB_HYBRID_BLOCK_FACTOR "ITLB hybrid blocking-factor" "#ways selected randomly" INTEGER "2" "2:8"
proc_add_parameter ICACHE ICACHE_BLOCK_BITS "Icache block-index bits" "log2c(#words)" INTEGER "3" "1:16"
proc_add_parameter ICACHE ICACHE_OFFSET_BITS "Icache offset bits" "log2c(#sets)" INTEGER "6" "1:16"
proc_add_parameter ICACHE ICACHE_WAYS "Icache ways" "Icache associativity" INTEGER "1" "1:16"
proc_add_parameter ICACHE ICACHE_REPLACE_TYPE "Icache replacement algorithm" "(RANDOM|LRU|PLRU|RANDOMHYBRID)" STRING "LRU"
proc_add_parameter ICACHE ICACHE_SUB_REPLACE_TYPE "Icache hybrid sub-replacement algorithm" "(RANDOM|LRU|PLRU)" STRING "LRU"
proc_add_parameter ICACHE ICACHE_HYBRID_BLOCK_FACTOR "Icache hybrid blocking-factor" "#ways selected randomly" INTEGER "2" "2:8"
proc_add_parameter ICACHE ICACHE_EARLY_RESTART "Icache early-restart" "Reduces apparent miss latency" BOOLEAN "false"
proc_add_parameter ICACHE CACHE_HINT_ICACHE_SHARE "Icache share hint" "Places lines in Icache in SHARED state instead of autopromoting to EXCLUSIVE" BOOLEAN "true"

proc_add_parameter DCACHE DTLB_OFFSET_BITS "DTLB offset bits" "log2c(#sets)" INTEGER "6" "1:16"
proc_add_parameter DCACHE DTLB_WAYS "DTLB ways" "DTLB associativity" INTEGER "1" "1:16"
proc_add_parameter DCACHE DTLB_REPLACE_TYPE "DTLB replacement algorithm" "(RANDOM|LRU|PLRU|RANDOMHYBRID)" STRING "LRU"
proc_add_parameter DCACHE DTLB_SUB_REPLACE_TYPE "DTLB hybrid sub-replacement algorithm" "(RANDOM|LRU|PLRU)" STRING "LRU"
proc_add_parameter DCACHE DTLB_HYBRID_BLOCK_FACTOR "DTLB hybrid blocking-factor" "#ways selected randomly" INTEGER "2" "2:8"
proc_add_parameter DCACHE DCACHE_BLOCK_BITS "Dcache block-index bits" "log2c(#words)" INTEGER "4" "1:16"
proc_add_parameter DCACHE DCACHE_OFFSET_BITS "Dcache offset bits" "log2c(#sets)" INTEGER "6" "1:16"
proc_add_parameter DCACHE DCACHE_WAYS "Dcache ways" "Dcache associativity" INTEGER "1" "1:16"
proc_add_parameter DCACHE DCACHE_REPLACE_TYPE "Dcache replacement algorithm" "(RANDOM|LRU|PLRU|RANDOMHYBRID)" STRING "LRU"
proc_add_parameter DCACHE DCACHE_SUB_REPLACE_TYPE "Dcache hybrid sub-replacement algorithm" "(RANDOM|LRU|PLRU)" STRING "LRU"
proc_add_parameter DCACHE DCACHE_HYBRID_BLOCK_FACTOR "Dcache hybrid blocking-factor" "#ways selected randomly" INTEGER "2" "2:8"
proc_add_parameter DCACHE DCACHE_EARLY_RESTART "Dcache early-restart" "Reduces apparent miss latency" BOOLEAN "false"
proc_add_parameter DCACHE DCACHE_LATENCY "Dcache latency" "Trades load-to-use latency vs store-to-load turnaround stalls" INTEGER "1" "1:2"

proc_add_parameter L2 L2_OFFSET_BITS "L2 offset bits" "log2(#sets)" INTEGER "0" "0:32"
proc_add_parameter L2 L2_WAYS "L2 ways" "#ways" INTEGER "0" "0:1024"
proc_add_parameter L2 L2_REPLACE_TYPE "L2 replacement policy" "(RANDOM|LRU|PLRU|RANDOMHYBRID)" STRING "PLRU"
proc_add_parameter L2 L2_SUB_REPLACE_TYPE "L2 sub replacement policy" "(RANDOM|LRU|PLRU)" STRING "LRU"
proc_add_parameter L2 L2_HYBRID_BLOCK_FACTOR "L2 hybrid replacement blocking-factor" "Controls Random-Hybrid blocking" INTEGER "2" "2:1024"

proc_add_parameter BUS CACHE_CLOCK_DOUBLING "Cache 2x clock" "Double transfer rate of internal cache busses" BOOLEAN "false"
proc_add_parameter BUS L2_ENABLE_SNOOPING "Level-2 Cache Snooping" "SMP cache-coherence support" BOOLEAN "false"
proc_add_parameter BUS CACHE_WIDTH "Cache interface width" "#bits" INTEGER "64" "32:65536"
proc_add_parameter BUS CACHE_BLOCK_BITS "Cache block bits" "log2(burst-length)" INTEGER "3" "1:16"
proc_add_parameter BUS CACHE_CRITICAL_WORD_FIRST "Cache critical-word-first" "Improves miss latency" BOOLEAN "true"
proc_add_parameter BUS BUS_CDC "Cache interface CDC" "Run cache interface in seperate clock-domain" BOOLEAN "false"
proc_add_parameter BUS BUS_SMFIFO_DEPTH "Bus S->M FIFO depth" "Slave-to-master FIFO depth" INTEGER "8" "4:1024"
proc_add_parameter BUS BUS_MSFIFO_DEPTH "Bus M->S FIFO depth" "Master-to-slave FIFO depth" INTEGER "32" "4:4096"
proc_add_parameter BUS BUS_CLOCKS_SYNCHED "Bus clock synched with core" "Reduces clock-crossing latency if metastability protection is not needed" BOOLEAN "false"
proc_add_parameter BUS BUS_SYNCH_STAGES "Bus CDC synch stages" "Provides metastability protection" INTEGER "2" "2:5"
# | 
# +-----------------------------------

# +-----------------------------------
# | display items
# | 
# | 
# +-----------------------------------

# +-----------------------------------
# | connection point coreclk
# | 
add_interface coreclk clock end

set_interface_property coreclk ENABLED true

add_interface_port coreclk reset reset Input 1
add_interface_port coreclk coreclk clk Input 1
# | 
# +-----------------------------------

# +-----------------------------------
# | connection point dcoreclk
# | 
add_interface dcoreclk clock end

set_interface_property dcoreclk ENABLED false

add_interface_port dcoreclk dcoreclk clk Input 1
# | 
# +-----------------------------------

# +-----------------------------------
# | connection point iumaster
# | 
add_interface iumaster avalon start
set_interface_property iumaster associatedClock coreclk
set_interface_property iumaster burstOnBurstBoundariesOnly false
set_interface_property iumaster doStreamReads false
set_interface_property iumaster doStreamWrites false
set_interface_property iumaster linewrapBursts false

set_interface_property iumaster ASSOCIATED_CLOCK coreclk
set_interface_property iumaster ENABLED true

add_interface_port iumaster iu_mem_in readdata Input 64
add_interface_port iumaster iu_mem_addr address Output 32
add_interface_port iumaster iu_mem_rd read Output 1
add_interface_port iumaster iu_mem_halt waitrequest Input 1
add_interface_port iumaster iu_mem_valid readdatavalid Input 1
# | 
# +-----------------------------------

# +-----------------------------------
# | connection point dumaster
# | 
add_interface dumaster avalon start
set_interface_property dumaster associatedClock coreclk
set_interface_property dumaster burstOnBurstBoundariesOnly false
set_interface_property dumaster doStreamReads false
set_interface_property dumaster doStreamWrites false
set_interface_property dumaster linewrapBursts false

set_interface_property dumaster ASSOCIATED_CLOCK coreclk
set_interface_property dumaster ENABLED true

add_interface_port dumaster u_mem_in readdata Input 32
add_interface_port dumaster u_mem_out writedata Output 32
add_interface_port dumaster u_mem_addr address Output 32
add_interface_port dumaster u_mem_rd read Output 1
add_interface_port dumaster u_mem_wr write Output 1
add_interface_port dumaster u_mem_halt waitrequest Input 1
add_interface_port dumaster u_mem_valid readdatavalid Input 1
add_interface_port dumaster u_mem_be byteenable Output 4
# | 
# +-----------------------------------

# +-----------------------------------
# | connection point mclk
# | 
add_interface mclk clock end

set_interface_property mclk ENABLED false

add_interface_port mclk m_rst reset Input 1
add_interface_port mclk m_clk clk Input 1
# | 
# +-----------------------------------

# +-----------------------------------
# | connection point mmaster
# | 
add_interface mmaster avalon start
set_interface_property mmaster associatedClock coreclk
set_interface_property mmaster burstOnBurstBoundariesOnly false
set_interface_property mmaster doStreamReads false
set_interface_property mmaster doStreamWrites false
set_interface_property mmaster linewrapBursts true
set_interface_property mmaster alwaysBurstMaxBurst true

set_interface_property mmaster ASSOCIATED_CLOCK coreclk
set_interface_property mmaster ENABLED true

add_interface_port mmaster m_addr address Output 32
add_interface_port mmaster m_out writedata Output CACHE_WIDTH
add_interface_port mmaster m_burstcount burstcount Output CACHE_BLOCK_BITS+1
add_interface_port mmaster m_rd read Output 1
add_interface_port mmaster m_wr write Output 1
add_interface_port mmaster m_halt waitrequest Input 1
add_interface_port mmaster m_valid readdatavalid Input 1
add_interface_port mmaster m_in readdata Input CACHE_WIDTH
# | 
# +-----------------------------------

# +-----------------------------------
# | connection point debug_slave
# | 
add_interface debug_slave avalon end
set_interface_property debug_slave addressAlignment DYNAMIC
set_interface_property debug_slave associatedClock coreclk
set_interface_property debug_slave burstOnBurstBoundariesOnly false
set_interface_property debug_slave explicitAddressSpan 0
set_interface_property debug_slave holdTime 0
set_interface_property debug_slave isMemoryDevice false
set_interface_property debug_slave isNonVolatileStorage false
set_interface_property debug_slave linewrapBursts false
set_interface_property debug_slave maximumPendingReadTransactions 0
set_interface_property debug_slave printableDevice false
set_interface_property debug_slave readLatency 1
set_interface_property debug_slave readWaitStates 0
set_interface_property debug_slave readWaitTime 0
set_interface_property debug_slave setupTime 0
set_interface_property debug_slave timingUnits Cycles
set_interface_property debug_slave writeWaitTime 0

set_interface_property debug_slave ASSOCIATED_CLOCK coreclk
set_interface_property debug_slave ENABLED true

add_interface_port debug_slave debug_mem_addr address Input 6
add_interface_port debug_slave debug_mem_in writedata Input 32
add_interface_port debug_slave debug_mem_out readdata Output 32
add_interface_port debug_slave debug_mem_be byteenable Input 4
add_interface_port debug_slave debug_mem_rd read Input 1
add_interface_port debug_slave debug_mem_wr write Input 1
add_interface_port debug_slave debug_mem_halt waitrequest Output 1
# | 
# +-----------------------------------

# +-----------------------------------
# | connection point trace_slave
# | 
add_interface trace_slave avalon end
set_interface_property trace_slave addressAlignment DYNAMIC
set_interface_property trace_slave associatedClock coreclk
set_interface_property trace_slave burstOnBurstBoundariesOnly false
set_interface_property trace_slave explicitAddressSpan 0
set_interface_property trace_slave holdTime 0
set_interface_property trace_slave isMemoryDevice false
set_interface_property trace_slave isNonVolatileStorage false
set_interface_property trace_slave linewrapBursts false
set_interface_property trace_slave maximumPendingReadTransactions 0
set_interface_property trace_slave printableDevice false
set_interface_property trace_slave readLatency 1
set_interface_property trace_slave readWaitStates 0
set_interface_property trace_slave readWaitTime 0
set_interface_property trace_slave setupTime 0
set_interface_property trace_slave timingUnits Cycles
set_interface_property trace_slave writeWaitTime 0

set_interface_property trace_slave ASSOCIATED_CLOCK coreclk
set_interface_property trace_slave ENABLED true

add_interface_port trace_slave trace_mem_addr address Input 16
add_interface_port trace_slave trace_mem_in writedata Input 32
add_interface_port trace_slave trace_mem_out readdata Output 32
add_interface_port trace_slave trace_mem_be byteenable Input 4
add_interface_port trace_slave trace_mem_rd read Input 1
add_interface_port trace_slave trace_mem_wr write Input 1
add_interface_port trace_slave trace_mem_halt waitrequest Output 1
# | 
# +-----------------------------------

# +-----------------------------------
# | connection point external
# | 
add_interface external conduit end

set_interface_property external ENABLED true

add_interface_port external blinkenlights export Output 8
add_interface_port external blinkenlights2 export Output 8
add_interface_port external triggermask export Input 18
add_interface_port external signaltap_trigger export Output 1
add_interface_port external blinkentriggers export Output 18
add_interface_port external mce_code export Output 9
# | 
# +-----------------------------------

# +-----------------------------------
# | connection point irqs
# | 
add_interface eirqs conduit end

set_interface_property eirqs ENABLED true

add_interface_port eirqs eirqs export Input 2
# | 
# +-----------------------------------

# +-----------------------------------
# | connection point snoop
# | 
add_interface snoop conduit end

set_interface_property snoop ENABLED false

add_interface_port snoop s_bus_reqn export Output 1
add_interface_port snoop s_bus_gntn export Input 1
add_interface_port snoop s_bus_r_addr_oe export Output 1
add_interface_port snoop s_bus_r_addr_out export Output 32
add_interface_port snoop s_bus_r_addr export Input 32
add_interface_port snoop s_bus_r_sharen_oe export Output 1
add_interface_port snoop s_bus_r_sharen export Input 1
add_interface_port snoop s_bus_r_excln_oe export Output 1
add_interface_port snoop s_bus_r_excln export Input 1
add_interface_port snoop s_bus_a_waitn_oe export Output 1
add_interface_port snoop s_bus_a_waitn export Input 1
add_interface_port snoop s_bus_a_ackn_oe export Output 1
add_interface_port snoop s_bus_a_ackn export Input 1
add_interface_port snoop s_bus_a_sharen_oe export Output 1
add_interface_port snoop s_bus_a_sharen export Input 1
add_interface_port snoop s_bus_a_excln_oe export Output 1
add_interface_port snoop s_bus_a_excln export Input 1
# | 
# +-----------------------------------

# +-----------------------------------
# | connection point mbox_slave
# | 
add_interface mbox_slave avalon end
set_interface_property mbox_slave addressAlignment NATIVE 
set_interface_property mbox_slave associatedClock coreclk
set_interface_property mbox_slave burstOnBurstBoundariesOnly false
set_interface_property mbox_slave explicitAddressSpan 0
set_interface_property mbox_slave holdTime 0
set_interface_property mbox_slave isMemoryDevice false
set_interface_property mbox_slave isNonVolatileStorage false
set_interface_property mbox_slave linewrapBursts false
set_interface_property mbox_slave maximumPendingReadTransactions 0
set_interface_property mbox_slave printableDevice false
set_interface_property mbox_slave readLatency 1
set_interface_property mbox_slave readWaitStates 0
set_interface_property mbox_slave readWaitTime 0
set_interface_property mbox_slave setupTime 0
set_interface_property mbox_slave timingUnits Cycles
set_interface_property mbox_slave writeWaitTime 0

set_interface_property mbox_slave ASSOCIATED_CLOCK coreclk
set_interface_property mbox_slave ENABLED true

add_interface_port mbox_slave mbox_addr address Input 1
add_interface_port mbox_slave mbox_out readdata Output 32
add_interface_port mbox_slave mbox_in writedata Input 32
add_interface_port mbox_slave mbox_rd read Input 1
add_interface_port mbox_slave mbox_wr write Input 1
# | 
# +-----------------------------------

# +-----------------------------------
# | connection point perf_slave
# | 
add_interface perf_slave avalon end
set_interface_property perf_slave addressAlignment DYNAMIC
set_interface_property perf_slave associatedClock coreclk
set_interface_property perf_slave burstOnBurstBoundariesOnly false
set_interface_property perf_slave explicitAddressSpan 0
set_interface_property perf_slave holdTime 0
set_interface_property perf_slave isMemoryDevice false
set_interface_property perf_slave isNonVolatileStorage false
set_interface_property perf_slave linewrapBursts false
set_interface_property perf_slave maximumPendingReadTransactions 0
set_interface_property perf_slave printableDevice false
set_interface_property perf_slave readLatency 1
set_interface_property perf_slave readWaitStates 0
set_interface_property perf_slave readWaitTime 0
set_interface_property perf_slave setupTime 0
set_interface_property perf_slave timingUnits Cycles
set_interface_property perf_slave writeWaitTime 0

set_interface_property perf_slave ASSOCIATED_CLOCK coreclk
set_interface_property perf_slave ENABLED true

add_interface_port perf_slave perf_in writedata Input 32
add_interface_port perf_slave perf_out readdata Output 32
add_interface_port perf_slave perf_be byteenable Input 4
add_interface_port perf_slave perf_rd read Input 1
add_interface_port perf_slave perf_wr write Input 1
add_interface_port perf_slave perf_addr address Input 7
# | 
# +-----------------------------------

# magic to dynamically configure interfaces
proc elaborate {} {
   if { "[ get_parameter HAVE_DEBUG ]" == "false" } {
      set_interface_property debug_slave ENABLED false
   }
   if { "[ get_parameter HAVE_PERF ]" == "false" } {
      set_interface_property perf_slave ENABLED false
   }
   if { "[ get_parameter HAVE_TRACE ]" == "false" } {
      set_interface_property trace_slave ENABLED false
   }
   if { "[ get_parameter L2_ENABLE_SNOOPING ]" == "true" } {
      set_interface_property snoop ENABLED true
   }
   if { "[ get_parameter HAVE_MBOX ]" == "false" } {
      set_interface_property mbox_slave ENABLED false
   }
   if { "[ get_parameter CACHE_CRITICAL_WORD_FIRST ]" == "false" } {
      set_interface_property mmaster burstOnBurstBoundariesOnly true
      set_interface_property mmaster linewrapBursts false
   }
   if { "[ get_parameter BUS_CDC ]" == "true" } {
      set_interface_property mclk ENABLED true
      set_interface_property mmaster associatedClock mclk
      set_interface_property mmaster ASSOCIATED_CLOCK mclk
   }
   if { "[ get_parameter CACHE_CLOCK_DOUBLING ]" == "true" } {
      set_interface_property dcoreclk ENABLED true
   }
}

set_module_property ELABORATION_CALLBACK elaborate
