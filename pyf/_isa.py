
def _isa(self, classname):
    """Implementation of UNIVERSAL::isa and $obj->isa"""
    _ref_map = {"<class 'int'>": 'SCALAR', "<class 'str'>": 'SCALAR',
                "<class 'float'>": 'SCALAR', "<class 'NoneType'>": 'SCALAR',
                "<class 'list'>": 'ARRAY', "<class 'tuple'>": 'ARRAY',
                "<class 'dict'>": 'HASH'}
    t = str(type(self))
    if t in _ref_map:
        return _ref_map[t] == classname
    elif '_ArrayHash' in t:
        if r.isHash:
            return 'HASH' == classname
        return 'ARRAY' == classname
    elif classname == 'IO::Handle':
        return isinstance(self, io.IOBase)
    classname = classname.replace("'", '.').replace('::', '.')
    if hasattr(builtins, classname):
        the_class = getattr(builtins, classname)
        return isinstance(self, the_class)
    return False
