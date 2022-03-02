
_fileinput_iter = None

def _fileinput_next(*args, **kwargs):
    """Implementation of fileinput.input() where it can be called multiple times for the same <> operator"""
    global _fileinput_iter

    if _fileinput_iter is None:
        _fileinput_iter = fileinput.input(*args, **kwargs)
    
    result = next(_fileinput_iter, None)
    if result is None:
        _fileinput_iter = None
    return result
