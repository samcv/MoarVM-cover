#!/usr/bin/env sh
# Merges all the files created by nqp-profile
# If supplied a command line argument, this becomes the directory which is used
# by which all files in this folder ending in .profraw will be merged
if [ "$1" ]; then
    COVERAGE_DIR="$1"
    printf "Merging into folder '%s' via command line argument\n" "$COVERAGE_DIR"
else
    COVERAGE_DIR="./coverage"
    printf "Merging into folder '%s' via default\n" "$COVERAGE_DIR"
fi
find_latest_version () { ls /usr/bin | grep -Ee "^$1(\-[0-9.]+)?$" | sort -r | head -n 1; }
llvm_profdata=$(find_latest_version llvm-profdata)
if [ ! "$llvm_profdata" ]; then
    echo "Didn't find llvm-profdata in /usr/bin hoping it's in your path";
    llvm_profdata="llvm-profdata";
fi
ls /usr/bin | grep -Ee '^clang(\-[0-9.]+)?$' | sort -r | head -n 1
OUT_FILE="$COVERAGE_DIR/nqptestcov.profdata"
if [ -d "$COVERAGE_DIR" ]; then
    FILES="$(find $COVERAGE_DIR -name '*.profraw')"
    echo "FILES: ($FILES)"
    $llvm_profdata merge -o "$OUT_FILE" $FILES
    case "$?" in
        0) printf "Finished writing to $OUT_FILE\n"
        ;;
        *) printf "Encountered errors. Make sure none of the paths have spaces in the names\n"
        ;;
    esac
else
    printf "Could not find folder '%s'\n" "$COVERAGE_DIR"
fi
