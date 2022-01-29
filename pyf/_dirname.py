
def _dirname(fullname):
    """Emulation of File::Basename qw(dirname) for unix"""
    def fileparse(fullname):
        [dirpath,basename] = (_m:=re.search(re.compile(r'^(.*/)?(.*)',re.S),fullname),_m.groups() if _m else [None,None])[1]

        if not (dirpath):
            dirpath = './'
        return (basename, dirpath)

    [basename, dirname] = fileparse(fullname)

    dirname = re.sub(r'(.)/*$', r'\1', dirname, flags=re.S)
    if not len(basename):
        [basename, dirname] = fileparse(dirname)
        dirname = re.sub(r'(.)/*$', r'\1', dirname, flags=re.S)

    return dirname
