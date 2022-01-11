
def _fileparse(*args):
    """Split a path into basename, dirpath, and (optional) suffixes.
    Translated from perl File::Basename for unix, plus annotations"""
    fullname = args[0]
    suffixes = args[1:]
    if fullname is None:
        raise Die("fileparse(): need a valid pathname")
    fullname = str(fullname)
    [dirpath,basename] = (_m:=re.search(re.compile(r'^(.*/)?(.*)',re.S),fullname),_m.groups() if _m else [None,None])[1]
    if not (dirpath):
        dirpath = './'

    tail=''
    suffix=''
    if suffixes:
        for suffix in suffixes:
            if(isinstance(suffix, re.Pattern)): # in case they use qr
                suffix = suffix.pattern
            pat=f"({suffix})$"
            def sub(_m):
                nonlocal tail
                tail = _m.group(1) + tail
                return ''
            basename = re.sub(re.compile(pat,re.S),sub,basename,count=1)

    return (basename, dirpath, tail)
