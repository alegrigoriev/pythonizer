
def splitpath(*_args):
    """Implementation of File::Spec->splitpath"""
    [path, nofile] = _list_of_n(_args, 2)

    [volume, directory, file] = ("", "", "")

    if nofile:
        directory = path
    else:
        _m = re.search(
            re.compile(r"^ ( (?: .* / (?: \.\.?\Z )? )? ) ([^/]*) ", re.X | re.S), _str(path)
        )
        directory = _m.group(1)
        file = _m.group(2)

    return [volume, directory, file]

