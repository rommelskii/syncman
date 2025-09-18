#!/bin/bash

INPUT="$1"
DAEMON_NAME="synchro"
TMP_DIR="/tmp/synchro/"
PID_FILE="/tmp/synchro/${DAEMON_NAME}.pid"
DIR_FILE="/tmp/synchro/${DAEMON_NAME}.dir"



case "$INPUT" in
	start)
		if [ ! -f "$DIR_FILE" ]; then
			echo "Failed to access directory. Exiting..."
			exit 1
		fi

		cd $(cat "$DIR_FILE")

		pid=$$
		if [ -f "$PID_FILE" ]; then
			rm $PID_FILE
		fi
		echo "$pid" >> "$PID_FILE"

		echo "Process started."

		while true #loop entry
		do 
			if [ -n "$(git fetch --porcelain)" ]; then
				echo "Detected change at $(date). Pulling from origin..."
				git pull &> /dev/null
			fi

			if [ -n "$(git status --porcelain)" ]; then
				echo "Detected change at $(date). Pushing to origin..."
				git add * 
				git commit -m "$(date)" &> /dev/null
				git push &> /dev/null
			fi

			sleep 1
		done 
		;;
	stop)
		if [ ! -f "$PID_FILE" ]; then
			echo "Process is not running. Exiting..."
			exit 1
		fi
		pid=$(cat "$PID_FILE")
		kill $pid &> /dev/null

		if ! kill -0 $pid &> /dev/null; then
			echo "Failed to kill process $pid. Exiting..."
			rm "$PID_FILE"
			exit 1
		fi

		rm $PID_FILE

		echo "Process successfully stopped."
		;;
	dir) 
		if [ ! -d "/tmp/synchro/" ]; then
			echo "Temp folder does not exist. Creating..."
			mkdir -p "$TMP_DIR"
		fi

		if [ ! -f "$DIR_FILE" ]; then
			echo "Directory file does not exist. Creating..."
			touch "$DIR_FILE"
		fi

		read -p "Enter directory: " NEW_DIR 

		if [ ! -d "$NEW_DIR" ]; then
			echo "Invalid directory! Exiting..."
			exit 1
		fi

		rm "$DIR_FILE"
		echo "$NEW_DIR" >> "$DIR_FILE"

		if [ ! -f "$DIR_FILE" ]; then 
			echo "Failed to set new directory. Exiting..."
			exit 1
		fi

		;;
	*) 
		echo "Usage: ./daemon_run (start | stop | dir)"
		exit 1
		;;
esac 


exit 0
