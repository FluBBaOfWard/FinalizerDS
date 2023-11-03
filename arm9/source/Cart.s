#ifdef __arm__

#include "Shared/EmuSettings.h"
#include "ARM6809/ARM6809mac.h"
#include "K005849/K005849.i"

	.global machineInit
	.global loadCart
	.global m6809Mapper
	.global emuFlags
	.global romNum
//	.global scaling
	.global cartFlags
	.global romStart
	.global vromBase0
	.global vromBase1
	.global promBase

	.global ROM_Space



	.syntax unified
	.arm

	.section .rodata
	.align 2

rawRom:
/*
	.incbin "finalizr/523k01.9c"
	.incbin "finalizr/523k02.12c"
	.incbin "finalizr/523k03.13c"
	.incbin "finalizr/d8749hd.bin"
	.incbin "finalizr/523h04.5e"
	.incbin "finalizr/523h05.6e"
	.incbin "finalizr/523h06.7e"
	.incbin "finalizr/523h07.5f"
	.incbin "finalizr/523h08.6f"
	.incbin "finalizr/523h09.7f"
	.incbin "finalizr/523h10.2f"
	.incbin "finalizr/523h11.3f"
	.incbin "finalizr/523h13.11f"
	.incbin "finalizr/523h12.10f"
*/
/*
	.incbin "finalizr/finalizr.5"
	.incbin "finalizr/finalizr.6"
//	.incbin "finalizr/d8749hd.bin"
	.incbin "finalizr/523k04.5e"
	.incbin "finalizr/523k05.6e"
	.incbin "finalizr/523k06.7e"
	.incbin "finalizr/523k07.5f"
	.incbin "finalizr/523k08.6f"
	.incbin "finalizr/523k09.7f"
	.incbin "finalizr/523h10.2f"
	.incbin "finalizr/523h11.3f"
	.incbin "finalizr/523h13.11f"
	.incbin "finalizr/523h12.10f"
*/
/*
	.incbin "jailbrek/507p03.11d"
	.incbin "jailbrek/507p02.9d"

	.incbin "jailbrek/507j04.3e"
	.incbin "jailbrek/507j05.4e"
	.incbin "jailbrek/507j06.5e"
	.incbin "jailbrek/507j07.3f"
	.incbin "jailbrek/507l08.4f"
	.incbin "jailbrek/507j09.5f"

	.incbin "jailbrek/507j10.1f"
	.incbin "jailbrek/507j11.2f"
	.incbin "jailbrek/507j13.7f"
	.incbin "jailbrek/507j12.6f"
	.incbin "jailbrek/507l01.8c"
*/
	.align 2
;@----------------------------------------------------------------------------
machineInit: 	;@ Called from C
	.type   machineInit STT_FUNC
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	bl gfxInit
//	bl ioInit
//	bl soundInit
	bl cpuInit

	ldmfd sp!,{lr}
	bx lr

	.section .ewram,"ax"
	.align 2
;@----------------------------------------------------------------------------
loadCart: 		;@ Called from C:  r0=rom number, r1=emuflags
	.type   loadCart STT_FUNC
;@----------------------------------------------------------------------------
	stmfd sp!,{r4-r11,lr}
	str r0,romNum
	str r1,emuFlags

//	ldr r7,=rawRom
	ldr r7,=ROM_Space
								;@ r7=rombase til end of loadcart so DON'T FUCK IT UP
	str r7,romStart				;@ Set rom base
	add r0,r7,#0xC000			;@ 0xC000
	str r0,cpu2Start			;@ Sound cpu
	add r0,r0,#0x800
	str r0,vromBase0			;@ Bg
	str r0,vromBase1			;@ Spr
	add r0,r0,#0x18000
	str r0,promBase				;@ Colour prom

	ldr r4,=MEMMAPTBL_
	ldr r5,=RDMEMTBL_
	ldr r6,=WRMEMTBL_
	adr r8,pageMappings

	ldr r2,=mem6809R0
	ldr r3,=rom_W
	mov r0,#0
tbLoop1:
	add r1,r7,r0,lsl#13
	bl initMappingPage
	add r0,r0,#1
	cmp r0,#0x88
	bne tbLoop1

	ldr r2,=empty_R
	ldr r3,=empty_W
