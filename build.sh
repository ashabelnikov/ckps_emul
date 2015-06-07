#!/bin/sh
#Script for Linux

wine avrasm2.exe -fI refsemul_ps.asm -DCAMSENSOR
wine hextobin.exe refsemul_ps.hex refsemul.bin