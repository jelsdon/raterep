#!/bin/bash
# A finger-in-the-air estimater of performance via logfile activity.
# Counts new lines per interval
# Author: James Elsdon <22/07/2013>

# Motivation; Portable code that has low dependencies, and easily shipped to
# a variety of unix-like hosts.

# Example: check mysql connections/second in real time
# (subject to tail/mysql/logging output’s performance)

#$ tail -s0.1 -n0 -f /var/lib/mysql/queries.log |grep --line-buffered Connect | ./raterep.sh
# [Mon Jul 22 12:37:28 EST 2013] 18
# [Mon Jul 22 12:37:29 EST 2013] 13
# [Mon Jul 22 12:37:30 EST 2013] 40


# Interval in seconds to which we report on
# (output rate is X lines per ${s_INTERVAL})
s_INTERVAL=1

# Keep track of when we stated
START_TIME=`date +%s%N| cut -b1-16`

# reader() accepts streaming character input.
# Reports on new lines read since initialisation
# or the last SIGHUP.
function reader() {
  # Zero our new line counter
  local newLineCount=0

  # readerstat() trap handler for
  # SIGHUP. Reports newline count and
  # resets counter.
  function readerstat()
  {
    # Report on line count
    echo "[`date`] ${newLineCount}"

    # Reset new line counter
    newLineCount=0
  }

  # Set readerstat() to fire on SIGHUP
  trap readerstat SIGHUP

  # Increase newline counter every time we see a new line
  while read line
    do
    let newLineCount+=1
  done

  # Final report (In the event we finish reading the file)
  echo "[`date`] ${newLineCount}"
}

function exitCode() {
  wait ${readerPID}

  # Calculate how long we've been running and report on it
  # before exiting
  STOP_TIME=`date +%s%N| cut -b1-16`
  TOTAL_TIME=`echo "${STOP_TIME} - ${START_TIME}" | bc`
  TOTAL_TIME=`bc <<< "scale = 2; ${TOTAL_TIME} / 1000"`
  echo "Total Time: ${TOTAL_TIME}ms"
  exit
}

# Set exitCode() to fire on SIGINT
trap exitCode SIGINT

# Pass stdin to our reader function. Main process will be
# left to control timing signals. Child pid is recorded
# as a means of existance (input is still being read).
cat - | reader &
readerPID=$!

# Whilst our child process is alive (EOF has not been reached)
# fire our signal to the child process to procude the interval
# report
while [ -d /proc/${readerPID} ]
do
  sleep $s_INTERVAL

  # Process may die before we get here, we don't care
  # if it no longer exists so squash the output
  kill -1 ${readerPID} >/dev/null 2>&1
done

# Wait for reader to return before we wrap things up
wait ${readerPID}

# Ensure we exit on EOF the same way we exit on Ctrl+C (SIGINT)
exitCode
