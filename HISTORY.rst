=======
History
=======

1.011 (2022-11-03)
------------------

*  Issue s135: Add _filter_map

1.010 (2022-11-03)
------------------

* (no library changes)

1.009 (2022-10-31)
------------------

* issue s128: Added _readlink, FindBin, issue s129: Added _switch

1.008 (2022-10-26)
------------------

* (no library changes)

1.007 (2022-10-24)
------------------

* (no library changes)

1.006 (2022-10-23)
------------------

* (no library changes)

1.005 (2022-10-21)
------------------

* issue s124: perllib functions should return 1 or '', not True/False

1.004 (2022-10-19)
------------------

* issue s122: IO encoding shouldn't default to UTF-8

1.003 (2022-10-17)
------------------

* issue s121: localtime, gmtime, and timelocal shouldn't raise exceptions

1.002 (2022-10-11)
------------------

* issue s119: Sparse extraction from array doesn't give proper results

1.001 (2022-10-01)
------------------

* First production version (no changes from 0.994)

0.994 (2022-09-29)
------------------

* issue s94: add _unlink, don't set OS_ERROR in _exc (used for eval errors)

0.993 (2022-09-26)
------------------

* (no library changes)

0.992 (2022-09-24)
------------------

* issue s105: newline at end of filename gets stripped by perl - fix in _open_

0.991 (2022-09-23)
------------------

* (no library changes)

0.990 (2022-09-22)
------------------

* (no library changes)

0.989 (2022-09-15)
------------------

* (no library changes)

0.988 (2022-09-15)
------------------

* (no library changes)

0.987 (2022-09-14)
------------------

* (no library changes)

0.986 (2022-09-09)
------------------

* (no library changes)

0.985 (2022-09-08)
------------------

* issue s99: If you have more formats than items, you get an error in python but not perl - fix in _format_

0.984 (2022-09-08)
------------------

* (no library changes)

0.983 (2022-09-04)
------------------

* (no library changes)

0.982 (2022-09-02)
------------------

* (no library changes)

0.981 (2022-08-02)
------------------

* (no library changes)

0.980 (2022-07-28)
------------------

* (no library changes)

0.979 (2022-07-02)
------------------

* issue s91 - open with a dynamic single argument that does not contain a mode returns None on error instead of a closed file.  Fix in _open_dynamic.

0.978 (2022-05-12)
------------------

* _system, _run, and _run_s are now able to run perl and python scripts under windows

0.977 (2022-04-29)
------------------

* (no library changes)

0.976 (2022-04-28)
------------------

* Add _strftime

0.975 (2022-04-28)
------------------

* (no library changes)

0.974 (2022-04-21)
------------------

* _num(blessed object) shouldn't return 0, _bless needs to treat the result as a dict, not an object.  Change method name for IO_File.open to have a trailing underscore to match the name after escape_keywords.  Fix typo "fd" in _IOFile_open to "fh".  perllib.close renamed to have a trailing underscore so that fh.close() doesn't cause infinite recursion.

0.973 (2022-04-16)
------------------

* (no library changes)

0.972 (2022-04-15)
------------------

* add _set_breakpoint

0.971 (2022-04-12)
------------------

* Add _split_s for split in a scalar context.  Add _splitdir, _splitpath, _curdir, and _updir from File::Spec.  Add _isa.  Add __contains__ in File_stat.  Add _chdir and _rmdir.

0.970 (2022-04-10)
------------------

* (no library changes)

0.969 (2022-04-05)
------------------

* Add _readdirs to handle readdir in list context, fix _each to handle arrays properly.  Fix _lstat so it actually works.

0.968 (2022-04-01)
------------------

* Add _utime, fix _stat and friends to work on filehandles and dirhandles.  Add _abspath for Cwd::abs_path.

0.967 (2022-03-31)
------------------

* (no library changes)

0.966 (2022-03-20)
------------------

* Convert variable to string in _substitute_global, _substitute_element, _translate_global, and _translate_element.  Change _ref to handle object checks and add _refs to handle ref with \ to a scalar, array, or hash - not perfect but it's normally correct.  Add _bless and enable _init_package to handle classes.  Fix _list_of_n and _make_list if you pass it a single Hash().  Add _flt for specific conversions to float, like in math functions.  Implement select via _select.  Implement kill via _kill.

0.965 (2022-03-14)
------------------

* Change Config.Config to Config.Config_h and all Dumper variables to include _v suffix to match new package var mappings in Pythonizer.  Add _map_int, _map_num, _map_str.  Fix _flatten to handle multiple levels. Change _longmess traceback to return '()' for args if they were changed to a list and all popped off instead of '[]'.  Handle OUTPUT_FIELD_SEPARATOR and OUTPUT_RECORD_SEPARATOR in _perl_print.  Fix charnames.viacode to handle 'U+' or '0x' prefix.

0.964 (2022-03-10)
------------------

* Fix _init_package for package with dotted name, don't raise exceptions in -C, -A, -M, fix Array __setitem__ with slice

0.963 (2022-03-09)
------------------

* Add _chop_global, _chomp_global, _chop_element, _chomp_element

0.962 (2022-03-09)
------------------

* Hot fix for _fileinput_next - errors on Python older than v3.10

0.961 (2022-03-02)
------------------

* Handle open layer pragmas, fix issue with translate and friends with squash option, add dclone, catfile, file_name_is_absolute, Dumper, don't raise exception on double close

0.960 (2022-02-28)
------------------

* Speed up ArrayHash and Num. Have add_element and subtract_element handle non-numeric elements, turn subprocess shell=False on windows unless the command contains cmd shell chars or is a cmd built-in, fixup open of /tmp/... on windows to use the windows tempdir, don't pass effective_ids=True on windows.  Have concat_element auto-convert everything to strings.

0.959 (2022-02-24)
------------------

* str(ArrayHash()) changed to give '' instead of [], add EVAL_ERROR global variable, have ArrayHash() + or += work on empty value

0.958 (2022-02-23)
------------------

* Don't give a close failed error on a pipe which got automatically closed, give empty result for keys(), values(), and items() on a fresh ArrayHash instead of AttributeError

0.957 (2022-02-22)
------------------

* Add list_to_hash function to process key/value pairs

0.956 (2022-02-21)
------------------

* Implement all options of translate (tr///)

0.955 (2022-02-19)
------------------

* Fix split: A zero-width match at the beginning of EXPR never produces an empty field, fix bootstrapping issues

0.954 (2022-02-17)
------------------

* Add -n: trace run, fix issue of scalar being initialized as an array

0.953 (2022-02-15)
------------------

* First release on PyPI.
