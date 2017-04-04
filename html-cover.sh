#!/usr/bin/env bash
# Fake tty so llvm-cov will output ANSI-color through a pipe
faketty () { script -qfc "$(printf "%q " "$@")"; }
# Generates ISO date format
isodate () { date -u +"%Y-%m-%dT%H:%M:%SZ"; }

check_prefix () {
    if [ ! -f src/moar.c ]; then echo "You don't seem to be in the MoarVM folder. Can't see ./src/moar.c"; exit 1; fi
    if [ "$MOAR_PREFIX" = "" ]; then
        MOAR_PREFIX="$(pwd)/moar-cover" || exit 1
        #export MOAR_PREFIX
        printf "MOAR_PREFIX env var not set, using '%s'\n" "$MOAR_PREFIX"
        export MOAR_PREFIX
    fi

}
stage_1 () {
    check_prefix
    NQP_FOLDER="../nqp"
    ./Configure.pl --compiler=clang --coverage --optimize=0 --debug=3 --prefix="$MOAR_PREFIX" || exit 1
    make install || exit
    cd "$NQP_FOLDER" || exit 1
    ./Configure.pl --prefix="$MOAR_PREFIX" --backends=moar || (NQP_RETURN="$?"; printf "NQP configure returned non-zero exit code(%s) exiting\n" "$NQP_RETURN"; exit "$NQP_RETURN")
    make || exit
    cd ../MoarVM || exit 1
}
stage_2 () {
    check_prefix
    cd ../nqp || exit 1
    if [ ! -f nqp-profile ]; then echo "can't find nqp-profile"; exit 1; fi;
    if [ -e coverage ]; then mv -v coverage "coverage-$RANDOM" || exit 1; fi
    # RUNNING TESTS HERE
    DATE_VERSION_HEADER="$(printf "%s\n%s" "$(date --utc)" "$(./nqp --version 2> /dev/null)" )"
    printf "Starting tests\n%s\n" "$DATE_VERSION_HEADER"
    mkdir -p html || exit 1
    PROVE_CMD="$(make -n test | tail -n 1 | sed 's/nqp-m/nqp-profile/')"
    echo PROVE_CMD $PROVE_CMD
    eval "$PROVE_CMD"
    UNCLEAN_TEST=$?
    if [ ! -f merge-profraw.sh ]; then echo "Can't find merge-profraw.sh"; exit 1; fi
    ./merge-profraw.sh

    cd ../MoarVM || exit
}
stage_3 () {
    check_prefix
    if [ ! "$DATE_VERSION_HEADER" ]; then DATE_VERSION_HEADER="$(printf "%s\n%s" "$(date --utc)" "$(cd ../nqp; ./nqp --version 2> /dev/null)" )"; fi

    # Filelist that is used for the coverage
    # main.c is in the `moar` binary. unicode.c is tens of thousands of lines long and
    # because of this is not included right now
    filelist_libmoar () { llvm-cov report -instr-profile ../rakudo/coverage/t/nqptestcov.profdata ./libmoar.* | tail -n +3 | head -n -3 | cut -d ' ' -f 1 | grep -v 3rdparty; }
    # We will generate the output of all the moar binary files just in case they change from main.c
    # or if under other distros there's extra files included
    filelist_moar_bin () { llvm-cov report -instr-profile ../rakudo/coverage/t/nqptestcov.profdata ./moar | tail -n +3 | head -n -3 | cut -d ' ' -f 1 | grep -v 3rdparty; }
    if [ ! -f "../nqp/coverage/nqptestcov.profdata" ]; then printf "Could not find ../nqp/coverage/nqptestcov.profdata\n"; exit 1; fi
    if [ -e "html" ]; then mv -v html "html-$RANDOM"; fi
    llvm-cov show -format=html -instr-profile ../nqp/coverage/nqptestcov.profdata ./moar $(filelist_moar) -output-dir=html
    printf "_____________________________\nThere will be many errors above this line, and they are fine as long as there are about 10 or less below this line\n----------------------\n"
    llvm-cov show -format=html -instr-profile ../nqp/coverage/nqptestcov.profdata ./libmoar.* $(filelist_libmoar) -output-dir=html
    mv html/index.html html/cov-index.html
    # If env var isn't set then we must be running stage_3 by itself, so set it to 0
    # to not cause an error when we check it numerically
    if [ "$UNCLEAN_TEST" = "" ]; then UNCLEAN_TEST=0; fi
    if [ "$UNCLEAN_TEST" -gt 0 ]; then
        UNCLEAN_TEST_TXT="Unclean test, returned status $UNCLEAN_TEST"
    fi
    if [ "$(which ansi2html)" ]; then
        printf "$DATE_VERSION_HEADER\n$UNCLEAN_TEST_TXT\n\n%s\n" "$(faketty llvm-cov report -instr-profile ../nqp/coverage/nqptestcov.profdata ./moar $(filelist_moar_bin) )" | ansi2html > html/report-moar.html && \
            printf "Done creating html/report-moar.html\n"
        printf "$DATE_VERSION_HEADER\n$UNCLEAN_TEST_TXT\n\n%s\n" "$(faketty llvm-cov report -instr-profile ../nqp/coverage/nqptestcov.profdata ./libmoar.* $(filelist_libmoar) )" | ansi2html > html/report-libmoar.html && \
            printf "Done creating html/report-libmoar.html\n"
    else
        printf "Could not find ansi2html, so not able to output cov-index.html\n"
    fi

    exit $UNCLEAN_TEST
}
echo $1
case "$1" in
    JUST1) stage_1; exit;;
    JUST2) stage_2; exit;;
    JUST3) stage_3; exit ;;
    "") ;&
    1) stage_1;&
    2) stage_2;&
    3) stage_3;&
    *) printf "Unknown option '$1' only know 1 2 and 3 for starting from 1st stage(default), 2nd stage or 3rd stage\n"; exit 1;;
esac

stage_1
stage_2
stage_3

#echo $(filelist)
#exit;

# scp -r ./html/* root@cry.nu:/srv/cry.nu/coverage/
