
def _overload_Overloaded(obj):
    """Given an object, return 1 if it has any overloads defined,
    else return ''"""
    for a in dir(obj):
        if a.startswith('('):   # special attribute for overloaded method
            return 1
    return ''
