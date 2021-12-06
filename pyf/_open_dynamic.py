
def _open_dynamic(file,mode=None):
    """Replacement for perl built-in open function when the mode is unknown."""
    dup = None
    pipe = None
    if mode is None:
        m = re.match(r'^\s*([<>+|-]*)([&]?)\s*(.*?)\s*([|]?)\s*$', file)
        mode = m.group(1)
        dup = m.group(2)
        file = m.group(3)
        pipe = m.group(4)
    if mode == '<-':
        return sys.stdin
    if mode == '->':
        return sys.stdout
    ext = encoding = None
    if ':' in mode:
        mode, ext = mode.split(':')
    if mode in _OPEN_MODE_MAP:
        mode = _OPEN_MODE_MAP[mode]
        errors = None
        if ext:
            if ext == 'raw' or ext == 'bytes':
                mode += 'b'
            elif ext.startswith('encoding('):
                encoding = ext.replace('encoding(','').replace(')','')
            elif ext == 'utf8':
                encoding = 'UTF-8'
                errors = 'ignore'
        if dup:
            return _dup(file, mode,encoding=encoding,errors=errors)
        return _open(file, mode,encoding=encoding,errors=errors)
    if pipe:
        return _open(file, '-|')
    return _open(file, 'r')

