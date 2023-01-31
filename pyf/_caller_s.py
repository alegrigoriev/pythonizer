
def _caller_s(expr=None):
    """ Implementation of caller function in scalar context"""
    result = _caller(2 if expr is None else (max(int(expr),0)+2))
    if result is None:
        return result
    return result[0]
