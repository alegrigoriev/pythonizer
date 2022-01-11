
def _looks_like_text(path):        # -T
    if not isinstance(path, str):
        return ValueError('-T is only supported on paths')
    rtn = subprocess.run(f'file "{path}"',capture_output=True,text=True,shell=True)
    rtn = rtn.stdout
    if rtn.returncode:
        return None
    return 'text' in rtn
