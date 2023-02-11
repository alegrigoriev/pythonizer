
def _resolve_alias(encoding):
    """Implementation of Encode::resolve_alias"""
    try:
        info = codecs.lookup(encoding)
        return info.name
    except LookupError:
        return None
