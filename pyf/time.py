
def _time():
    """ Replacement for perl built-in time function"""
    return (tm_py.time_ns() // 1000000000)
