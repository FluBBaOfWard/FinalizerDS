#ifdef __arm__

#include "Shared/nds_asm.h"
#include "Equates.h"
#include "ARM6809/ARM6809.i"
#include "K005849/K005849.i"

	.global gfxInit
	.global gfxReset
	.global paletteInit
	.global paletteTxAll
	.global refreshGfx
	.global endFrame
	.global gfxState
	.global g_flicker
	.global g_twitch
	.global g_scaling
	.global g_gfxMask
	.global vblIrqHandler
	.global yStart

	.global k005849_0
	.global k005849Ram_0R
	.global k005849_0R
	.global k005849Ram_0W
	.global k005849_0W
	.global k005885_0
	.global k005885Ram_0R
	.global k005885_0R
	.global k005885Ram_0W
	.global k005885_0W
	.global emuRAM


	.syntax unified
	.arm

	.section .text
	.align 2
;@----------------------------------------------------------------------------
gfxInit:					;@ Called from machineInit
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}

	ldr r0,=OAM_BUFFER1			;@ No stray sprites please
	mov r1,#0x200+SCREEN_HEIGHT
	mov r2,#0x100
	bl memset_
	adr r0,scaleParms
	bl setupSpriteScaling

	ldmfd sp!,{pc}

;@----------------------------------------------------------------------------
scaleParms:					;@  NH     FH     NV     FV
	.long OAM_BUFFER1,0x0000,0x0100,0xff01,0x0120,0xfee1
