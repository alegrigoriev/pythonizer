
def _ref(r):
    """ref function in perl"""
    _ref_map = {"<class 'int'>": 'SCALAR', "<class 'str'>": 'SCALAR',
                "<class 'float'>": 'SCALAR', "<class 'NoneType'>": 'SCALAR',
                "<class 'list'>": 'ARRAY', "<class 'tuple'>": 'ARRAY',
                "<class 'dict'>": 'HASH'}
    t = str(type(r))
    if t in _ref_map:
        return _ref_map[t]
    return ''
