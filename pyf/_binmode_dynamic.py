
def _binmode_dynamic(fh, mode):
    """Handle binmode where the mode/layers are dynamic"""
    encoding = None
    errors = None
    newline = None
    mmode = mode

    ext = None
    if ':' in mode:
        mode, ext = mode.split(':')
    if mode in _OPEN_MODE_MAP:
        mode = _OPEN_MODE_MAP[mode]
    else:
        mode = 'r'
    if ext:
        if ext == 'raw' or ext == 'bytes':
            mode += 'b'
        elif ext.startswith('encoding('):
            encoding = ext.replace('encoding(','').replace(')','')
            errors = 'replace'
        elif ext == 'utf8':
            encoding = 'UTF-8'
            errors = 'ignore'
    return _binmode(fh, mode, encoding=encoding, errors=errors, newline=newline)
