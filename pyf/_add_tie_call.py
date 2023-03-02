
def _add_tie_call(func, package):
    """Add a call to _tie_call for functions defined in a tie package"""
    def tie_call_func(*args, **kwargs):
        __package__ = package   # for _caller() only
        return _tie_call(func, args, kwargs)
    return tie_call_func
