#!/bin/bash

trap ctrl_c INT
RUN=true

function ctrl_c() {
        RUN=false
}

SINGLE=false
USERIRQ=""

while :
do
	case "$1" in
	  -s)
		SINGLE=true
		shift 1
		;;
	  -u)
		USERIRQ="-userirq"
		shift 1
		;;
	  -*) # Unknown option
		echo "Error: Unknown option: $1" >&2
		exit 1
		;;
	  *)
		break
		;;
	esac
done


EXIT_CODE1=0
EXIT_CODE2=0

i=1
while $RUN;
do
	if [[ $SINGLE == false ]]; then
		echo "Running 2 guests in parallel (round $i)"
	else
		echo "Running 1 guest (round $i)"
	fi

	setsid expect hackbench-shutdown.exp ../arm64-trusty.img $USERIRQ --alt-console 5000 > /tmp/guest1.log &
	PID1=$!

	if [[ $SINGLE == false ]]; then
		setsid expect hackbench-shutdown.exp ../arm64-trusty-2.img $USERIRQ --alt-console 5001 > /tmp/guest2.log &
		PID2=$!
	fi

	while true; do
		wait $PID1
		EXIT_CODE1=$?

		if [[ $EXIT_CODE1 -gt 128 ]]; then
			continue
		fi

		if [[ $SINGLE == false ]]; then
			wait $PID2
			EXIT_CODE2=$?
		fi

		# The signal handler will return from wait and give us an exit code greater
		# than 128 - see the bash manual and search for 'wait builtin'.
		if [[ $EXIT_CODE1 -le 128 && $EXIT_CODE2 -le 128 ]]; then
			break
		fi
	done

	if [[ $EXIT_CODE1 != 0 || $EXIT_CODE2 != 0 ]]; then
		echo "Exit code non-zero: guest1: $EXIT_CODE1, guest2: $EXIT_CODE2"
		exit 1
	fi

	i=$(($i+1))
	sleep 1
done
