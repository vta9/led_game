; stateControls.asm
;Vincent Ave'Lallemant 
	
; There is a delay of approximately 0.5 seconds from one state to the next
; This delay is created using a 16*256 double loop
; The loop delay is approx 16 * 256 * 3 CPU cycles 
; Using an oscillator frequeny of 100 kHz, a CPU cycle is 40 microsec
; Loop delay is ~492 sec after testing 
 
; CPU configuration
; 16F84 with RC osc, watchdog timer off, power-up timer on

	processor 16f84A
	include <p16F84A.inc>
	__config _RC_OSC & _WDT_OFF & _PWRTE_ON

; macros

IFSET macro fr,bit,label
	btfss fr,bit 
	goto label 
      endm

IFCLR macro fr,bit,label
	btfsc fr,bit 
	goto label 
	  endm

IFEQ macro fr,lit,label
	movlw lit
	xorwf fr,W
	btfss STATUS,Z 
	goto label 
	 endm

IFNEQ macro fr,lit,label
	movlw lit
	xorwf fr,W
	btfsc STATUS,Z 
	goto label 
	 endm

MOVLF macro lit,fr
	movlw lit
	movwf fr
	  endm

MOVFF macro from,to
	movf from,W
	movwf to
  	  endm

; file register variables

nextS equ 0x0C 	; next state (output)
octr equ 0x0D	; outer-loop counter for delays
ictr equ 0x0E	; inner-loop counter for delays

; state definitions for Port B
L1 equ B'000001'  ;RB0
L2 equ B'000010'  ;RB1
L3 equ B'000100'  ;RB2
L4 equ B'001000'  ;RB3
ERR equ B'010000'  ;RB4
WIN equ B'100000' ;RB5

 
; input bits on Port A 
G1 equ 0 ;RA0
G2 equ 1 ;RA1
G3 equ 2 ;RA2
G4 equ 3 ;RA3
 


; beginning of program code

	org 0x00	; reset at address 0
reset:	goto	init	; skip reserved program addresses	

	org	0x08 	; beginning of user code
init:	
; set up RB5-0 as outputs
	bsf	STATUS,RP0	; switch to bank 1 memory
	MOVLF B'11000000',TRISB	; RB7-6 are inputs, RB5-0 are outputs 
	bcf	STATUS,RP0	; return to bank 0 memory 

	
mloop:	; main program loop
 
;state 1: only light 1 is on    
l1: 
    MOVLF L1, PORTB
    call delay 
    IFEQ PORTA, 0x00, guess1
    goto l2

;state 2: only light 2 is on 
l2:
    MOVLF L2, PORTB
    call delay
    IFEQ PORTA, 0x00, guess2
    goto l3

;state 3: only light 3 is on 
l3: 
    MOVLF L3, PORTB
    call delay
    IFEQ PORTA, 0x00, guess3
    goto l4

;state 4: only light 4 is on 
l4: 
    MOVLF L4, PORTB
    call delay 
    IFEQ PORTA, 0x00, guess4 
    goto l1

;substate of guess, user made guess during state 1
guess1:
    IFEQ PORTA, 0x01, wrong
    goto right
 
;substate of guess, user made guess during state 2
guess2: 
    IFEQ PORTA, 0x02, wrong
    goto right
  
;substate of guess, user made guess during state 3
guess3: 
    IFEQ PORTA, 0x04, wrong
    goto right
    
;substate of guess, user made guess during state 4
guess4: 
    IFEQ PORTA, 0x08, wrong
    goto right

;guess is wrong, enter error mode until all buttons are reset to 0000
wrong: 
    MOVLF ERR, PORTB
    call delay
    IFEQ PORTA, 0x00, wrong
    goto l1

;guess is correct, enter win mode until all buttons are reset to 0000
right: 
    MOVLF WIN, PORTB
    call delay
    IFEQ PORTA, 0x00, right
    goto l1

    
; create a delay of about 0.5 seconds
delay: 
	MOVLF	d'32',octr 
d1:	clrf	ictr	
d2: decfsz	ictr,F	
	goto 	d2		 	
	decfsz	octr,F	 
	goto	d1
    return
    
; end of main loop
endloop: 
	goto	mloop

	end	
	
; end of program code		
