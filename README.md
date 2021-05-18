

Command/function `extract` in your console
=================================

What’s a good way to extract: .zip, .rar, .bz2, .gz, .tar, .tbz2, .tgz, .Z, .7z, .xz, .exe, .tar.bz2, .tar.gz, .tar.xz, .arj, .cab, .chm, .deb, .dmg, .iso, .lzh, .msi, .rpm, .udf, .wim, .xar .cpio .cbr, .cbz, .cb7, .cbt, .cba, .apk, .zpaq, .arc, .ciso files on the Mac or Linux?

The goal is to make `extract` able to extract anything you give it. The command `extract` uses the free unpackers to support many older, obscure formats like this: .zip, .rar, .bz2, .gz, .tar, .tbz2, .tgz, .Z, .7z, .xz, .exe, .tar.bz2, .tar.gz, .tar.xz, .arj, .cab, .chm, .deb, .dmg, .iso, .lzh, .msi, .rpm, .udf, .wim, .xar .cpio, .cbr, .cbz, .cb7, .cbt, .cba, .apk, .zpaq, .arc, .ciso

And more: run `extract -h` for a list.
It can be that an extension is not supported, but 7zip supports extracting that file type.


How to install
-------------------------

Execute it anywhere via ./extract.sh (or put it anywhere in PATH)

### macOS / OSX / Mac OS X
Copy&Paste function into file `~/.bash_profile`

### Ubuntu / *nix
Copy&Paste function into file `~/.bashrc`


How to use
----------

Using command `extract`, in a terminal

```
$ extract <archive_filename.extention>

$ extract <archive_filename_1.extention> <archive_filename_2.extention> <archive_filename_3.extention> ...
```

License
-------
Author [Vitalii Tereshchuk](http://dotoca.net). &copy; 2013-2020, MIT license.
Author Stdedos <133706+stdedos@users.noreply.github.com> &copy; 2020-2021, MIT license.
