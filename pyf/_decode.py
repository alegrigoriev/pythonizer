
_init_package('Encode')
def FB_DEFAULT():
    return 0
Encode.FB_DEFAULT = FB_DEFAULT
def FB_CROAK():
    return 1
Encode.FB_CROAK = FB_CROAK
def FB_QUIET():
    return 4
Encode.FB_QUIET = FB_QUIET
def FB_WARN():
    return 6
Encode.FB_WARN = FB_WARN
def LEAVE_SRC():
    return 8
Encode.LEAVE_SRC = LEAVE_SRC

def _decode(encoding, octets, check=None):
    """Implementation of Encode::decode"""
    # NOTE: Changes to this function should also be make in _decode_utf8.py
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
        return octets.encode('latin-1').decode(encoding, errors=name)
    else:
        check = _int(check)
    if check & Encode.FB_CROAK():
        try:
            return octets.encode('latin-1').decode(encoding)
        except Exception as e:
            _croak(str(e))
    elif (check & 7) == Encode.FB_WARN():
        try:
            s = octets.encode('latin-1')
            return s.decode(encoding)
        except UnicodeError as e:
            print(str(e), file=sys.stderr)
            return s[:e.start].decode(encoding)
    elif (check & 7) == Encode.FB_QUIET():
        # NOTE: To keep from having to change the user's string (which is difficult
        # in python, since they are immutable), we instead keep track of the status
        # of the current decode as an attribute of this function.  We avoid using this status
        # in a completely different decode by checking the first 16-bytes of the
        # string being decoded, and also ensuring that the string being passed keeps growing.
        # This may not be 100% effective in all cases, but it does pass a fairly
        # comprehensive test (test_Encode.py)
        try:
            s = octets.encode('latin-1')
            orig_s = s
            if hasattr(_decode, 'start'):
                # Quick sanity check that we're still decoding the same data
                verify_chars = 16
                string = _decode.string
                check_len = min(verify_chars, _decode.start)
                ln = len(s)
                if(ln == 1 or ln < _decode.start or s[:check_len] != string[:check_len]):
                    delattr(_decode, 'start')
                else:
                    s = s[_decode.start:]
            result = s.decode(encoding)
            _decode.start = len(orig_s)
            _decode.string = orig_s
            return result
        except UnicodeError as e:
            prior_start = 0
            if e.reason.startswith('unexpected end'):
                if hasattr(_decode, 'start'):
                    prior_start = _decode.start
                    _decode.start += e.start
                else:
                    _decode.start = e.start
                _decode.string = orig_s
            elif hasattr(_decode, 'start'):
                delattr(_decode, 'start')
            return orig_s[prior_start:_decode.start].decode(encoding)
    else:
        return octets.encode('latin-1').decode(encoding, errors='replace')
