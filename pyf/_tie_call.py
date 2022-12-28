
def _tie_call(func, _args):
    """Call a function in a package that uses TIEARRAY or TIEHASH.  This is an
    internal routine whose call is automatically generated."""
    try:
        self = _args[0]
        tie_class = self.__class__
        orig_class = tie_class.__bases__[0]
        if(hasattr(orig_class, '__TIE_subclass__')):
            self.__class__ = orig_class
    except Exception:   # e.g. we have no args, or self is a string or something
        return func(*_args)
    try:
        # Call the function with the class of 'self' reset to the parent class
        # which doesn't have __getitem__ etc defined
        return func(*_args)
    finally:
        self.__class__ = tie_class
