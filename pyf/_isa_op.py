
def _isa_op(self, classname):
    """Implementation of isa operator"""
    if hasattr(classname, '__name__'):
        classname = classname.__name__
    elif not isinstance(classname, str) and hasattr(classname, '__class__'):
        classname = classname.__class__.__name__
    if hasattr(self, 'isa'):
            return self.isa(classname)
    _ref_map = {"<class 'int'>": 'SCALAR', "<class 'str'>": 'SCALAR',
                "<class 'float'>": 'SCALAR', "<class 'NoneType'>": 'SCALAR',
                "<class 'list'>": 'ARRAY', "<class 'tuple'>": 'ARRAY',
                "<class 'dict'>": 'HASH'}
    if isinstance(self, type):
        return ''   # isa operator needs an object on the LHS, not a class
    t = str(type(self))
    if t in _ref_map:
        return 1 if _ref_map[t] == classname else ''
    elif '_ArrayHash' in t:
        if self.isHash:
            return 1 if 'HASH' == classname else ''
        return 1 if 'ARRAY' == classname else ''
    elif classname == 'IO::Handle' or classname == 'IO.Handle':
        return 1 if isinstance(self, io.IOBase) else ''
    elif classname == 'UNIVERSAL':
        return 1
    elif classname == 'GLOB':
        # Assume all file handles and subs are globs
        return 1 if isinstance(self, io.IOBase) or callable(self) else ''
    elif classname == 'CODE':
        return 1 if callable(self) else ''
    classname = classname.replace("'", '.').replace('::', '.')
    if hasattr(builtins, classname):
        the_class = getattr(builtins, classname)
        if isinstance(the_class, type): # make sure it's a class and not a namespace
            if isinstance(self, the_class):
                return 1
            if isinstance(self, type) and issubclass(self, the_class):
                return 1
        elif self == the_class:
            return ''   # Not an object
        else:
            if hasattr(self, 'ISA_a'):
                for parent_name in getattr(self, 'ISA_a'):
                    parent_name = parent_name.replace("'", '.').replace('::', '.')
                    if hasattr(builtins, parent_name):
                        return _isa(getattr(builtins, parent_name), classname)
            return ''
    return ''       # False
