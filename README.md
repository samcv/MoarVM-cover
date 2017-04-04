# MoarVM line based/function based coverage reporting
You can also [go here](https://cry.nu/coverage/) to see the generated output from
the last time I have ran it, which reports on the NQP test suite coverage.
Unlike [the other coverage reporter](perl6.wtf), which reports line based coverage
of **Perl 6** itself, this reports coverage of the underlying Moar virtual machine.

It is planned to also automate coverage based reporting of the roast test suite
as well.

## Instructions
### Dependencies
* `llvm-cov` and `clang` (hard dependency)
    * If you already have clang, you probably already have `llvm-cov`
* `ansi2html` (soft dependency)
    * For the line based reporting, `llvm-cov` natively can output as html. But for
      the file and function based coverage reporting, we use `ansi2html` to convert
      the color output of `llvm-cov` to html.
    * If you don't have it, it will generate the line based coverage and just not
      create the function based and file based one.

### Info
* [`report-libmoar.html`](https://cry.nu/coverage/report-libmoar.html) details stats of files
  that are included in the `libmoar.so`, which is to the best of my knowledege, everything but `main.c`
* [`report-moar.html`](https://cry.nu/coverage/report-moar.html) details of `moar` binary, which
  is only `main.c` (so most files show no coverage except this one)


## Generating it yourself
After reading the dependencies above, make sure your directory structure has
this repo, nqp MoarVM all on the same level. It is not strictly required for
MoarVM-cover to be on the same level as long as you adjust the `ln -s`
commands below, but the script does rely on nqp and MoarVM being on the same
level (also this is the only situation I am testing).
```
$ ls
MoarVM
MoarVM-cover
nqp
```
If you want to install MoarVM into a specific place, set the MOAR_PREFIX env variable,
otherwise it will build its own MoarVM in `MoarVM/moar-cover` (may be a good idea if you don't
want to disrupt your existing installation).

* Run:
```
cd nqp
# Make sure you are in the nqp repo directory then run:
ln -s ../MoarVM-cover/nqp-profile
ln -s ../MoarVM-cover/merge-profraw.sh
cd ../MoarVM
ln -s ../MoarVM-cover/html-cover.sh
```
Now you are ready to run the fully automated *super awesome* html-cover.sh script!
```
./html-cover.sh
```
This will generate line by line html coverage report as well as stats for each function.
It will generate into the html directory of MoarVM
