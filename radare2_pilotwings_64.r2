e asm.arch=mips
e asm.bits=64
e cfg.bigendian=true

e io.va=true
e asm.emu=true

# define IO maps for kernel and app .text and .data sections
# om fd vaddr [size] [paddr] [rwx] [name]
om 3 0x80200050 0x50e30 0x001000 mrx kernel
om 3 0x802ca900 0x8c8f0 0x051e30 mrx app

# functions
af entry 0x80200050
af thread_3 0x80203dd0
af memset 0x8022aa80
af thread_4 0x8022b8c4
af debug_print_section_sizes 0x8022e0e0
af main 0x8022e440
af thread_0 0x8022e874
af thread_6 0x8022e920
af thread_1 0x8022e980
af debug_printf 0x8022ed14
af mio0_decompress 0x80231a20
af osSendMesg 0x80236190
af alBnkfNew 0x80236444
af alSetFileNew 0x80236548
af osAiSetFrequency 0x80236590
af linked_list_remove 0x802366f0
af linked_list_insert 0x80236720
af osCreateMesgQueue 0x802367b0
af osCreateThread 0x802367e0
af osStartThread 0x80236930
af osRecvMesg 0x80236a80
af osVirtualToPhysical 0x80236bc0
af osAiSetNextBuffer 0x80236c40
af osPiStartDma 0x802373d0
af osGetCount 0x80238140
af sqrtf 0x8023a820
af osViBlack 0x8023a830
af osWriteBackDCache 0x8023a8a0
af osViSetSpecialFeatures 0x8023a920
af __ull_rshift 0x8023aae0
af __ull_rem 0x8023ab0c
af __ull_div 0x8023ab48
af __ll_lshift 0x8023ab84
af __ll_rem 0x8023abb0
af __ll_div 0x8023abec
af __ll_mul 0x8023ac48
af __ull_divremi 0x8023ac78
af __ll_mod 0x8023acd8
af __ll_rshift 0x8023ad74
af osViSwapBuffer 0x8023ae20
af osWriteBackDCacheAll 0x8023ae70
af TaskVirtualToPhysical 0x8023aea0
af osSpTaskLoad 0x8023afbc
af osSpTaskStartGo 0x8023b11c
af osCreateViManager 0x8023b1e0
af __osViDevMgrMain 0x8023b364
af osViSetMode 0x8023b540
af osSetEventMsg 0x8023b5b0
af osViSetEventMsg 0x8023b620
af osSpTaskYield 0x8023b690
af osSpTaskYielded 0x8023b6b0
af osEepromLongRead 0x8023b730
af osEepromLongWrite 0x8023b870
af osEepromProbe 0x8023b9b0
af osInitialize 0x8023ba20
af osEPiRawReadIo 0x8023bc50
af osCreatePiManager 0x8023bcc0
af osSetThreadPri 0x8023be40
af osSetTimer 0x8023bf20
af osContInit 0x8023c000
af __osContGetInitData 0x8023c1fc
af __osPackRequestData 0x8023c2cc
af osContStartReadData 0x8023c3c0
af osContGetReadData 0x8023C484
af __osPackReadData 0x8023c52c
af osInvalDCache 0x8023c620
af osSetIntMask 0x8023d240
af __osDisableInt 0x8023ed20
af __osRestoreInt 0x8023ed40
af __osDequeueThread 0x8023ed60
af __osExceptionPreamble 0x8023eda0
af __osExceptionHandler 0x8023edb0
af send_mesg 0x8023f2f8
af __osEnqueueAndYield 0x8023f3e0
af __osEnqueueThread 0x8023f470
af __osPopThread 0x8023f4b8
af __osDispatchThread 0x8023f4c8
af __osCleanupThread 0x8023f608
af __osViInit 0x8023f610
af __osProbeTLB 0x8023f750
af __osAiDeviceBusy 0x8023f810
af osJamMesg 0x80241e30
af osPiGetCmdQueue 0x80241f80
af __osPiCreateAccessQueue 0x80241fe0
af __osPiGetAccess 0x80242030
af __osPiRelAccess 0x80242074
af bcopy 0x802420a0
af __osSpSetStatus 0x802423b0
af __osSpSetPc 0x802423c0
af __osSpRawStartDma 0x80242400
af __osSpDeviceBusy 0x80242490
af __osTimerServicesInit 0x802424c0
af __osTimerInterrupt 0x8024254c
af __osSetTimerIntr 0x802426c4
af __osInsertTimer 0x80242738
af osGetThreadPri 0x802428c0
af __osViSwapContext 0x802428f0
af __osSpGetStatus 0x80242c50
af osEepromRead 0x80242c60
af __osPackEepReadData 0x80242e10
af __osEepStatus 0x80242f1c
af osEepromWrite 0x80243140
af __osPackEepWriteData 0x80243330
af __osSiCreateAccessQueue 0x80243440
af __osSiGetAccess 0x80243490
af __osSiRelAccess 0x802434d4
af __osSetSR 0x80243500
af __osGetSR 0x80243510
af __osSetFpcCsr 0x80243520
af __osSiRawReadIo 0x80243530
af __osSiRawWriteIo 0x80243580
af osInvalCache 0x802435d0
af osMapTLBRdb 0x80243650
af bzero 0x802436b0
af osPiRawStartDma 0x80243750
af __osDevMgrMain 0x80243830
af osGetTime 0x802439b0
af __osSiRawStartDma 0x80243a40
af kdebugserver 0x80244438
af __osSyncPutChars 0x80244620
af osDestroyThread 0x80244750
af __osSetCompare 0x80245480
af __osSiDeviceBusy 0x80245490
af __osAtomicDec 0x802454d0
af decode_block 0x802ca900
af app_entry 0x8030fe20

# seek to main
s main
