
def _mapf(func,arg):
    """Handle map with user function - in perl the global $_ is the arg"""
    global _d
    _d = arg
    return func([arg])

