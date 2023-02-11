
def _find_encoding(encoding):
    """Implementation of Encode::find_encoding"""

    try:
        info = codecs.lookup(encoding)
        if hasattr(info, '_obj'):   # We defined it
            return info._obj
        decod = functools.partial(_decode, encoding)
        encod = functools.partial(_encode, encoding)
        name = lambda: encoding
        mime_name = lambda: info.name
        return type('Encode.Encoding', 
                    tuple(), 
                    dict(decode=decod, encode=encod, name=name, mime_name=mime_name))
    except LookupError:
        return None
