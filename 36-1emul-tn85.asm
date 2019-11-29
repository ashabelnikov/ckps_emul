/* SECU-3  - An open source, free engine control unit
   Copyright (C) 2007 Alexey A. Shabelnikov. Ukraine, Kiev

   This program is free software: you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation, either version 3 of the License, or
   (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program.  If not, see <http://www.gnu.org/licenses/>.

   contacts:
              http://secu-3.org
              email: shabelnikov@secu-3.org
*/

;Created by Alexey A. Shabelnikov (STC) 28/10/2013, Kiev
;Program for simulation of signal from 36-1 CKP sensor
;28.11.2017 code was ported to ATtiny25/45/85.
;
;You can change RPM by changing voltage at the PB.3 pin (ADC input)
;in range 0...5V.
;
;CKP Outputs: PB1, PB2
;
; Processor should work in the ATtiny15 compatibility mode. For doing that you should set CKSEL fuses to 0011.
; See datasheet for more information about ATtiny15 compatibility mode.

;.include "tn15def.inc"
.include "tn85def.inc"

; Variables
.def TOOTH  =  r21            ;Tooth (pulse) conter
.def FLAGS  =  r18            ;Flags used in interrupts
.def PERD2  =  r19            ;Period / 2
;              r20            ;For save SREG in interrupts
;              r16            ;For use in main loop
;              r23            ;For use in main loop

; Constants
.equ TOOTH_NUM = 36           ;Number of teeth
.equ PERD_MIN  = 3            ;
.equ PERD_MAX  = 253          ;

; Interrupt vectors
       .org  $0000
        rjmp RESET            ;Reset handler

       .org  $0004
        rjmp TC1OVF           ;Timer/Counter 1 overflow


;-----------------------------------
TC1OVF:
       in   r20, SREG

       out  TCNT1, PERD2      ;load 1/2 period

       sbrs FLAGS, 0          ; check current edge
       rjmp TC1OVF_0          ;


       CPI  TOOTH, TOOTH_NUM - 1  ;skip 1 tooth
       BREQ L00
       sbi  PORTB, PB1
       cbi  PORTB, PB2
L00:
       andi FLAGS, ~(1 << 0)

       CPI  TOOTH, 0          ; if zero than load counter again
       BRNE L10
       ldi  TOOTH, TOOTH_NUM
L10:

       DEC  TOOTH
       out  SREG, r20
       reti

TC1OVF_0:
       cbi  PORTB, PB1
       sbi  PORTB, PB2
       ori  FLAGS, (1 << 0)
       out  SREG, r20
       reti

;------------------------------------
RESET:
       ;prepare port b
       ldi  r16, (1 << DDB2) | (1 << DDB1)
       out  DDRB, r16         ;PB1, PB2 - outputs
       ldi  r16, 0x00
       out  PORTB, r16 

       ;init flags and variables
       ldi  FLAGS, 0
       ldi  TOOTH, TOOTH_NUM

       ;configure Timer1
       ldi  r16, 0
       out  TCNT1, r16
       ldi  r16, (1 << CS13)
       out  TCCR1, r16

       ;configure ADC
       ldi  r16, (1 << ADLAR) | (1 << MUX1) | (1 << MUX0) ;VCC used as analog reference, disconnected from PB0 (AREF), select ADC3
       out  ADMUX,r16
       ldi  r16, (1 << ADEN) | (1 << ADSC) | (1 << ADATE) | (1 << ADPS2) | (1 << ADPS1) | (1 << ADPS0) ;free runing mode, div=128, start, enable
       out  ADCSRA,r16

       ;wait for first ADC conversion
       ldi  r16, 0
L20:
       dec  r16
       brne L20

       ;enable interrupts
       ldi  r16, (1 << TOIE1)
       out  TIMSK, r16
       sei

       ;main loop
loop:
       ; read ADC
       in   R16, ADCL
       in   R16, ADCH

       ;limit minimum and maximum values
       cpi  R16, PERD_MIN
       BRSH L30
       ldi  R16, PERD_MIN
L30:
       cpi  R16, PERD_MAX
       BRLO L40
       ldi  R16, PERD_MAX
L40:

       NEG  R16                ; when voltage at the input raises, RPM value raises too

       ;calculate period values
       ldi  R23, 0
       sub  R23, R16

       ;update period
       cli
       mov PERD2, R23
       sei

       rjmp  loop

.exit
