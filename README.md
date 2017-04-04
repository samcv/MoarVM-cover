Make sure your directory structure has this repo, nqp MoarVM all on the same level. It is not strictly required for MoarVM-cover to be on the same level as long as you adjust the `ln -s` commands below, but the script does rely on nqp and MoarVM being on the same level.
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
