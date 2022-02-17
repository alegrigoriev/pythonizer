
def _looks_like_text(path):        # -T
    """Implementation of perl -T"""
    if not isinstance(path, str):
        return ValueError('-T is only supported on paths')
    rtn = subprocess.run(f'file "{path}"',capture_output=True,text=True,shell=True)
    if rtn.returncode:
        return None
    rtn = rtn.stdout
    return 'text' in rtn
