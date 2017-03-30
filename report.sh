#!/usr/bin/env bash
faketty () { script -qfc "$(printf "%q " "$@")"; }
if [[ "$1" = '' ]] || [[ "$1" = '-h' ]] || [[ "$1" = '--help' ]]; then
  printf "Usage: %s location/of/nqptestcov.profdata [-html]\n" "$0"
  exit 0
fi
if [ ! -f "$1" ]; then
  printf "did not receive any input or could not find the file '$1'\n"
  exit 1
fi
if [ ! -f './libmoar.so' ]; then
  printf "Could not find 'libmoar.so' in this directory. Are you sure you're in the MoarVM build directory?\n"
  exit 1
fi
if [ "$2" == "-html" ]; then
  FILENAME="$RANDOM.html"
  faketty llvm-cov report -instr-profile "$1" ./libmoar.so | ansi2html > "$FILENAME" && printf "wrote file to '$FILENAME'\n" && exit 0
  printf "Something went wrong. Do you have ansi2html installed?"
  exit 1
fi
llvm-cov report -instr-profile "$1" ./libmoar.so && exit 0
printf "Reached the end but nothing happened. Please read project README.md\n"
#faketty llvm-cov report -instr-profile ../nqp/coverage/OUTPUT ./libmoar.so | ansi2html > "$RANDOM.html"
