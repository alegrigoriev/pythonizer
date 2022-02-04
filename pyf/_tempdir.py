
def _tempdir(*args):
    """Implementation of File::Temp::tempdir()"""
    template=None
    options={}
    start = 0
    if len(args) % 2 == 1:
        template = args[0]
        start = 1
    for i in range(start, len(args), 2):
        options[args[i]] = args[i+1]

    dirn=None
    base=None
    if template:
        template = template.replace('X', '')
        (base, dirn, tail) = _fileparse(template)
    if 'DIR' in options:
        dirn = options['DIR']
    return tempfile.mkdtemp(prefix=base, dir=dirn)
