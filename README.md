# makospell

Aspell bridge for Mac OS X

This project aims to provide a way to use GNU Aspell spellchecker from applications in Mac OS X.

## How to build

The project requires aspell library (`libaspell.dylib`). There are two ways:

1. Put aspell source codes under `external-libs` directory.
2. Change Xcode reference to existing aspell library.

### Compiling Aspell library from source

By default, the Xcode project contains a reference to `external-libs/aspell-0.60.6.1/.libs/libpspell.dylib`.
Follow these steps to build this file:

1. Download aspell source from [Aspell website](http://aspell.net/) (current version is 0.60.6.1).
2. Place the directory `aspell-0.60.6.1` inside `external-libs`.
   This directory has `.gitignore` so that the aspell directory is not synced by git.
3. In order to sucessfuly build Aspell, you need to copy `aspell.h` file in `external-libs` to `aspell-0.60.6.1/interfaces/cc`.
4. `cd` to `aspell-0.60.6.1` directory and do

        $ ./configure
        $ make

which should compile the library file `libaspell.dylib` in `aspell-0.60.6.1/.libs` directory.

You then need to prepare word lists.

1. Download dictionary files from Aspell FTP directory ftp://ftp.gnu.org/gnu/aspell/dict/0index.html.
2. Put the directory, say, `aspell6-en-2016.11.20-0` in `external-libs`.
3. `cd` to `aspell6-en-2016.11.20-0` and do

        $ ./configure
        $ make

You might get encoding error, but the word list should be created anyhow.

Then create config file `~/.aspell.conf` for Aspell.
Here is an sample:

    lang en_US
    dict-dir path/to/aspell6-en-2016.11.20-0
    data-dir /Users/foo/lib/aspell-0.60
    home-dir /Users/foo/Library/Preferences/cocoAspell/
    personal en.pws
    add-filter tex
    add-tex-command rightarrow o
    tex-check-comments true
    encoding utf-8

* `dict-dir` is the directory containing `.cwl`, `.rws`, `.multi`, `.alias` files.
* `data-dir` is the directory containing `.cset` and `.cmap` files.
  This is `external-libs/aspell-0.60.6.1/data` in the project directory, but `make install` (see next section) will install it under `${PREFIX}/lib`.
* `home-dir` is the directory containing the personal word list file `en.pws`.

#### Tips for compling Aspell command

You do not have to install Aspell command for this project itself, but you might want it separately.
You need `--enable-compile-in-filters` flag for `configure` script to build in filters such as `tex` and `email` (modes seem to be broken in Aspell 0.60).
Use the following commands to install `aspell` command under your home directory.
These also install library and header files.

    $ ./configure --prefix=${HOME} --enable-compile-in-filters
    $ make
    $ make install

### Referencing existing Aspell library

Alternatively, you might already have Aspell (say, from Cocoaspell utility).
You can just change the libaspell.dylib reference in Xcode project to that copy.

## How to install

After building MakoSpellChecker target in Xcode project, you should see MakoSpellChecker.service.
Copy this bundle to `~/Library/Services`.
