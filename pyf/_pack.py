
_PACK_TO_STRUCT = dict(a='s', c='b', C='B', s='h', S='H', l='l', L='L', q='q', Q='Q',
                       i='i', I='I', n='!H', N='!L', v='<H', V='<L', j='i', J='I', f='f',
                       d='d', F='d', x='x')
_TEMPLATE_LENGTH = dict(a=1, c=1, C=1, s=2, S=2, l=4, L=4, q=8, Q=8, i=4, I=4, n=2, N=4, v=2, V=4, j=4, J=4, f=4, d=8, F=8, x=1)
# Create simple bytes <-> str identity conversions
_decoding_map = codecs.make_identity_dict(range(256))
_encoding_map = codecs.make_encoding_map(_decoding_map)
def _str_to_bytes(by):
    return codecs.charmap_encode(by, 'ignore', _encoding_map)[0]
def _bytes_to_str(by):
    return codecs.charmap_decode(by, 'ignore', _decoding_map)[0]

def _get_pack_unpack_format_and_counts(template, args, is_unpack=False):
    # FIXME: Handle more cases using a custom translator.
    format_and_counts = []
    prefix = ''
    format = ''
    i = 0
    ndx = 0
    typ = 'unpack' if is_unpack else 'pack'
    len_so_far = 0
    prev = 0
    while i < len(template):
        if template[i].isspace():
            i += 1
            continue
        if template[i] in _PACK_TO_STRUCT:
            fmt = _PACK_TO_STRUCT[template[i]]
        else:
            raise Die(f'{typ} format {template[i]} is not currently supported')

        mod = ''
        cnt = 1
        if (_m:=re.match(r'^([!<>]?)((?:(?:\[?(?:(?:\d+)|[*]))\]?)|(?:\[[A-Za-z]\]))?', template[i+1:])):
            i += _m.end()
            mod = _m.group(1)
            if mod is None:
                mod = ''
            cnt = _m.group(2)
            if not cnt:
                cnt = '1'
            elif cnt[0] == '[':
                cnt = cnt[1:-1]
            if cnt.isdigit():
                cnt = int(cnt)
            elif cnt in _TEMPLATE_LENGTH:
                cnt = _TEMPLATE_LENGTH[cnt]
            else:
                raise Die(f'{typ} cannot get length of {cnt} template')
            if mod == '!':
                if len(fmt) != 1:
                    fmt = fmt.lower()
                    mod = fmt[0]
                    fmt = fmt[1]
                else:
                    mod = '@'   # Native
            elif len(fmt) != 1:
                mod = fmt[0]
                fmt = fmt[1]

            if cnt == '*':
                if is_unpack and hasattr(args[0], '__len__'):
                    cnt = len(args[0]) - len_so_far - (struct.calcsize(format) if format else 0)
                if ndx < len(args) and hasattr(args[ndx], '__len__'):
                    cnt = len(args[ndx])
                else:
                    cnt = 1
            fmt = f"{cnt}{fmt}"
        elif len(fmt) != 1:
            mod = fmt[0]
            fmt = fmt[1]


        fmt_code = fmt[-1]
        if mod == prefix:
            format += fmt
            mod = ''
            fmt = ''
        elif mod and not prefix:
            prefix = mod
            format += fmt
            mod = ''
            fmt = ''
        else:
            format = f'{prefix}{format}'
            len_so_far += struct.calcsize(format)
            format_and_counts.append((format, prev, ndx))
            prefix = ''
            format = ''
            prev = ndx

        if fmt_code == 's':
            if not is_unpack and isinstance(args[ndx], str):
                args[ndx] = _str_to_bytes(args[ndx])
            ndx += 1
        else:
            ndx += cnt

        i += 1

    format = prefix + mod + format + fmt
    if format:
        format_and_counts.append((format, prev, ndx))

    return format_and_counts

def _pack(template, *args):
    """pack items into a str via a given format template"""
    # Look here to handle many cases: https://docs.python.org/3/library/struct.html
    args = list(args)
    result = ''
    format_and_counts = _get_pack_unpack_format_and_counts(template, args)

    for format, start, end in format_and_counts:
        result += _bytes_to_str(struct.pack(format, *args[start:end]))

    return result
