set PROGRAMMER=avreal32.exe
set CODE=refsemul_r.hex
set HEXTOBIN=hextobin.exe


%PROGRAMMER% -as -p%LPT% +attiny15 -o1MHZ -r %CODE%

%HEXTOBIN% %CODE% refsemul_r.bin