tbLoop2:
	bl initMappingPage
	add r0,r0,#1
	cmp r0,#0x100
	bne tbLoop2

	ldmfd r8!,{r0-r3}
memL3:
	bl initMappingPage
	add r0,r0,#1				;@ 0xF8-0xFB RAM
	cmp r0,#0xFB
	bne memL3

	mov r9,#6
tbLoop4:
	ldmfd r8!,{r0-r3}
	bl initMappingPage
	subs r9,r9,#1
	bne tbLoop4

	bl gfxReset
	bl ioReset
	bl soundReset
	bl cpuReset

	ldmfd sp!,{r4-r11,lr}
	bx lr

;@----------------------------------------------------------------------------
pageMappings:
	.long 0xF8, emuRAM, k005885Ram_0R, k005885Ram_0W	;@ RAM
	.long 0xF9, emptySpace, empty_R, empty_W			;@ empty
	.long 0xFB, emptySpace, VLM_R, empty_W				;@ empty
	.long 0xFC, emuRAM, k005849Ram_0R, k005849Ram_0W	;@ Graphic
	.long 0xFD, emptySpace, k005849_0R, k005849_0W		;@ IO
	.long 0xFE, emuRAM, k005885Ram_0R, k005885Ram_0W	;@ Graphic
	.long 0xFF, emptySpace, IO_R, IO_W					;@ IO
;@----------------------------------------------------------------------------
initMappingPage:	;@ r0=page, r1=mem, r2=rdMem, r3=wrMem
;@----------------------------------------------------------------------------
	str r1,[r4,r0,lsl#2]
	str r2,[r5,r0,lsl#2]
	str r3,[r6,r0,lsl#2]
	bx lr

;@----------------------------------------------------------------------------
//	.section itcm
;@----------------------------------------------------------------------------

;@----------------------------------------------------------------------------
m6809Mapper:		;@ Rom paging..
;@----------------------------------------------------------------------------
	ands r0,r0,#0xFF			;@ Safety
	bxeq lr
	stmfd sp!,{r3-r8,lr}
	ldr r5,=MEMMAPTBL_
	ldr r2,[r5,r1,lsl#2]!
	ldr r3,[r5,#-1024]			;@ RDMEMTBL_
	ldr r4,[r5,#-2048]			;@ WRMEMTBL_

	mov r5,#0
	cmp r1,#0xF8
	movmi r5,#12

	add r6,m6809ptr,#m6809ReadTbl
	add r7,m6809ptr,#m6809WriteTbl
	add r8,m6809ptr,#m6809MemTbl
	b m6809Memaps
m6809Memapl:
	add r6,r6,#4
	add r7,r7,#4
	add r8,r8,#4
m6809Memap2:
	add r3,r3,r5
	sub r2,r2,#0x2000
m6809Memaps:
	movs r0,r0,lsr#1
	bcc m6809Memapl				;@ C=0
	strcs r3,[r6],#4			;@ readmem_tbl
	strcs r4,[r7],#4			;@ writemem_tb
	strcs r2,[r8],#4			;@ memmap_tbl
	bne m6809Memap2

;@------------------------------------------
m6809Flush:		;@ Update cpu_pc & lastbank
;@------------------------------------------
	reEncodePC

	ldmfd sp!,{r3-r8,lr}
	bx lr

;@----------------------------------------------------------------------------

romNum:
	.long 0						;@ romnumber
romInfo:						;@ Keep emuflags/BGmirror together for savestate/loadstate
emuFlags:
	.byte 0						;@ emuflags      (label this so Gui.c can take a peek) see EmuSettings.h for bitfields
//scaling:
	.byte SCALED				;@ (display type)
	.byte 0,0					;@ (sprite follow val)
cartFlags:
	.byte 0 					;@ cartflags
	.space 3

romStart:
	.long 0
cpu2Start:
	.long 0
vromBase0:
	.long 0
vromBase1:
	.long 0
promBase:
	.long 0

	.section .bss
WRMEMTBL_:
	.space 256*4
RDMEMTBL_:
	.space 256*4
MEMMAPTBL_:
	.space 256*4
ROM_Space:
	.space 0x24A40
emptySpace:
	.space 0x2000
;@----------------------------------------------------------------------------
	.end
#endif // #ifdef __arm__
