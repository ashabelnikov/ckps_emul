#!/bin/sh
#Script for Linux

PROGRAMMER=avrdude
CODE=refsemul_ps.hex
MCU=ATTINY15

$PROGRAMMER -p $MCU -c avr910 -P /dev/ttyACM1 -U flash:w:$CODE
