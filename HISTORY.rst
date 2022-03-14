=======
History
=======

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
