#!/bin/sh
# Script file for setting up of microcontroller's fuse bits for solarcharger project
# Created by Alexey A. Shabelnikov, Kiev 29 May 2017.

PROGRAMMER=avrdude
LFUSE=0x63
HFUSE=0xD4
EFUSE=0xFF

#test if programmer exists
$PROGRAMMER >> /dev/null
if [ $? -ne 0 ]
then
 echo "ERROR: Can not execute file "$PROGRAMMER
 PrintError
 exit 1
fi

#Run programmer
$PROGRAMMER -p attiny85 -c usbasp -P /dev/ttyACM0 -F -U lfuse:w:$LFUSE:m -U hfuse:w:$HFUSE:m -U efuse:w:$EFUSE:m -i 100
if [ $? -ne 0 ]
then
 PrintError
 exit 1
fi

echo "ALL OPERATIONS WERE COMPLETED SUCCESSFULLY!"
exit 0

PrintError() {
echo "WARNING! THERE ARE SOME ERRORS IN EXECUTING BATCH."
}
