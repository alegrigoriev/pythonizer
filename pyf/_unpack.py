
def _unpack(template, bytestr):
    """Unpack bytestr using the template and return a list of values"""
    if isinstance(bytestr, str):
        bytestr = _str_to_bytes(bytestr)
    result = []
    format_and_counts = _get_pack_unpack_format_and_counts(template, (bytestr,), is_unpack=True)
    start = 0
    for format, _, _ in format_and_counts:
        size = struct.calcsize(format)
        result.extend(struct.unpack(format, bytestr[start:start+size]))
        start += size

    for i, r in enumerate(result):
        if isinstance(r, bytes):
            result[i] = _bytes_to_str(r)

    return result
