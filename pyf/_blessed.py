
def _blessed(r):
    """blessed function in perl"""
    _ref_map = {"<class 'int'>": 'SCALAR', "<class 'str'>": 'SCALAR',
                "<class 'float'>": 'SCALAR', "<class 'NoneType'>": 'SCALAR',
                "<class 'list'>": 'ARRAY', "<class 'tuple'>": 'ARRAY',
                "<class 'function'>": 'CODE', "<class 'dict'>": 'HASH'}
    tr = type(r)
    t = str(tr)
    if t in _ref_map:
        return None
    elif '_ArrayHash' in t:
        return None
    if hasattr(tr, '__name__'):
        return tr.__name__.replace('.', '::')
    return t.replace("<class '", '').replace("'>", '').replace('.', '::')
