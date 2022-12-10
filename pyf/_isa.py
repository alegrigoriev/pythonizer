
def _isa(self, classname):
    """Implementation of UNIVERSAL::isa and $obj->isa"""
    _ref_map = {"<class 'int'>": 'SCALAR', "<class 'str'>": 'SCALAR',
                "<class 'float'>": 'SCALAR', "<class 'NoneType'>": 'SCALAR',
                "<class 'list'>": 'ARRAY', "<class 'tuple'>": 'ARRAY',
                "<class 'dict'>": 'HASH'}
    t = str(type(self))
    if t in _ref_map:
        return 1 if _ref_map[t] == classname else ''
    elif '_ArrayHash' in t:
        if self.isHash:
            return 1 if 'HASH' == classname else ''
        return 1 if 'ARRAY' == classname else ''
    elif classname == 'IO::Handle':
        return 1 if isinstance(self, io.IOBase) else ''
    elif classname == 'UNIVERSAL':
        return 1
    classname = classname.replace("'", '.').replace('::', '.')
    if hasattr(builtins, classname):
        the_class = getattr(builtins, classname)
        return 1 if isinstance(self, the_class) else ''
    return ''       # False
