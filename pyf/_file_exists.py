
def _file_exists(path):        # -e
    if not path:
        return False
    if hasattr(path, 'cando'):
        return True
    return os.path.exists(path)
