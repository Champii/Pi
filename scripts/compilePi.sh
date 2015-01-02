#!/bin/bash

# $1 == start
# $2 == finish
echo "Init $# $0 $1 $2"

START=0
NB=$(( `ls -l ./original | wc -l` - 1))
if [[ "$#" -ge "1" ]]
then
	START=$1
fi
if [[ "$#" -ge "2" ]]
then
	NB=$2
fi

for (( I=$START; I<$NB; I++ ))
do
SRC="/data_unsafe/pi/original/$I.ycd"
DEST="/data_unsafe/pi/$I.txt"
HEX="/data_unsafe/pi/$I"
PROGRAM="/home/champii/y-cruncher/DigitViewer.out"
echo "0
$SRC
3
$(( $(( $I * 25000000000 )) + 1 ))
25000000000
$DEST" > compileParams


echo "Params : "
cat compileParams

echo -n "Extracting pi part $(( $I + 1 ))/$NB..."
cat compileParams | $PROGRAM
echo "Ok"

echo -n "Extracting hex file...................."
cat $DEST | xxd -r -p > $HEX
echo "Ok"

echo -n "Removing temp file....................."
rm $DEST
echo "Ok"


#echo -n "Splitting hex file...................."
#split -a 1 -n $NB -d 0.hex ''
#echo "Ok"
done

echo -n "Finished"
