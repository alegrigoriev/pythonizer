
def _ref(r):
    """ref function in perl - called when NOT followed by a backslash"""
    _ref_map = {"<class 'int'>": 'SCALAR', "<class 'str'>": 'SCALAR',
                "<class 'float'>": 'SCALAR', "<class 'NoneType'>": 'SCALAR',
                "<class 'list'>": 'ARRAY', "<class 'tuple'>": 'ARRAY',
                "<class 'function'>": 'CODE', "<class 'dict'>": 'HASH'}
    tr = type(r)
    t = str(tr)
    if t in _ref_map:
        return ''
    elif '_ArrayHash' in t:
        return ''
    if isinstance(r, type): # return '' for a class (not a class instance)
        return ''
    if hasattr(tr, '__name__'):
        return tr.__name__.replace('.', '::')
    return t.replace("<class '", '').replace("'>", '').replace('.', '::')
