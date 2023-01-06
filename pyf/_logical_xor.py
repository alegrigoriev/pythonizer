
def _logical_xor(a, b):
    """Implementation of perl's xor operator"""
    return 1 if (a or b) and not (a and b) else ''
