
def _tie_call(func, _args, _kwargs=None):
    """Call a function in a package that uses TIEARRAY or TIEHASH.  This is an
    internal routine whose call is automatically generated."""
    # This is needed to "undo" what _add_tie_methods does to a class that has TIEARRAY or TIEHASH.
    # That function creates a subclass which is used as the object's class returned from TIEARRAY or
    # TIEHASH which defines the python special methods like __getitem__ and __setitem__ to call
    # FETCH and STORE respectively.  However, inside the class that defines TIEARRAY or TIEHASH,
    # we don't want indexing and other basic operations to call these special methods, so we temporarily
    # change the type of the object to it's base type, then do the call, then restore it.
    if _kwargs is None:
        _kwargs = dict()
    try:
        self = _args[0]
        tie_class = self.__class__
        orig_class = tie_class.__bases__[0]
        if(hasattr(orig_class, '__TIE_subclass__')):
            self.__class__ = orig_class
    except Exception:   # e.g. we have no args, or self is a string or something
        return func(*_args, **_kwargs)
    try:
        # Call the function with the class of 'self' reset to the parent class
        # which doesn't have __getitem__ etc defined
        return func(*_args, **_kwargs)
    finally:
        try:
            self.__class__ = tie_class
        except Exception:   # e.g. self is a string or something
            pass
