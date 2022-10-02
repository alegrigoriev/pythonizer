
def _unlink(*args):
    """Implementation of perl unlink"""
    global OS_ERROR

    cnt = 0
    for f in args:
        try:
            os.unlink(f)
            cnt += 1
        except Exception as e:
            OS_ERROR = str(e)

    return cnt
