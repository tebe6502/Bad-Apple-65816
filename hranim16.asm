
// BAD APPLE - RAPIDUS CPU 65816

// 22.10.2018

	icl 'atari.hea'
	icl 'move.mac'

pm	= $0000

buf	= $0000		; 240 bytes max

data	= $110000
smpl	= $580000

frames	= 5432

prg	= $2000

bmp0	= $d808
bmp1	= $e000
bmp2	= $f000


	org $f6

px	.ds 1
py	.ds 1
ret	.ds 2
cnt	.ds 2
dat	.ds 3

regA	.ds 1

	ert *>$100

	opt c+

	org prg

fnt	ins 'title\title_h6.fnt'

dl	dta $4e,a(bmp0)
	:50 dta $e
	dta $4e,a(bmp1)
	:101 dta $e
	dta $4e,a(bmp2)
	:86 dta $e
	dta $41,a(dl)

	.align

tdl	dta d'pppppp'
	dta $42,a(scr)
	:18 dta 2
	dta $41,a(tdl)

scr	ins 'title\title_h6.scr',6*40,19*40


tic	brk

main
	lda:rne vcount

	sei
	stz nmien
	stz irqen

	mva #$fe portb

	mwa #irq0 irqvec

	mwa #nmi nmivec

	ldx #5
	ldy #0
mv0	lda pmg,y
mv1	sta pm+$300,y
	iny
	bne mv0
	inc mv0+2
	inc mv1+2
	dex
	bne mv0

	lda $ff0080
	sta rmem0

	lda $ff0081
	sta rmem1


// --------------------------------------------------
//	Title screen
// --------------------------------------------------
title	lda consol
	cmp #$0e
	beq title

	lda:rne vcount

	sei
	stz nmien
	stz irqen
	stz dmactl

	lda #0
rmem0	equ *-1
	sta $ff0080

	lda #0
rmem1	equ *-1
	sta $ff0081

	ldx #$ff
	txs

	ldx #$1f
	stz:rpl $d000,x-

	lda >fnt
	sta chbase

	stz pmbase
	mva #$3 pmcntl

	stz colbak
	stz color0
	stz color1
	lda #$0E
	sta color2

	lda #$11
	sta gtictl

	lda #$03
	sta sizep0
	sta sizep1
	sta sizep2
	sta sizep3
	lda #$FF
	sta sizem

	lda #$30
	sta hposp0
	lda #$50
	sta hposp1
	lda #$48
	sta hposp2
	lda #$68
	sta hposp3
	lda #$88
	sta hposm0
	lda #$90
	sta hposm1
	lda #$98
	sta hposm2
	lda #$A0
	sta hposm3
	lda #$06
	sta colpm0
	sta colpm1
	lda #$0A
	sta colpm2
	sta colpm3
	sta color3

	mva #scr40 dmactl
	mwa #tdl dlptr

wait	lda consol
	cmp #$0e
	bne wait

wait_	lda consol
	cmp #$0e
	beq wait_


// --------------------------------------------------
//	Plays animation
// --------------------------------------------------
start	lda:rne vcount

	stz dmactl

	ldx #$1f
	stz:rpl $d000,x-

	fill >bmp0 #$27 #$00

	mva #$08 color0
	sta decode.cl0
	mva #$04 color1
	mva #$0e color2
	mva #$00 colbak
	sta decode.bkg

	lda #3
	sta sizep0
	sta sizep1
	sta sizep2
	sta sizep3

	lda #4
	sta gtictl

	stz colpm0
	stz colpm1
	stz colpm2
	stz colpm3

	lda #$ff
	sta grafp0
	sta grafp1
	sta grafp2
	sta grafp3

	sta grafm

	sta sizem

	:4 mva #48+#*32 hposp0+#

	:4 mva #176+#*8 hposm0+#


	mva #@dmactl(dma|normal) dmactl
	mwa #dl dlptr

	lda #%01110100	; 116			; RAPIDUS Memory Configuration Register
	sta $ff0080

	lda #%11000001	; 193
	sta $ff0081

	ldx #8
clr	stz AUDF1,x
	stz AUDF1+$10,x
	dex
	bpl clr

	lda #%01000000
	sta AUDCTL

	mva #1 SKCTL				; init POKEY
	sta wsync
	sta wsync

;	mva	#52	AUDF1			; 32000

	mva	#36	AUDF1			; 44100

	mva	#$01	IRQEN			; enable timer

	sta	STIMER				; start timers

	mva #$40 nmien
	cli


.local	decode

	stz cnt
	stz cnt+1
	stz _key
	stz tic

	mva <data dat
	mva >data dat+1
	mva ^data dat+2

	mva <smpl irq0.smp
	mva >smpl irq0.smp+1
	mva ^smpl irq0.smp+2

	ldy #$ff

