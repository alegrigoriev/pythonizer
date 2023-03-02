
def _add_tie_methods(obj):
    """Create a subclass for the object and add the methods to it to implement 'tie', like __getitem__ etc.  The call to this functions is generated on any 'return' statement (or implicit return) in TIEHASH or TIEARRAY"""
    try:
        cls = obj.__class__
    except Exception:       # Not an object, so just ignore
        return obj
    is_scalar = is_hash = is_array = False
    if hasattr(cls, 'TIESCALAR'):
        is_scalar = True
    if hasattr(cls, 'TIEARRAY'):
        is_array = True
    if hasattr(cls, 'TIEHASH'):
        is_hash = True
    if not is_array and not is_hash and not is_scalar:
        return obj
    elif hasattr(cls, '__TIE_subclass__'):
        obj.__class__ = cls.__TIE_subclass__
        return obj

    classname = cls.__name__
    result = type(classname, (cls,), Hash() if hasattr(cls, 'isHash') else dict())

    if is_scalar:
        def __get__(self, obj, objtype=None):
            return self.FETCH()
        result.__get__ = __get__
        def __set__(self, obj, value):
            return self.STORE(value)
        result.__set__ = __set__
        if hasattr(result, 'DELETE'):
            setattr(result, _TIE_MAP['DELETE'], getattr(result, 'DELETE'))
        if hasattr(result, 'UNTIE'):
            setattr(result, _TIE_MAP['UNTIE'], getattr(result, 'UNTIE'))
        else:
            setattr(result, _TIE_MAP['UNTIE'], lambda self: None)
        cls.__TIE_subclass__ = result
        obj.__class__ = result
        return obj

    for m, p in _TIE_MAP.items():
        if hasattr(result, m):
            setattr(result, p, getattr(result, m))
        elif p != '__del__' and p != '__len__':    # Don't define __del__ unless they define DELETE, __len__ could be SCALAR or FETCHSIZE
            setattr(result, p, eval(f'lambda *_args: _raise(Die(\'Can\\\'t locate object method "{m}" via package "{classname}"\'))'))

    if not hasattr(result, 'SCALAR') and not hasattr(result, 'FETCHSIZE'):
        setattr(result, _TIE_MAP['SCALAR'], eval(f'lambda *_args: _raise(Die(\'Can\\\'t locate object method SCALAR or FETCHSIZE via package "{classname}"\'))'))

    # Always generate an __untie__ method unless we generated it above
    if not hasattr(result, 'UNTIE'):
        setattr(result, _TIE_MAP['UNTIE'], lambda self: None)

    result.__bool__ = lambda self: True

    if is_array:
        if hasattr(result, 'POP') and hasattr(result, 'SHIFT'):
            result.pop = lambda *_args: _args[0].POP() if len(_args) == 1 else _args[0].SHIFT()
        else:
            def pop(self, ndx=-1):
                result = self.FETCH(ndx)
                self.DELETE(ndx)
                return result
            setattr(result, 'pop', pop)

        result.extend = lambda self, lst: [self.PUSH(l) for l in lst]

        def __iter__(self):
            for i in range(self.SCALAR() if hasattr(self, 'SCALAR') else self.FETCHSIZE()):
                yield self.FETCH(i)
        result.__iter__ = __iter__
        cls.__TIE_subclass__ = result

    if is_hash:
        if is_array:
            def __iter__(self):
                if self.isHash:
                    current_key = self.FIRSTKEY()
                    # Handle FIRSTKEY being implemented using each
                    if isinstance(current_key, collections.abc.Sequence) and not isinstance(current_key, str):
                        if len(current_key) == 0:
                            current_key = None
                        else:
                            current_key = current_key[0]
                    while current_key is not None:
                        yield current_key
                        current_key = self.NEXTKEY()
                        if isinstance(current_key, collections.abc.Sequence) and not isinstance(current_key, str):
                            if len(current_key) == 0:
                                current_key = None
                            else:
                                current_key = current_key[0]
                else:
                    for i in range(self.SCALAR() if hasattr(self, "SCALAR") else self.FETCHSIZE()):
                        yield self.FETCH(i)
            result.__iter__ = __iter__

        else:
            def __iter__(self):
                current_key = self.FIRSTKEY()
                # Handle FIRSTKEY being implemented using each
                if isinstance(current_key, collections.abc.Sequence) and not isinstance(current_key, str):
                    if len(current_key) == 0:
                        current_key = None
                    else:
                        current_key = current_key[0]
                while current_key is not None:
                    yield current_key
                    current_key = self.NEXTKEY()
                    if isinstance(current_key, collections.abc.Sequence) and not isinstance(current_key, str):
                        if len(current_key) == 0:
                            current_key = None
                        else:
                            current_key = current_key[0]
            result.__iter__ = __iter__

        if is_array:
            def pop(*args):
                self = args[0]
                if len(args) == 1:
                    key = -1
                else:
                    key = args[1]
                if isinstance(key, int):    # Array style
                    result = self.FETCH(key)
                    self.DELETE(key)
                    return result
                if not self.EXISTS(key):    # Hash style
                    if len(args) >= 2:
                        return args[2]  # default
                    return None # default default
                return self.DELETE(key)
            result.pop = pop
        else:
            def pop(self, key, default=None):
                if not self.EXISTS(key):
                    return default
                return self.DELETE(key)
            result.pop = pop

        def get(self, key, default=None):
            if not self.EXISTS(key):
                return default
            return self.FETCH(key)
        result.get = get

        result.keys = lambda self: [k for k in self]
        result.values = lambda self: [self[k] for k in self]
        result.items = lambda self: [(k, self[k]) for k in self]
        result.update = lambda self, items: {self.STORE(i, items[i]) for i in items}
        cls.__TIE_subclass__ = result

    obj.__class__ = result
    return obj
