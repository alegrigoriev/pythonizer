
def _find_mime_encoding(encoding):
    """Implementation of Encode::find_mime_encoding"""
    obj = _find_encoding(encoding)
    if hasattr(obj, 'mime_name'):
        mime_name = obj.mime_name()
        def normalize(enc):
            # Make sure 'ISO-8859-1' matches 'iso8859-1'
            return enc.lower().replace('-', '').replace('_', '')
        if normalize(mime_name) != normalize(encoding):
            return None
    return obj
