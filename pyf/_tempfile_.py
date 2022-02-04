
def _tempfile_(*args):
    """Implementation of File::Temp::tempfile() in list context"""
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
    suffix=None
    unlink=True
    if 'TEMPLATE' in options:
        template = options['TEMPLATE']
    if template:
        template = template.replace('X', '')
        (base, dirn, tail) = _fileparse(template)
    if 'SUFFIX' in options:
        suffix = options['SUFFIX']
    if 'DIR' in options:
        dirn = options['DIR']
    if 'UNLINK' in options:
        unlink = options['UNLINK']
    fh = tempfile.NamedTemporaryFile(prefix=base, dir=dirn, suffix=suffix, delete=unlink)
    def filename(fh):
        return fh._name
    fh._name = fh.name
    fh.filename = types.MethodType(filename, fh)
    return (fh, fh.name)
