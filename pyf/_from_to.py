
def _from_to(octets, from_enc, to_enc, check=None):
    """Implementation of Encode::from_to"""
    result = _encode(to_enc, _decode(from_enc, octets), check)
    return (result, len(result))
