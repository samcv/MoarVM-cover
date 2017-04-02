#!/usr/bin/env sh
# Merges all the files created by nqp-profile
if [ "$1" ]; then
    COVERAGE_DIR="$1"
    printf "Merging into folder '%s' via command line argument\n" "$COVERAGE_DIR"
else
    COVERAGE_DIR="./coverage"
    printf "Merging into folder '%s' via default\n" "$COVERAGE_DIR"
fi
OUT_FILE="$COVERAGE_DIR/nqptestcov.profdata"
if [ -d "$COVERAGE_DIR" ]; then
    FILES="$(find $COVERAGE_DIR -name '*.profraw')"
    llvm-profdata merge -o "$OUT_FILE" $FILES
    case "$?" in
        0) printf "Finished writing to $OUT_FILE\n"
        ;;
        *) printf "Encountered errors. Make sure none of the paths have spaces in the names\n"
        ;;
    esac
else
    printf "Could not find folder '%s'\n" "$COVERAGE_DIR"
fi
