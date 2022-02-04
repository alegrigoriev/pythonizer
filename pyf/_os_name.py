
def _os_name():
    """Implementation of $OSNAME / $^O"""
    result = sys.platform
    return 'MSWin32' if result == 'win32' else result
