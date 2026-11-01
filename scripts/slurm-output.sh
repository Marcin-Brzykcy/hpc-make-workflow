#!/bin/sh
# Print the output path specified in the Slurm directive header.
set -eu
script=$1
if [ ! -f "$script" ]; then
    echo "Slurm script not found: $script" >&2
    exit 1
fi
output=$(awk '
    /^[[:space:]]*$/ { next }
    /^[[:space:]]*#/ {
        line = $0
        if (line !~ /^[[:space:]]*#SBATCH[[:space:]]/) next
        sub(/^[[:space:]]*#SBATCH[[:space:]]+/, "", line)
        if (line ~ /^--output=/) sub(/^--output=/, "", line)
        else if (line ~ /^--output[[:space:]]+/) sub(/^--output[[:space:]]+/, "", line)
        else if (line ~ /^-o[[:space:]]+/) sub(/^-o[[:space:]]+/, "", line)
        else if (line ~ /^-o[^[:space:]]/) sub(/^-o/, "", line)
        else next
        sub(/[[:space:]]*#.*/, "", line)
        sub(/[[:space:]]+$/, "", line)
        if (line ~ /^"[^" ]*"$/ || line ~ /^\047[^\047 ]*\047$/) line = substr(line, 2, length(line)-2)
        result = line
        next
    }
    { exit }
    END { if (result != "") print result; else print "slurm-%j.out" }
' "$script")
case "$output" in
    /*|*..*|*[!a-zA-Z0-9_./%+-]*) echo "Unsupported Slurm output path: $output" >&2; exit 1 ;;
esac
# Only the job-ID substitution is supported; reject all other patterns.
rest=$(printf '%s' "$output" | sed 's/%j//g')
case "$rest" in *%*) echo "Unsupported Slurm output pattern: $output (only %j is supported)" >&2; exit 1 ;; esac
printf '%s\n' "$output"
