
def _cmp(a,b):
    """3-way comparison like the cmp operator in perl"""
    if a is None:
        a = ''
    if b is None:
        b = ''
    return (a > b) - (a < b)
