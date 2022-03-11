
_finditer_pattern = None
_finditer_string = None
_finditer_iter = None

def _finditer_next(pattern, string, flags=0):
    """Implementation of re.finditer() where it can be called multiple times for the same pattern and string"""
    global _finditer_iter, _finditer_pattern, _finditer_string

    if _finditer_pattern != pattern or _finditer_string != string:
        _finditer_iter = None
    if _finditer_iter is None:
        _finditer_iter = re.finditer(pattern, string, flags)
        _finditer_pattern = pattern
        _finditer_string = string

    result = next(_finditer_iter, None)
    if result is None:
        _finditer_iter = None
    return result
