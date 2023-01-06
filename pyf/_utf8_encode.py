
def _utf8_encode(s):
    """Implementation of utf8::encode"""
    return (str(s).encode().decode('latin-1'), None)
