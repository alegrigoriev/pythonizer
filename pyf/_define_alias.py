def _define_alias(alias, name):
    """Implementation of Encode::define_alias"""
    def norm(n):
        return re.sub(r'[-\s]+', '_', n).lower()
    if alias == norm(name):
        return
    try:
        info = codecs.lookup(name)
        result = codecs.CodecInfo(
            name=alias,
            encode=info.encode,
            decode=info.decode)
        if hasattr(info, '_obj'):
            result._obj = info._obj
    except LookupError:
        result = None
    alias = norm(alias)

    codecs.register(lambda a: result if a == alias else None)
