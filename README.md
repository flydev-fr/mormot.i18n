# mORMot v2 i18n

## About

Internationalization (i18n) routines and classes for mORMot v2.2.

- This unit is adapted from the Synopse mORMot framework version 1.18 to work with mORMot v2.2.
- This file is not officially part of the Synopse mORMot 2 Framework.
- It is open source and follows the mORMot MPL/GPL/LGPL tri-license.

It's an experiment made after receiving an answer from ab on [this post](https://synopse.info/forum/viewtopic.php?id=6891). 

## Notes

Reminder: Your language text file must be either:
- In WinAnsi / 1252 code page
- UTF-8 encoded with BOM

It works only on the Windows platform and can be compiled with Delphi. Tested on Delphi IDE v12 (Athens).

`PUREMORMOT2` is defined.

If you compile the project for x64 CPUs, `PUREPASCAL` is defined, and no enhanced runtime is used. For more information, see [mORMoti18n reference L1036-L1245](https://github.com/synopse/mORMot/blob/master/SQLite3/mORMoti18n.pas#L1036-L1245).

This repository will be archived once official support for the framework is available. To help with this, consider [adopting a mORMot](https://github.com/synopse/mORMot2/blob/master/DONATE.md) :)

## Samples

You can find a basic VCL form sample loading available languages to the menu and/or combobox.
There is also a modified mvc-blog application included.
