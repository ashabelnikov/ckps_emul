#!/bin/sh
#Script for Linux

#wine avrasm2.exe -fI refsemul_ps.asm -DCAMSENSOR
#wine hextobin.exe refsemul_ps.hex refsemul.bin

#wine avrasm2.exe -fI 36-1emul-tn85.asm
#wine hextobin.exe 36-1emul-tn85.hex 36-1emul-tn85.bin

wine avrasm2.exe -fI refsemul_ps_tn85.asm -DCAMSENSOR
wine hextobin.exe refsemul_ps_tn85.hex refsemul_ps_tn85.bin
