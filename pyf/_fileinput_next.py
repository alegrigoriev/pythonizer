
_fileinput_iter = None

def _fileinput_next(files=None, inplace=False, backup='',*, mode='r', openhook=None, encoding=None, errors=None):
    """Implementation of fileinput.input() where it can be called multiple times for the same <> operator"""
    global _fileinput_iter

    if _fileinput_iter is None:
        try:
            (mode, encoding, errors) = _handle_open_pragma(mode, encoding, errors)
        except NameError:
            pass
        _fileinput_iter = fileinput.input(files=files, inplace=inplace, backup=backup, mode=mode, openhook=openhook,
                                          encoding=encoding, errors=errors)
    
    result = next(_fileinput_iter, None)
    if result is None:
        _fileinput_iter = None
    return result
