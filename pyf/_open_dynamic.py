
def _open_dynamic(file,mode=None,encoding=None,errors=None,checked=True):
    """Replacement for perl built-in open function when the mode is unknown."""
    dup_it = None
    pipe = None
    if mode is None:
        m = re.match(r'^\s*([<>+|-]*)([&]?=?)\s*(.*?)\s*([|]?)\s*$', file)
        mode = m.group(1)
        dup_it = m.group(2)
        file = m.group(3)
        pipe = m.group(4)
    elif '&' in mode:           # dup
        dup_it = '&'
        mode = mode.replace('&', '')
        if '=' in mode:
            dup_it = '&='
            mode = mode.replace('=', '')

    if mode == '<-' or mode == '-' or mode == '-<':
        return sys.stdin
    if mode == '>-' or mode == '->':
        return sys.stdout
    ext = None
    if ':' in mode:
        mode, ext = mode.split(':')
    if mode in _OPEN_MODE_MAP:
        mode = _OPEN_MODE_MAP[mode]
        if ext:
            if ext == 'raw' or ext == 'bytes':
                mode += 'b'
            elif ext.startswith('encoding('):
                encoding = ext.replace('encoding(','').replace(')','')
                errors = 'replace'
            elif ext == 'utf8':
                encoding = 'UTF-8'
                errors = 'ignore'
        if dup_it:
            if '=' in dup_it:
                return _dup(file, mode,encoding=encoding,errors=errors,checked=checked,equals=True)
            return _dup(file, mode,encoding=encoding,errors=errors,checked=checked)
        return _open(file, mode,encoding=encoding,errors=errors,checked=checked)
    if pipe:
        return _open(file, '-|',encoding=encoding,errors=errors,checked=checked)
    return _open(file, 'r',encoding=encoding,errors=errors,checked=checked)

