
def _fileparse(*args):
    """Split a path into basename, dirpath, and (optional) suffices"""
    fullname = args[0]
    suffices = args[1:]
    [dirpath,basename] = (_m:=re.search(re.compile(r'^(.*/)?(.*)',re.S),fullname),_m.groups() if _m else [None,None])[1]
    if not (dirpath):
        dirpath = './'

    tail=''
    suffix=''
    if suffices:
        for suffix in suffices:
            pat=f"({suffix})$"
            if (_m:=re.sub(re.compile(pat,re.S),r'',basename,count=1)):
                tail = _m.group(1) + tail

    return (basename, dirpath, tail)
