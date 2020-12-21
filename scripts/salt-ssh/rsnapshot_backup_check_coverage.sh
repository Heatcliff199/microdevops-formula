#!/usr/bin/env bash
GRAND_EXIT=0

if [[ "_$1" = "_" ]]; then
	echo ERROR: needed args missing: use rsnapshot_backup_check_coverage.sh TARGET
	exit 1
fi

SALT_TARGET=$1
	
OUT_FILE="$(mktemp -p /dev/shm/)"

exec > >(tee ${OUT_FILE})
exec 2>&1

( set -x ; stdbuf -oL -eL  bash -c "salt-ssh --wipe --force-color ${SALT_TARGET} state.apply rsnapshot_backup.check_coverage queue=True" ) || GRAND_EXIT=1

# Check out file for errors
grep -q "ERROR" ${OUT_FILE} && GRAND_EXIT=1

# Check out file for red color with shades 
grep -q "\[0;31m" ${OUT_FILE} && GRAND_EXIT=1
grep -q "\[31m" ${OUT_FILE} && GRAND_EXIT=1
grep -q "\[0;1;31m" ${OUT_FILE} && GRAND_EXIT=1

exit $GRAND_EXIT
