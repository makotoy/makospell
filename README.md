# makospell

An aspell bridge for Mac OS X

This project aims to provide a way to use GNU Aspell spellchecker from applications in Mac OS X.

## How to build

The project requires aspell library (`libaspell.dylib`). There are two ways:

1. Put aspell source codes under `external-libs` directory.
2. Change Xcode reference to existing aspell library.

### Compiling Aspell library from source

By default, the Xcode project contains a reference to `external-libs/aspell-0.60.6.1/.libs/libpspell.dylib`.
In order to build this file, you first need to download aspell source from [Aspell website](http://aspell.net/) (current version is 0.60.6.1).
Then place the directory `aspell-0.60.6.1` inside `external-libs`.
This directory has `.gitignore` so that the aspell directory is not synced by git.
In order to sucessfuly configure aspell for building, you need to copy `aspell.h` file in `external-libs` to `aspell-0.60.6.1/interfaces/cc`.
Then `cd` to `aspell-0.60.6.1` directory and do

    $ ./configure
    $ make

which should compile the library file `libaspell.dylib` in `aspell-0.60.6.1/.libs` directory.

### Referencing existing Aspell library

Alternatively, you might already have Aspell (say, from Cocoaspell utility).
You can just change the libaspell.dylib reference in Xcode project to that copy.

## How to install

After building MakoSpellChecker target in Xcode project, you should see MakoSpellChecker.service.
Copy this bundle to `~/Library/Services`.
