
set PROGRAMMER=avreal32.exe
set CODE=refsemul.hex
set MCU=+attiny15

%PROGRAMMER% -as -p%LPT% %MCU% -o1MHZ -e -w %CODE%
