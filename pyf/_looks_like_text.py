
def _looks_like_text(path):        # -T
    """Implementation of perl -T"""
    global TRACE_RUN
    if not isinstance(path, str):
        return ValueError('-T is only supported on paths')
    rtn = subprocess.run(f'file "{path}"',capture_output=True,text=True,shell=True)
    if TRACE_RUN:
        _carp(f'trace -T {path}: {repr(rtn)}', skip=2)
    if rtn.returncode:
        return None
    rtn = rtn.stdout
    return 'text' in rtn
