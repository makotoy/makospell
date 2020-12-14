# makospell

Aspell bridge for Mac OS X

This project aims to provide a way to use GNU Aspell spellchecker from applications in Mac OS X.

## How to build

The project requires aspell library (`libaspell.dylib`) and aspell data files.
As for the library, there are two ways:

1. Put aspell source codes under `external-libs` directory.
2. Change Xcode reference to existing aspell library.

As for the data files, if you have aspell already, it is possible to use the installed files via `~/.aspell.config`.

### Compiling Aspell library from source

By default, the Xcode project contains a reference to `external-libs/aspell-0.60.8/.libs/libaspell.15.dylib`.
Follow these steps to build this file:

1. Download aspell source from [Aspell website](http://aspell.net/) (current version is 0.60.6.1).
2. Place the directory `aspell-0.60.8` inside `external-libs`.
   This directory has `.gitignore` so that the aspell directory is not synced by git.
3. `cd` to `aspell-0.60.8` directory and do

        $ ./configure --enable-compile-in-filters
        $ make
        $ install_name_tool -id @rpath/libaspell.15.dylib libaspell.15.dylib
4. `cd` to `external-libs` and do

        $ mkdir -p dict/data
        $ cp aspell-0.60.6.1/data/* dict/data/

This should compile the library file `libaspell.dylib` in `aspell-0.60.8/.libs` directory.

#### Tips for compling Aspell command

This is not required for building the project, but you might still want to install the standalone `aspell` utility.
You need `--enable-compile-in-filters` flag for `configure` script to build in filters such as `tex` and `email` (modes seem to be broken in Aspell 0.60).
Use the following commands to install `aspell` command under your home directory.
These also install library and header files.

    $ ./configure --prefix=${HOME} --enable-compile-in-filters
    $ make
    $ make install

Then create config file `~/.aspell.conf`.
Here is an sample:

    lang en_US
    dict-dir path/to/aspell6-en-2016.11.20-0
    data-dir /path/to/aspell-0.60
    home-dir /path/to/home-dir
    personal en.pws
    add-filter tex
    add-tex-command rightarrow o
    tex-check-comments true
    encoding utf-8

* `dict-dir` is the directory containing `.cwl`, `.rws`, `.multi`, `.alias` files.
* `data-dir` is the directory containing `.cset` and `.cmap` files.
  This is `external-libs/aspell-0.60.6.1/data` in the project directory, but `make install` (see next section) will install it under `${PREFIX}/lib`.
* `home-dir` is the directory containing the personal word list file `en.pws`.
* `encoding` needs to be `utf-8`, as we need to assume that only Unicode can represent the possible input (such as non-breaking space) from Mac OS X.

You can set `MYSpellCheckerAspellConf` environment variable to use different config file.
See [this Stack Overflow thread](http://stackoverflow.com/questions/25385934/setting-environment-variables-via-launchd-conf-no-longer-works-in-os-x-yosemite/26586170#26586170) for how to set environment variables at login.

### Compiling dictionaries

You then need to prepare word lists.

1. Download dictionary files from Aspell FTP directory ftp://ftp.gnu.org/gnu/aspell/dict/0index.html.
2. Put the directory, say, `aspell6-en-2016.11.20-0` in `external-libs`.
   This directory is again listed in `.gitignore`, but you might want to update it if there there is an update.
3. If you already have `.aspell.conf` file, temporarily rename it to something else.
4. cd to `aspell6-en-2016.11.20-0` and do

        $ PROJ_DIR=/path/to/proj; ./configure --vars DESTDIR=${PROJ_DIR}/external-libs/dict/ ASPELL_FLAGS="--per-conf=${PROJ_DIR}/external-libs/aspell.en.dict-compile.conf --data-dir=${PROJ_DIR}/external-libs/aspell-0.60.6.1/data" ASPELL="$( which aspell ) --per-conf=${PROJ_DIR}/external-libs/aspell.en.dict-compile.conf"
        $ make
        $ make install

This should install English dictionary files under `external-libs/dict/en`.
Then repeat the same for French and German dictionaries.
However, the configure script for French is missing a line to process options, so copy the modified one from `external-libs` first.

    $ cp /path/to/proj/external-libs/configure-fr /path/to/proj/external-libs/aspell-fr-0.50-3
    $ PROJ_DIR=/path/to/proj; ./configure-fr --vars DESTDIR=${PROJ_DIR}/external-libs/dict/ ASPELL_FLAGS="--per-conf=${PROJ_DIR}/external-libs/aspell.fr.dict-compile.conf --data-dir=${PROJ_DIR}/external-libs/aspell-0.60.6.1/data" ASPELL="$( which aspell ) --per-conf=${PROJ_DIR}/external-libs/aspell.fr.dict-compile.conf"

### Referencing existing Aspell library

Alternatively, you might already have Aspell (say, from Cocoaspell utility).
You can just change the libaspell.dylib reference in Xcode project to that copy.

## How to install

After building MakoSpellChecker target in Xcode project, you should see MakoSpellChecker.service.
Copy this bundle to `~/Library/Services`.
