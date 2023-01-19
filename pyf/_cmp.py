
def _cmp(a,b):
    """3-way comparison like the cmp operator in perl"""
    if a is None:
        a = ''
    elif hasattr(a, '__cmp__'):
        return a.__cmp__(b)
    if b is None:
        b = ''
    elif hasattr(b, '__rcmp__'):
        return b.__rcmp__(a)
    a = str(a)
    b = str(b)
    return (a > b) - (a < b)
