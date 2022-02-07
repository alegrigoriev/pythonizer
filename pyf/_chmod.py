
def _chmod(mode, *argv):
    """Implementation of perl chmod function"""
    result = 0
    for arg in argv:
        try:
            os.chmod(arg, mode)
            result += 1
        except Exception:
            pass
    return result
