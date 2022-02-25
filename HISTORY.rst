=======
History
=======

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
