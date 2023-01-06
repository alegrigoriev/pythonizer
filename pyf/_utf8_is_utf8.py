
def _utf8_is_utf8(s):
    """Implementation of utf8::is_utf8"""
    try:
        s = str(s)
        if s.isascii():
            return ''
        s.encode()
    except Exception:
        return ''

    # if it looks like raw utf8, then it's not utf8 encoded
    i = 0;
    in_byte = 0
    while i < len(s):
        c = ord(s[i])
        if in_byte:
            if c < 0x80 or c > 0xbf:
                return 1
            in_byte -= 1
        else:
            if c < 0x80:
                pass
            elif c >= 0xc0 and c <= 0xdf:  # 2-byte
                in_byte = 1
            elif c >= 0xe0 and c <= 0xef:  # 3-byte
                in_byte = 2
            elif c >= 0xf0 and c <= 0xff:  # 4-byte
                in_byte = 3
            else:
                return 1
        i += 1

    if in_byte:
        return 1
    return ''
