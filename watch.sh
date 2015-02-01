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

    while [[ true ]]
    do
        # See if any files have been modified
        files=$(modifiedSince "${dir}" "${seconds}")
        if [[ ${files} == "" ]] ; then
            echo -n "."
        else
            # Attempt to kill old process if we have a PID
            if [[ ${pid} != "" ]]; then
                output=$(kill -s KILL ${pid} &> /dev/null && echo -n "good" || echo -n "bad")

                # Output if killed or not
                if [[ ${output} == "good" ]] ; then
                    echo -n "O"
                else
                    echo -n "X"
                fi
            fi

            # Run command and keep PID (for long running commands)
            bash -c "${cmd}" &

            # Keep PID to kill later when needed
            pid=$!
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