begin
	:2 lda:cmp:req tic

	mva #39 px

loop	stz py

repeat	iny

	lda [dat],y
	beq nxtCol
	bpl skip

	bra store

skip	add py
	sta py

	cmp #240
	bcc repeat

nxtCol	tya
	add dat
	sta dat
	scc
	inw dat+1
;	lda #0
;	adc dat+1
;	sta dat+1
;	scc
;	inc dat+2

	ldy #0

	dec px
	bpl loop

	iny

	lda [dat],y
	bpl skp

	lda #0
bkg	equ *-1
	eor #$0e
	sta bkg

	sta colpm0
	sta colpm1
	sta colpm2
	sta colpm3

	eor #$0e
	sta color2

	lda #$08
cl0	equ *-1
	eor #8^4
	sta cl0
	sta color0

	eor #8^4
	sta color1

skp	lda consol
	cmp #$e
_key	equ *-1
	beq restart

	inw cnt
	cpw cnt #frames
	seq

	jmp begin

restart	jmp title

store
;	tya
;	add dat
;	sta dat
;	lda #0
;	adc dat+1
;	sta dat+1
;	scc
;	inc dat+2


;	jsr rle

.local	rle
	mva #0 outputPointer

loop    iny
	lda [dat],y
	beq stop
	lsr @

	tax
lp0	iny
	lda [dat],y
lp1	sta buf
outputPointer	equ *-1

	inc outputPointer
	dex
	bmi loop

	bcs lp0
	bcc lp1

stop
.endl
;	rts

	tya
	add dat
	sta dat
	scc
	inw dat+1
;	lda #0
;	adc dat+1
;	sta dat+1
;	scc
;	inc dat+2

	ldx py
	mva ladr,x jm
	mva hadr,x jm+1

	txa
	add rle.outputPointer
	tax
	mva ladr,x ret
	mva hadr,x ret+1

	lda #{jmp}
	sta (ret)
	ldy #1
	lda <stop
	sta (ret),y
	iny
	lda >stop
	sta (ret),y

	ldy px
	ldx #0

;	mva rle.outputPointer max

	jmp start
jm	equ *-2

start
	.rept 87
	lda buf,x
	sta bmp2+[86-#]*40,y
	inx
;	cpx max
;	sne
;	jmp stop
	.endr

	.rept 102
	lda buf,x
	sta bmp1+[101-#]*40,y
	inx
;	cpx max
;	sne
;	jmp stop
	.endr

	.rept 51
	lda buf,x
	sta bmp0+[50-#]*40,y
	inx
;	cpx max
;	sne
;	jmp stop
	.endr

	lda buf,x
	sta bmp0

stop
	lda #{lda 0,x}
	sta (ret)
	ldy #1
	lda #0
	sta (ret),y
	iny
	lda #{sta bmp0,y}
	sta (ret),y

	txa

	ldy #0

	jmp skip

.endl


;----------------------------------------------------

.local	irq0
	sta regA

	stz IRQEN
	lda #1
	sta IRQEN

	lda table1
v1	equ *-2
	sta audc1
;	sta audc1+$10

	lda table2
v2	equ *-2
	sta audc2
;	sta audc2+$10

	lda table3
v3	equ *-2
	sta audc3
;	sta audc3+$10

	lda.l $ffffff
smp	equ *-3
	sta v1
	sta v2
	sta v3

	inl smp

	lda regA

	rti
.endl

;----------------------------------------------------



.local	nmi
;	bit nmist
;	bpl vbl
;dli	rti

vbl	sta rA

;	sta nmist

	inc tic

	spl
	mva #$e decode._key

;	mva #@dmactl(dma|normal) dmactl
	lda <dl
	sta dlptr

	lda #0
rA	equ *-1

	rti
.endl

;----------------------------------------------------

.proc	fill (.byte y,x,a) .reg
	sty adr+1

	ldy #0
loop	sta $ff00,y
adr	equ *-2
	iny
	bne loop
	inc adr+1
	dex
	bne loop

	rts
.endp

;----------------------------------------------------

	.align

ladr	:256 dta l(decode.start+#*6)
hadr	:256 dta h(decode.start+#*6)

table1	= *
table2	= *+$100
table3	= *+$200

;	ins '6bit\volume_6bit.dat'
;	ins '6bit\pecus_6bit.obx'

	ins '6bit\draco_6bit.dat'

pmg	ins 'title\title_h6.pmg'

.print 'end: ',*

.print 'table1: ', table1
.print 'table2: ', table2
.print 'table3: ', table3

	run main
