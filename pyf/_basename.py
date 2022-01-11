
def _basename(path, *suffixes):
    path = re.sub(r'(.)/*$', r'\1', path, flags=re.S)
    [basename, dirname, suffix] = _fileparse(path, *map(re.escape, suffixes))
    if len(suffix) and not len(basename):
        basename = suffix

    if not len(basename):
        basename = dirname

    return basename
