#!/usr/bin/env bash
# Fake tty so llvm-cov will output ANSI-color through a pipe
faketty () { script -qfc "$(printf "%q " "$@")"; }
# Generates ISO date format
isodate () { date -u +"%Y-%m-%dT%H:%M:%SZ"; }
find_latest_version () { ls /usr/bin | grep -Ee "^$1(\-[0-9.]+)?$" | sort -r | head -n 1; }

HTML="html-cov"
check_prefix () {
    if [ ! -f src/moar.c ]; then echo "You don't seem to be in the MoarVM folder. Can't see ./src/moar.c"; exit 1; fi
    if [ "$MOAR_PREFIX" = "" ]; then
        MOAR_PREFIX="$(pwd)/moar-cover" || exit 1
        printf "MOAR_PREFIX env var not set, using '%s'\n" "$MOAR_PREFIX"
        export MOAR_PREFIX
    fi
    if [ "$MOAR_FOLDER" = "" ]; then
        MOAR_FOLDER="$(readlink -f .)"
        export MOAR_FOLDER
    fi

}
nqp_folder () {
    if [ ! "$NQP_FOLDER" ]; then NQP_FOLDER="../nqp"; fi
}
# stage_1 compiles MoarVM and NQP
stage_1 () {
    check_prefix
    nqp_folder
    ./Configure.pl --compiler=clang --coverage --optimize=0 --debug=3 --prefix="$MOAR_PREFIX" || exit 1
    make install || exit
    cd "$NQP_FOLDER" || exit 1
    ./Configure.pl --prefix="$MOAR_PREFIX" --backends=moar || (NQP_RETURN="$?"; printf "NQP configure returned non-zero exit code(%s) exiting\n" "$NQP_RETURN"; exit "$NQP_RETURN")
    make || exit
    cd ../MoarVM || exit 1
}
# Stage 2 runs the nqp test suite, collecting test data. It then merges
# this test data into a single processed file
stage_2 () {
    check_prefix
    nqp_folder
    cd "$NQP_FOLDER" || exit 1
    if [ ! -f nqp-profile ]; then echo "can't find nqp-profile"; exit 1; fi;
    if [ -e coverage ]; then mv -v coverage "coverage-$RANDOM" || exit 1; fi
    # RUNNING TESTS HERE
    DATE_VERSION_HEADER="$(printf "%s\n%s" "$(date --utc)" "$(./nqp --version 2> /dev/null)" )"
    printf "Starting tests\n%s\n" "$DATE_VERSION_HEADER"
    mkdir -p "$HTML" || exit 1
    PROVE_CMD="$(make -n test | tail -n 1 | sed 's/nqp-m/nqp-profile/')"
    echo PROVE_CMD $PROVE_CMD
    eval "$PROVE_CMD"
    UNCLEAN_TEST=$?
    if [ ! -f merge-profraw.sh ]; then echo "Can't find merge-profraw.sh"; exit 1; fi
    ./merge-profraw.sh

    cd ../MoarVM || exit
}
# Stage 3 generates the html pages
stage_3 () {
    check_prefix
    if [ ! "$DATE_VERSION_HEADER" ]; then DATE_VERSION_HEADER="$(printf "%s\n%s" "$(date --utc)" "$(cd ../nqp; ./nqp --version 2> /dev/null)" )"; fi
    #PROFDATA='../rakudo/coverage/t/nqptestcov.profdata'
    PROFDATA='../nqp/coverage/nqptestcov.profdata'
    # Filelist that is used for the coverage
    # main.c is in the `moar` binary. unicode.c is tens of thousands of lines long and
    # because of this is not included right now
    llvm_cov=$(find_latest_version llvm-cov)
    if [ ! "$llvm_cov" ]; then
        echo "Didn't find llvm-cov in /usr/bin hoping it's in your path";
        llvm_cov=llvm-cov;
    fi
    filelist_libmoar () { $llvm_cov report -instr-profile $PROFDATA ./libmoar.* | tail -n +3 | head -n -3 | cut -d ' ' -f 1 | grep -v 3rdparty; }
    # We will generate the output of all the moar binary files just in case they change from main.c
    # or if under other distros there's extra files included
    filelist_moar_bin () { $llvm_cov report -instr-profile $PROFDATA ./moar | tail -n +3 | head -n -3 | cut -d ' ' -f 1 | grep -v 3rdparty; }
    if [ ! -f "$PROFDATA" ]; then printf "Could not find $PROFDATA\n"; exit 1; fi
    if [ -e "$HTML" ]; then mv -v $HTML "$HTML-$RANDOM"; fi
    $llvm_cov show -format=html -instr-profile $PROFDATA ./moar $(filelist_moar_bin) -output-dir="$HTML/moar"
    $llvm_cov show -format=html -instr-profile $PROFDATA ./libmoar.* $(filelist_libmoar) -output-dir="$HTML/libmoar"
    # If env var isn't set then we must be running stage_3 by itself, so set it to 0
    # to not cause an error when we check it numerically
    if [ "$UNCLEAN_TEST" = "" ]; then UNCLEAN_TEST=0; fi
    if [ "$UNCLEAN_TEST" -gt 0 ]; then
        UNCLEAN_TEST_TXT="Unclean test, returned status $UNCLEAN_TEST"
    fi
    # Old code not needed with LLVM 5, but maybe helpful on those on lower versions
    #if [ "$(which ansi2html)" ]; then
    #    printf "$DATE_VERSION_HEADER\n$UNCLEAN_TEST_TXT\n\n%s\n" "$(faketty llvm-cov report -instr-profile $PROFDATA ./moar $(filelist_moar_bin) )" | ansi2html > "$HTML/report-moar.html" && \
    #        printf "Done creating html/report-moar.html\n"
    #    printf "$DATE_VERSION_HEADER\n$UNCLEAN_TEST_TXT\n\n%s\n" "$(faketty llvm-cov report -instr-profile $PROFDATA ./libmoar.* $(filelist_libmoar) )" | ansi2html > "$HTML/report-libmoar.html" && \
    #        printf "Done creating html/report-libmoar.html\n"
    #else
    #    printf "Could not find ansi2html, so not able to output function based reporting\n"
    #fi

    exit $UNCLEAN_TEST
}
echo $1
case "$1" in
    JUST1) stage_1; exit;;
    JUST2) stage_2; exit;;
    JUST3) stage_3; exit ;;
    "") stage_1; stage_2; stage_3;;
    1) stage_1; stage_2; stage_3;;
    2) stage_2; stage_3;;
    3) stage_3;;
    *) printf "Unknown option '$1' only know 1 2 and 3 for starting from 1st stage(default), 2nd stage or 3rd stage\n"; exit 1;;
esac

stage_1
stage_2
stage_3

# scp -r ./html/* root@cry.nu:/srv/cry.nu/coverage/
