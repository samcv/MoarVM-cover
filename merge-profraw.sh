#!/usr/bin/env sh
# Merges all the files created by nqp-profile
COVERAGE_DIR="./coverage"
OUT_FILE="$COVERAGE_DIR/nqptestcov.profdata"
llvm-profdata merge -o "$OUT_FILE" "$COVERAGE_DIR"/* && printf "Finished writing to $OUT_FILE\n"
