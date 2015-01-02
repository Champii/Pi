#!/bin/bash

# $1 == start
# $2 == finish
echo "Init $# $0 $1 $2"

START=$(( `ls -l ./original | wc -l` - 1 ))
NB=60
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
DEST="/data_unsafe/pi/original/$I.ycd"
SRC="http://fios.houkouonchi.jp:8080/pi/Pi%20-%20Hex%20-%20Chudnovsky/Pi%20-%20Hex%20-%20Chudnovsky%20-%20$I.ycd -c -O $DEST"

wget $SRC $DEST
#echo "wget $SRC $DEST"
#echo -n "Splitting hex file......"
#split -a 1 -n $NB -d 0.hex ''
#echo "Ok"
done

echo -n "Finished"
