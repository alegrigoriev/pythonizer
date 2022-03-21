
_fileinput_iter = None

def _fileinput_next(files=None, inplace=False, backup='',*, mode='r', openhook=None, encoding=None, errors=None):
    """Implementation of fileinput.input() where it can be called multiple times for the same <> operator"""
    global _fileinput_iter

    if _fileinput_iter is None:
        try:
            (mode, encoding, errors, newline) = _handle_open_pragma(mode, encoding, errors)
        except NameError:
            pass
        try:
            _fileinput_iter = fileinput.input(files=files, inplace=inplace, backup=backup, mode=mode, openhook=openhook,
                                          encoding=encoding, errors=errors)
        except TypeError:   # pythons older than 3.10 don't have encoding and errors
            _fileinput_iter = fileinput.input(files=files, inplace=inplace, backup=backup, mode=mode, openhook=openhook)
    
    result = next(_fileinput_iter, None)
    if result is None:
        _fileinput_iter = None
    return result
