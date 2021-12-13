
def _wait():
    """Replacement for perl wait() call"""
    global CHILD_ERROR
    try:
        (pid, stat) = os.wait()
        CHILD_ERROR = stat
        return pid
    except Exception:
        return -1

