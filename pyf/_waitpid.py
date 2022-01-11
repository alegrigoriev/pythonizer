
def _waitpid(pid, flags):
    """Replacement for perl waitpid() call"""
    global CHILD_ERROR
    try:
        (rpid, stat) = os.waitpid(pid, options)
        CHILD_ERROR = stat
        return rpid
    except Exception:
        return -1

