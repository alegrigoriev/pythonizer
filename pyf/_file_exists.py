
def _file_exists(path):        # -e
    if not path:
        return ''   # False
    if hasattr(path, 'cando'):
        return 1    # True
    return 1 if os.path.exists(path) else ''
