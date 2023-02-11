
def _define_encoding(obj, name, aliases):
    """Implementation of Encode::define_encoding"""
    def norm(n):
        return re.sub(r'[-\s]+', '_', n).lower()
    def encode(s, errors='strict'):
        l = len(s)
        s = obj.encode(s)
        return (bytes(s, encoding='latin1'), l)
    def decode(b, errors='strict'):
        l = len(b)
        s = str(b, encoding='latin1')
        return (obj.decode(s), l)
    result = codecs.CodecInfo(name=name, encode=encode, decode=decode)
    result._obj = obj
    name = norm(name)

    codecs.register(lambda n: result if n == name else None)

    for alias in aliases:
        _define_alias(alias, obj.name())
    return obj

