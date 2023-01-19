
def _ref_scalar(r):
    """ref function in perl - called when being passed a scalar without a backslash"""
    _ref_map = {"<class 'int'>": '', "<class 'str'>": '',
                "<class 'float'>": '', "<class 'NoneType'>": '',
                "<class 'list'>": 'ARRAY', "<class 'tuple'>": 'ARRAY',
                "<class 'function'>": 'CODE', "<class 'dict'>": 'HASH'}
    tr = type(r)
    t = str(tr)
    if t in _ref_map:
        return _ref_map[t]
    elif '_ArrayHash' in t:
        if r.isHash:
            return 'HASH'
        return 'ARRAY'
    if isinstance(r, type): # return '' for a class (not a class instance)
        return ''
    if hasattr(tr, '__name__'):
        return tr.__name__
    elif hasattr(r, 'TIEARRAY'):
        return 'ARRAY'
    elif hasattr(r, 'TIEHASH'):
        return 'HASH'
    return t.replace("<class '", '').replace("'>", '').replace('.', '::')
