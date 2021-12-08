
def _sortf(func,aa,bb):
    """Handle sort with user function - in perl the global $a and $b are compared"""
    global a, b
    a = aa
    b = bb
    return func([])

