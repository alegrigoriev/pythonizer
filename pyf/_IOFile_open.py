
def _open_mode_string(mode):
    if not ((_m:=re.search(r'^\+?(<|>>?)$',mode))):
        if not (mode:=re.sub(r'^r(\+?)$',r'\g<1><',mode, count=1)):
            if not (mode:=re.sub(r'^w(\+?)$',r'\g<1>>',mode, count=1)):
                if not (mode:=re.sub(r'^a(\+?)$',r'\g<1>>>',mode, count=1)):
                    _croak(f"IO::Handle: bad open mode: {mode}")
    return mode

def _IOFile_open(fh, filename, mode=None, perms=None):
    """Implementation of perl $fh->open method"""
    if mode is not None:
        if isinstance(mode, str) and re.match(r'^\d+$', mode):
            mode = int(mode)
            if perms is None:
                perms = 0o666
            result = os.fdopen(os.open(filename, mode, perms))
        elif ':' in mode:
            result = _open_dynamic(filename, mode, checked=False)
        else:
            result = _open_dynamic(filename, _open_mode_string(mode), checked=False)
    else:
        encoding = errors = None
        if hasattr(fh, 'encoding'):
            encoding = fh.encoding
            errors = fh.errors
        result = _open_dynamic(filename,encoding=encoding,errors=errors)
    if not fh.closed:
        fh.close()
    return _create_all_fh_methods(result)
