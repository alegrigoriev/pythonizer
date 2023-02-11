
def _encode_utf8(string):
    """Implementation of Encode::encode_utf8"""
    return string.encode(errors='replace').decode('latin-1')
