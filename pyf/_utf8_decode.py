
def _utf8_decode(s):
    """Implementation of utf8::decode"""
    try:
        return (str(s).encode('latin-1').decode(), 1)
    except Exception:
        return (str(s).encode('latin-1').decode(errors='ignore'), '')