;@----------------------------------------------------------------------------
gfxReset:					;@ Called with CPU reset
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}

	ldr r0,=gfxState
	mov r1,#5					;@ 5*4
	bl memclr_					;@ Clear GFX regs

	mov r1,#REG_BASE
	ldr r0,=0x08F8				;@ start-end
	strh r0,[r1,#REG_WIN0H]
	mov r0,#0x00C0				;@ start-end
	strh r0,[r1,#REG_WIN0V]
	mov r0,#0x0000
	strh r0,[r1,#REG_WINOUT]

	ldr r0,=m6809SetNMIPin
	ldr r1,=m6809SetIRQPin
	ldr r2,=m6809SetFIRQPin
	ldr r3,=emuRAM
	bl k005885Reset0
	bl bgInit

	ldr r0,=g_gammaValue
	ldrb r0,[r0]
	bl paletteInit				;@ Do palette mapping
	bl paletteTxAll				;@ Transfer it

	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
bgInit:					;@ BG tiles
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	ldr r0,=BG_GFX+0x8000		;@ r0 = NDS BG tileset
	str r0,[koptr,#bgrGfxDest]
	ldr r0,=Gfx1Bg
	str r0,[koptr,#spriteRomBase]
	str r0,[koptr,#bgrRomBase]
	ldr r1,=vromBase0
	ldr r1,[r1]					;@ r1 = even bytes
	add r2,r1,#0xC000			;@ r2 = odd bytes
	mov r3,#0x18000				;@ Length
	bl convertTiles5885
	ldr r0,=BG_GFX+0x4000		;@ r0 = NDS BG tileset
	bl addBackgroundTiles

	ldmfd sp!,{lr}
	bx lr
;@----------------------------------------------------------------------------
bgInit_:					;@ BG tiles
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	ldr r0,=BG_GFX+0x8000		;@ r0 = NDS BG tileset
	str r0,[koptr,#bgrGfxDest]
	ldr r0,=Gfx1Bg
	str r0,[koptr,#spriteRomBase]
	str r0,[koptr,#bgrRomBase]
	ldr r1,=vromBase0
	ldr r1,[r1]					;@ r1 = even bytes
	mov r2,#0x18000				;@ Length
	bl convertTiles5849
	ldr r0,=BG_GFX+0x4000		;@ r0 = NDS BG tileset
	bl addBackgroundTiles

	ldmfd sp!,{lr}
	bx lr

;@----------------------------------------------------------------------------
paletteInit:		;@ r0-r3 modified.
	.type paletteInit STT_FUNC
;@ Called by ui.c:  void paletteInit(u8 gammaVal);
;@----------------------------------------------------------------------------
	stmfd sp!,{r4-r9,lr}
	mov r1,r0					;@ Gamma value = 0 -> 4
	ldr r8,=promBase			;@ Proms
	ldr r8,[r8]
	mov r7,#0xF0
	ldr r6,=MAPPED_RGB
	mov r4,#32					;@ Finalizer bgr, r1=R, r2=G, r3=B
noMap:							;@ Map 0000bbbbggggrrrr  ->  0bbbbbgggggrrrrr
	ldrb r0,[r8,#0x20]
	and r0,r7,r0,lsl#4			;@ Blue ready
	bl gPrefix
	mov r5,r0

	ldrb r9,[r8],#1
	and r0,r7,r9				;@ Green ready
	bl gPrefix
	orr r5,r0,r5,lsl#5

	and r0,r7,r9,lsl#4			;@ Red ready
	bl gPrefix
	orr r5,r0,r5,lsl#5

	strh r5,[r6],#2
	subs r4,r4,#1
	bne noMap

	ldmfd sp!,{r4-r9,lr}
	bx lr

;@----------------------------------------------------------------------------
gPrefix:
	orr r0,r0,r0,lsr#4
;@----------------------------------------------------------------------------
gammaConvert:	;@ Takes value in r0(0-0xFF), gamma in r1(0-4),returns new value in r0=0x1F
;@----------------------------------------------------------------------------
	rsb r2,r0,#0x100
	mul r3,r2,r2
	rsbs r2,r3,#0x10000
	rsb r3,r1,#4
	orr r0,r0,r0,lsl#8
	mul r2,r1,r2
	mla r0,r3,r0,r2
	mov r0,r0,lsr#13

	bx lr
;@----------------------------------------------------------------------------
paletteTxAll:				;@ Called from ui.c
	.type paletteTxAll STT_FUNC
;@----------------------------------------------------------------------------
	stmfd sp!,{r4-r5}

	ldr r2,=promBase			;@ Proms
	ldr r2,[r2]
	add r2,r2,#64
	ldr r3,=MAPPED_RGB+32
	ldr r4,=EMUPALBUFF
	add r5,r4,#512
	mov r1,#256
noMap2:
	ldrb r0,[r2],#1
	and r0,r0,#0xF
	mov r0,r0,lsl#1
	ldrh r0,[r3,r0]
	strh r0,[r4],#2
	subs r1,r1,#1
	bne noMap2

	sub r3,r3,#32
	mov r1,#256
noMap3:
	ldrb r0,[r2],#1
	and r0,r0,#0xF
	mov r0,r0,lsl#1
	ldrh r0,[r3,r0]
	strh r0,[r5],#2
	subs r1,r1,#1
	bne noMap3

	ldmfd sp!,{r4-r5}
	bx lr

;@----------------------------------------------------------------------------
vblIrqHandler:
	.type vblIrqHandler STT_FUNC
;@----------------------------------------------------------------------------
	stmfd sp!,{r4-r8,lr}
	bl calculateFPS

	ldrb r0,g_scaling
	cmp r0,#UNSCALED
	moveq r6,#0
	ldrne r6,=0x80000000 + ((GAME_HEIGHT-SCREEN_HEIGHT)*0x10000) / (SCREEN_HEIGHT-1)		;@ NDS 0x2B10 (was 0x2AAB)
	ldrbeq r8,yStart
	movne r8,#0
	add r8,r8,#0x10
	mov r7,r8,lsl#16

	ldr r0,g_flicker
	eors r0,r0,r0,lsl#31
	str r0,g_flicker
	addpl r6,r6,r6,lsl#16

	ldr r5,=SCROLLBUFF
	mov r4,r5

	ldr r3,=scrollTemp
	mov r12,#SCREEN_HEIGHT
scrolLoop2:
	ldr r0,[r3,r8,lsl#2]
	add r0,r0,r7
	mov r1,r0
	add r2,r7,#8				;@ Second bg layer
	stmia r4!,{r0-r2}
	adds r6,r6,r6,lsl#16
	addcs r7,r7,#0x10000
	adc r8,r8,#1
	subs r12,r12,#1
	bne scrolLoop2



	mov r6,#REG_BASE
	strh r6,[r6,#REG_DMA0CNT_H]	;@ DMA0 stop

	add r0,r6,#REG_DMA0SAD
	mov r1,r5					;@ Setup DMA buffer for scrolling:
	ldmia r1!,{r3-r5}			;@ Read
	add r2,r6,#REG_BG0HOFS		;@ DMA0 always goes here
	stmia r2,{r3-r5}			;@ Set 1st value manually, HBL is AFTER 1st line
	ldr r3,=0x96600003			;@ noIRQ hblank 32bit repeat incsrc inc_reloaddst, 3 word
	stmia r0,{r1-r3}			;@ DMA0 go

	add r1,r6,#REG_DMA3SAD

	ldr r2,dmaOamBuffer			;@ DMA3 src, OAM transfer:
	mov r3,#OAM					;@ DMA3 dst
	mov r4,#0x84000000			;@ noIRQ 32bit incsrc incdst
	orr r4,r4,#64*2				;@ 64 sprites * 2 longwords
	stmia r1,{r2-r4}			;@ DMA3 go

	ldr r2,=EMUPALBUFF			;@ DMA3 src, Palette transfer:
	mov r3,#BG_PALETTE			;@ DMA3 dst
	mov r4,#0x84000000			;@ noIRQ 32bit incsrc incdst
	orr r4,r4,#0x100			;@ 256 words (1024 bytes)
	stmia r1,{r2-r4}			;@ DMA3 go

	ldr r0,=0x000A
	ldr koptr,=k005885_0
	ldrb r2,[koptr,#sprBank]
	and r1,r2,#0x3				;@ Tile bank
//	add r0,r0,r1,lsl#3
	strh r0,[r6,#REG_BG0CNT]

	mov r0,#0x0017
	tst r2,#0x04				;@ Is left/right overlay on?
	biceq r0,#0x0004
	ldrb r1,g_gfxMask
	bic r0,r0,r1
	strh r0,[r6,#REG_WININ]
	tst r2,#0x80				;@ 240/256 screen width.
	ldreq r0,=0x00FF			;@ start-end
	ldrne r0,=0x08F8			;@ start-end
	strh r0,[r6,#REG_WIN0H]

	blx scanKeys
	ldmfd sp!,{r4-r8,pc}


;@----------------------------------------------------------------------------
g_flicker:		.byte 1
				.space 2
g_twitch:		.byte 0

g_scaling:		.byte SCALED
g_gfxMask:		.byte 0
yStart:			.byte 0
				.byte 0
;@----------------------------------------------------------------------------
refreshGfx:					;@ Called from C.
	.type refreshGfx STT_FUNC
;@----------------------------------------------------------------------------
	adr koptr,k005885_0
;@----------------------------------------------------------------------------
endFrame:					;@ Called just before screen end (~line 240)	(r0-r2 safe to use)
;@----------------------------------------------------------------------------
	stmfd sp!,{r3,lr}

	ldr r0,=scrollTemp
	bl copyScrollValues
	mov r0,#BG_GFX			;@ Destination
	bl convertTileMap5885
	ldr r0,tmpOamBuffer		;@ Destination
	bl convertSprites5885
;@--------------------------

	ldr r0,dmaOamBuffer
	ldr r1,tmpOamBuffer
	str r0,tmpOamBuffer
	str r1,dmaOamBuffer

	mov r0,#1
	str r0,oamBufferReady

	ldr r0,=windowTop			;@ Load wtop, store in wtop+4.......load wtop+8, store in wtop+12
	ldmia r0,{r1-r3}			;@ Load with increment after
	stmib r0,{r1-r3}			;@ Store with increment before

	ldmfd sp!,{r3,lr}
	bx lr

;@----------------------------------------------------------------------------
DMA0BUFPTR:			.long 0

tmpOamBuffer:		.long OAM_BUFFER1
dmaOamBuffer:		.long OAM_BUFFER2

oamBufferReady:		.long 0
emuPaletteReady:	.long 0
;@----------------------------------------------------------------------------
k005849Reset0:			;@ r0=periodicIrqFunc, r1=frameIrqFunc, r2=frame2IrqFunc
;@----------------------------------------------------------------------------
	adr koptr,k005849_0
	b k005849Reset
;@----------------------------------------------------------------------------
k005849Ram_0R:				;@ Ram read (0x0000-0x1FFF)
;@----------------------------------------------------------------------------
	stmfd sp!,{addy,lr}
	mov r1,addy
	adr koptr,k005849_0
	bl k005849Ram_R
	ldmfd sp!,{addy,pc}
;@----------------------------------------------------------------------------
k005849_0R:					;@ I/O read, 0x2000-0x2044
;@----------------------------------------------------------------------------
	stmfd sp!,{addy,lr}
	mov r1,addy
	adr koptr,k005849_0
	bl k005849_R
	ldmfd sp!,{addy,pc}

;@----------------------------------------------------------------------------
k005849Ram_0W:				;@ Ram write (0x0000-0x1FFF)
;@----------------------------------------------------------------------------
	stmfd sp!,{addy,lr}
	mov r1,addy
	adr koptr,k005849_0
	bl k005849Ram_W
	ldmfd sp!,{addy,pc}
;@----------------------------------------------------------------------------
k005849_0W:					;@ I/O write  (0x2000-0x2044)
;@----------------------------------------------------------------------------
	stmfd sp!,{addy,lr}
	mov r1,addy
	adr koptr,k005849_0
	bl k005849_W
	ldmfd sp!,{addy,pc}

;@----------------------------------------------------------------------------
k005885Reset0:			;@ r0=periodicIrqFunc, r1=frameIrqFunc, r2=frame2IrqFunc
;@----------------------------------------------------------------------------
	adr koptr,k005885_0
	b k005849Reset
;@----------------------------------------------------------------------------
k005885Ram_0R:				;@ Ram read (0x2000-0x3FFF)
;@----------------------------------------------------------------------------
	stmfd sp!,{addy,lr}
	mov r1,addy
	adr koptr,k005885_0
	bl k005885Ram_R
	ldmfd sp!,{addy,pc}
;@----------------------------------------------------------------------------
k005885_0R:					;@ I/O read, 0x0000-0x005F
;@----------------------------------------------------------------------------
	stmfd sp!,{addy,lr}
	mov r1,addy
	adr koptr,k005885_0
	bl k005885_R
	ldmfd sp!,{addy,pc}

;@----------------------------------------------------------------------------
k005885Ram_0W:				;@ Ram write (0x2000-0x3FFF)
;@----------------------------------------------------------------------------
	stmfd sp!,{addy,lr}
	mov r1,addy
	adr koptr,k005885_0
	bl k005885Ram_W
	ldmfd sp!,{addy,pc}
;@----------------------------------------------------------------------------
k005885_0W:					;@ I/O write  (0x0000-0x005F)
;@----------------------------------------------------------------------------
	stmfd sp!,{addy,lr}
	mov r1,addy
	adr koptr,k005885_0
	bl k005885_W
	ldmfd sp!,{addy,pc}

k005849_0:
k005885_0:
	.space k005849Size
;@----------------------------------------------------------------------------

gfxState:
adjustBlend:
	.long 0
windowTop:
	.long 0
wTop:
	.long 0,0,0		;@ windowTop  (this label too)   L/R scrolling in unscaled mode

	.byte 0
	.byte 0
	.byte 0
	.byte 0

	.section .bss
scrollTemp:
	.space 0x100*4
OAM_BUFFER1:
	.space 0x400
OAM_BUFFER2:
	.space 0x400
DMA0BUFF:
	.space 0x200
SCROLLBUFF:
	.space 0x400*3				;@ Scrollbuffer.
MAPPED_RGB:
	.space 0x400				;@ 0x400
EMUPALBUFF:
	.space 0x400
emuRAM:
	.space 0x2000
	.space SPRBLOCKCOUNT*4
	.space BGBLOCKCOUNT*4

	.align 9
Gfx1Bg:
	.space 0x20000

;@----------------------------------------------------------------------------
	.end
#endif // #ifdef __arm__
