
def _caller_s(expr=None):
    """ Implementation of caller function in scalar context"""
    result = _caller(1 if expr is None else (max(int(expr),0)+1))
    if result is None:
        return result
    return result[0]
