#!/bin/bash

set -o nounset
set -o errexit
set -o pipefail

# Speed up by skipping CVS folders etc ...
EXCLUDE_ARGS="-not \( -name .bzr -prune \) -not \( -name .cdv -prune \) -not \( -name ~.dep -prune \) -not \( -name ~.dot -prune \) -not \( -name ~.nib -prune \) -not \( -name ~.plst -prune \) -not \( -name .git -prune \) -not \( -name .hg -prune \) -not \( -name .pc -prune \) -not \( -name .svn -prune \) -not \( -name _MTN -prune \) -not \( -name blib -prune \) -not \( -name CVS -prune \) -not \( -name RCS -prune \) -not \( -name SCCS -prune \) -not \( -name _darcs -prune \) -not \( -name _sgbak -prune \) -not \( -name autom4te.cache -prune \) -not \( -name cover_db -prune \) -not \( -name _build -prune \) -not \( -name node_modules -prune \)"

# Find all modified files
function modifiedSince() {
    local dir=$1
    local seconds=$2

    bash -c "find '${dir}' ${EXCLUDE_ARGS} -type f -newermt '${seconds} seconds ago'"
}

function watch() {
    local dir=$1
    local seconds=$2
    local cmd=$3
    local sleepSeconds=`expr ${seconds} - 1`
    local pid=""

    # Utilty function to command
    function run() {
        # Run command and keep PID (for long running commands)
        bash -c "exec bash -c '${cmd}'" &

        # Keep PID to kill later when needed
        pid=$!

        # Sleep a bit to avoid false positives
        # this can happen if the command changes files
        sleep ${seconds}
    }

    # Utility kill func
    function _kill() {
        local pid=$1

        kill -s KILL ${pid}
    }

    # Kill command if killed myself
    trap '_kill ${pid}' EXIT KILL

    # Run first time
    run

    while [[ true ]]
    do
        # See if any files have been modified
        files=$(modifiedSince "${dir}" "${seconds}")
        if [[ ${files} == "" ]] ; then
            echo -n "."
        else
            echo ""
            echo "#### Files ####"
            echo "${files}"
            echo "####  End  ####"
            echo ""

            # Attempt to kill old process if we have a PID
            echo "Killing ${pid}"
            _kill ${pid}

            # Wait a tiny bit for cleanup
            sleep 0.2

            # Run command again
            run
        fi
        sleep ${sleepSeconds}
    done
}

# Constants
seconds="2" # Must be equal or greater to 2 (since we substract from it later)

# CLI args
folder=$1
cmd=${@:2}

watch "${folder}" "${seconds}" "${cmd}"

wait
