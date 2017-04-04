#!/usr/bin/env sh
install_it () {
    NQP_FOLDER="../nqp"
    if [ "$MOAR_PREFIX" = "" ]; then
        MOAR_PREFIX="$(pwd)/moar-cover" || exit 1
        #export MOAR_PREFIX
        printf "MOAR_PREFIX env var not set, using '%s'\n" "$MOAR_PREFIX"
        export MOAR_PREFIX
    fi
    ./Configure.pl --compiler=clang --coverage --optimize=0 --debug=3 --prefix="$MOAR_PREFIX" || exit 1
    make install || exit
    cd "$NQP_FOLDER" || exit
    ./Configure.pl --prefix="$MOAR_PREFIX" --backends=moar || (NQP_RETURN="$?"; printf "NQP configure returned non-zero exit code(%s) exiting\n" "$NQP_RETURN"; exit "$NQP_RETURN")
    make || exit
    if [ ! -f nqp-profile ]; then echo "can't find nqp-profile"; exit 1; fi;
    if [ -e coverage ]; then mv -v coverage "coverage-$RANDOM" || exit 1; fi
    # RUNNING TESTS HERE
    DATE_VERSION_HEADER="$(printf "%s\n%s" "$(date --utc)" "$(./nqp --version 2> /dev/null)" )"
    printf "Starting tests\n%s\n" "$DATE_VERSION_HEADER"
    mkdir -p html || exit
    PROVE_CMD="$(make -n test | tail -n 1 | sed 's/nqp-m/nqp-profile/')"
    echo PROVE_CMD $PROVE_CMD
    eval "$PROVE_CMD"
    UNCLEAN_TEST=$?
    if [ ! -f merge-profraw.sh ]; then echo "Can't find merge-profraw.sh"; exit 1; fi
    ./merge-profraw.sh

    cd ../MoarVM || exit
}
install_it
# Fake tty so llvm-cov will output ANSI-color through a pipe
faketty () { script -qfc "$(printf "%q " "$@")"; }
# Generates ISO date format
isodate () { date -u +"%Y-%m-%dT%H:%M:%SZ"; }
# Filelist that is used for the coverage (variable not yet integrated)
filelist () { find src -name '*.c' | grep -v unicode.c; }

#echo $(filelist)
#exit;
if [ ! -f src/moar.c ]; then echo "You don't seem to be in the MoarVM folder. Can't see ./src/moar.c"; exit 1; fi
if [ -e "html" ]; then mv -v html "html-$RANDOM"; fi
llvm-cov show -format=html -instr-profile ../nqp/coverage/nqptestcov.profdata ./moar $(filelist) -output-dir=html
printf "_____________________________\nThere will be many errors above this line, and they are fine as long as there are about 10 or less below this line\n----------------------\n"
llvm-cov show -format=html -instr-profile ../nqp/coverage/nqptestcov.profdata ./libmoar.* $(filelist) -output-dir=html
mv html/index.html html/cov-index.html
if [ "$UNCLEAN_TEST" -gt 0 ]; then
    UNCLEAN_TEST_TXT="Unclean test, returned status $UNCLEAN_TEST"
fi
if [ "$(which ansi2html)" ]; then
    printf "$DATE_VERSION_HEADER\n$UNCLEAN_TEST_TXT\n\n%s\n" "$(faketty llvm-cov report -instr-profile ../nqp/coverage/nqptestcov.profdata ./moar $(filelist) )" | ansi2html > html/report-moar.html && \
        printf "Done creating html/report-moar.html\n"
    printf "$DATE_VERSION_HEADER\n$UNCLEAN_TEST_TXT\n\n%s\n" "$(faketty llvm-cov report -instr-profile ../nqp/coverage/nqptestcov.profdata ./libmoar.* $(filelist) )" | ansi2html > html/report-libmoar.html && \
        printf "Done creating html/report-libmoar.html\n"
else
    printf "Could not find ansi2html, so not able to output cov-index.html\n"
fi

exit $UNCLEAN_TEST
# scp -r ./html/* root@cry.nu:/srv/cry.nu/coverage/
