
def _get_layers(fh):
    """Implementation of PerlIO::get_layers"""
    result = ['unix', 'perlio']
    if fh.encoding == 'UTF-8':
        if fh.errors == 'strict':
            result.append('encoding(utf-8-strict)')
        else:
            result.append('encoding(utf-8)')
        result.append('utf8')
    if fh.newlines == "\n":
        result.append('lf')
    elif fh.newlines == "\r\n":
        result.append('crlf')

    return result
