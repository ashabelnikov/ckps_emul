#!/bin/sh
#Script for Linux

PROGRAMMER=avrdude
#CODE=refsemul_ps.hex
#MCU=ATTINY15
#CODE=refsemul_ps.hex
#CODE=36-1emul-tn85.hex
CODE=refsemul_ps_tn85.hex
MCU=ATTINY85

$PROGRAMMER -p $MCU -c usbasp -P /dev/ttyACM0 -U flash:w:$CODE
