#!/bin/bash
# Replaces genmon's genmonmaint.sh in the app image (the original is genmonmaint-orig.sh).
# genmon is part of the image and has no .git, so "-u" (web UI About -> Update) runs genmon-update,
# which rebuilds the app with the latest genmon. All other options go to the original script.

genmondir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
original="${genmondir}/genmonmaint-orig.sh"
args=("$@")

update=false
others=()
OPTIND=1
while getopts ":hfp:bt:irunc:Csl:" opt; do
    case "${opt}" in
        u) update=true ;;
        p|t|c|l) others+=("-${opt}" "${OPTARG}") ;;
        \?|:) others+=("-${OPTARG}") ;;
        *) others+=("-${opt}") ;;
    esac
done
shift $((OPTIND - 1))
others+=("$@")

if ! ${update}; then
    exec /bin/bash "${original}" "${args[@]}"
fi

/usr/local/bin/genmon-update
status=$?

# Run whatever else was requested; "-n" (no prompt) alone has nothing to do
for arg in "${others[@]}"; do
    if [ "${arg}" != "-n" ]; then
        exec /bin/bash "${original}" "${others[@]}"
    fi
done
exit ${status}
