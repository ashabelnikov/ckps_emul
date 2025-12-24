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

;Created by Alexey A. Shabelnikov (STC) 21/10/2012, Kiev
;28.11.2017 код адаптирован для ATtiny45/85.
;28.11.2017 code was ported to ATtiny45/85
;Программа для эмуляции сигнала с датчика 60-2 для тестирования зажигания
;Software for emulation of signals of 60-2 trigger wheels.
;
;Изменение оборотов производится путем изменения напряжения на выводе PB3 (вход АЦП)
;в диапазоне 0...5в.
; Выход ДУИ: PB1, PB2
;
;Changing of RPM is oerformed by altering of voltage at the PB3 pin of processor
; in 0...5V range.
; Output of the non-missing tooth wheel: PB1, PB2
;
;
; Есть возможность генерировать сигнал датчика фаз. Для этого в командной строке ассемблера нужно
; указать опцию -DCAMSENSOR. сигнад датчика фаз берется с PB1
; Thare is a possibility also to generate a cam signal. For doing that you should specify -DCAMSENSOR
; option in the command line of assembler.

; МК должен работать в режиме совместимости с ATtiny15. Для этого нужно установить fuse-биты CKSEL в 0011
; Processor should work in the ATtiny15 compatibility mode. To do that you should set CKSEL fuses to 0011 value
;

.include "tn85def.inc"

; Variables
.def TOOTH  =  r21            ;Tooth (pulse) conter
.def FLAGS  =  r18            ;Flags used in interrupts
.def PERD2  =  r19            ;Period / 2
;              r17            ;For use as temporary register in interrupts
;              r20            ;For save SREG in interrupts
;              r16            ;For use in main loop
;              r23            ;For use in main loop
.def CAMST  =  r25            ;For cam sensor signal generation (1 time per 2 revolutions)


; Constants
.equ TOOTH_NUM = 60           ;Number of teeth
.equ PERD_MIN  = 3            ;
.equ PERD_MAX  = 253          ;
#ifdef CAMSENSOR
.equ CAM_P_BEF = 3            ; Beginning of can sensor pulse in teeth before reference pulse
.equ CAM_P_AFT = 3            ; Ending of can sensor pulse in teeth before reference pulse
#endif

; Interrupt vectors
       .org  $0000
        rjmp RESET            ;Reset handler

       .org  $0003
        rjmp TC1COMP          ;Timer/Counter1 Compare Match

       .org  $0004
        rjmp TC1OVF           ;Timer/Counter 1 overflow


;-----------------------------------
TC1OVF:
       in   r20, SREG

       out  TCNT1, PERD2      ;load 1/2 period

       sbrs FLAGS, 0
       rjmp TC1OVF_0

       cpi TOOTH, TOOTH_NUM - 2
       BRSH  ST00             ;skip 2 teeth
#ifndef CAMSENSOR
       sbi  PORTB, PB1
#endif
       cbi  PORTB, PB2
ST00:
       andi FLAGS, ~(1 << 0)

       CPI  TOOTH, 0
       BRNE L00
       com  CAMST
       ldi  TOOTH, TOOTH_NUM  ;reload tooth counter
L00:

;=====================================
#ifdef CAMSENSOR
       CPI  TOOTH, TOOTH_NUM - 1 - CAM_P_BEF
       BRNE L11
       cbi  PORTB, PB1
L11:
       CPI  CAMST, 0
       BREQ L12               ;skip each 1-st referense pulse
       CPI  TOOTH, CAM_P_AFT
       BRNE L12
       sbi  PORTB, PB1
L12:
#endif
;=====================================

       DEC  TOOTH
       out  SREG, r20
       reti

TC1OVF_0:
#ifndef CAMSENSOR
       cbi  PORTB, PB1
#endif
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
;=====================================
#ifdef CAMSENSOR
       ldi  CAMST, 0
#endif
;=====================================

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

       NEG  R16               ;при увеличении напряжения на входе АЦП обороты должны возрастать

       ;calculate period values
       ldi  R23, 0
       sub  R23, R16

       ;update period
       cli
       mov PERD2, R23
       sei

       rjmp  loop

.exit
