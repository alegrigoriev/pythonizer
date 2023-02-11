
def _encode(encoding, string, check=None):
    """Implementation of Encode::encode"""
    if check is None:
        check = 0
    elif callable(check):
        name = str(id(check))
        try:
            codecs.lookup_error(name)
        except LookupError:
            def handler(uee):
                slc = uee.object[uee.start:uee.end]
                if not isinstance(slc, bytes):
                    slc = bytes(slc,encoding='latin-1')
                return (check(*slc), uee.end)
            codecs.register_error(name, handler)
        return string.encode(encoding, errors=name).decode('latin-1')
    else:
        check = _int(check)
    if check & Encode.FB_CROAK():
        try:
            return string.encode(encoding).decode('latin-1')
        except Exception as e:
            _croak(str(e))
    elif (check & 7) == Encode.FB_WARN():
        try:
            return string.encode(encoding).decode('latin-1')
        except UnicodeError as e:
            print(str(e), file=sys.stderr)
            return string[:e.start].encode(encoding).decode('latin-1')
    elif (check & 7) == Encode.FB_QUIET():
        try:
            return string.encode(encoding).decode('latin-1')
        except UnicodeError as e:
            return string[:e.start].encode(encoding).decode('latin-1')
    else:
        return string.encode(encoding, errors='replace').decode('latin-1')
