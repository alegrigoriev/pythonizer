
def _refs(r):
    """ref function in perl - called when followed by a backslash"""
    _ref_map = {"<class 'int'>": 'SCALAR', "<class 'str'>": 'SCALAR',
                "<class 'float'>": 'SCALAR', "<class 'NoneType'>": 'SCALAR',
                "<class 'list'>": 'ARRAY', "<class 'tuple'>": 'ARRAY',
                "<class 'dict'>": 'HASH'}
    t = str(type(r))
    if t in _ref_map:
        return _ref_map[t]
    elif '_ArrayHash' in t:
        if r.isHash:
            return 'HASH'
        return 'ARRAY'
    elif hasattr(r, 'TIEARRAY'):
        return 'ARRAY'
    elif hasattr(r, 'TIEHASH'):
        return 'HASH'
    return ''
