Compile and install MoarVM normally, or if it's already installed you can skip this step.

Now go into the nqp folder and run `./Configure.pl --prefix="$MOAR_PREFIX"` and then
`make`. We want to compile nqp before we use our special coverage build for MVM.
Once it's compiled nqp:

* Run:
```
# Make sure you are in the nqp repo directory then run:
ln -s ../MoarVM-cover/nqp-profile
ln -s ../MoarVM-cover/merge-profraw.sh
```

* `export MOAR_PREFIX="$HOME/perl6/"` or your prefix of choice. This will be used by the nqp-profile executable.

Now compile MoarVM with these options:
`Configure.pl --compiler=clang --coverage --optimize=0 --debug=3 --prefix="$MOAR_PREFIX"`

Now that it's made go back into the nqp folder and run this to get the `make test` command:
```bash
make -n test | tail -n 1
```
OUTPUT: `prove -r --exec "./nqp-m" t/nqp t/hll t/qregex t/p5regex t/qast t/moar t/serialization t/nativecall`
Now replace `./nqp-profile` in the above command.

Run the command with the nqp executable's name substituted:

`prove -r --exec "./nqp-profile" t/nqp t/hll t/qregex t/p5regex t/qast t/moar t/serialization t/nativecall`

This will create a bunch of coverage files in a folder called `coverage`. Now you want to run `merge-profraw.sh` which will combine all of these profiles into one. It would output a file called `nqptestcov.profdata`

Now go to the folder where MoarVM was compiled (the coverage version). Now you can link the `show.sh` script similar to how you did the other ones:
```
# make sure you are in the MoarVM repo directory then run
ln -s ../Moar-cover/report.sh
```