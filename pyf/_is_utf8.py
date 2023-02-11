
def _is_utf8(s, check=False):
    """Implementation of Encode::is_utf8"""
    if check:
        return _utf8_is_utf8(s)
    try:
        s = str(s)
        if s.isascii():
            return ''
        s.encode()
    except Exception:
        return ''
    return 1
