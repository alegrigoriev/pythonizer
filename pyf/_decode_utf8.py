
def _decode_utf8(octets, check=None):
    """Implementation of Encode::decode_utf8"""
    # Note: The code here is mostly a copy of _decode.py
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
        return octets.encode('latin-1').decode(errors=name)
    else:
        check = _int(check)
    if check & Encode.FB_CROAK():
        try:
            return octets.encode('latin-1').decode()
        except Exception as e:
            _croak(str(e))
    elif (check & 7) == Encode.FB_WARN():
        try:
            s = octets.encode('latin-1')
            return s.decode()
        except UnicodeError as e:
            print(str(e), file=sys.stderr)
            return s[:e.start].decode()
    elif (check & 7) == Encode.FB_QUIET():
        # NOTE: To keep from having to change the user's string (which is difficult
        # in python, since they are immutable), we instead keep track of the status
        # of the current decode as an attribute of this function.  We avoid using this status
        # in a completely different decode_utf8 by checking the first 16-bytes of the
        # string being decoded, and also ensuring that the string being passed keeps growing.
        # This may not be 100% effective in all cases, but it does pass a fairly
        # comprehensive test (test_Encode.py)
        try:
            s = octets.encode('latin-1')
            orig_s = s
            if hasattr(_decode_utf8, 'start'):
                # Quick sanity check that we're still decoding the same data
                verify_chars = 16
                string = _decode_utf8.string
                check_len = min(verify_chars, _decode_utf8.start)
                ln = len(s)
                if(ln == 1 or ln < _decode_utf8.start or s[:check_len] != string[:check_len]):
                    delattr(_decode_utf8, 'start')
                else:
                    s = s[_decode_utf8.start:]
            result = s.decode()
            _decode_utf8.start = len(orig_s)
            _decode_utf8.string = orig_s
            return result
        except UnicodeError as e:
            prior_start = 0
            if e.reason.startswith('unexpected end'):
                if hasattr(_decode_utf8, 'start'):
                    prior_start = _decode_utf8.start
                    _decode_utf8.start += e.start
                else:
                    _decode_utf8.start = e.start
                _decode_utf8.string = orig_s
            elif hasattr(_decode_utf8, 'start'):
                delattr(_decode_utf8, 'start')
            return orig_s[prior_start:_decode_utf8.start].decode()
    else:
        return octets.encode('latin-1').decode(errors='replace')
