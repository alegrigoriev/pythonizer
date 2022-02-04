
def _file_size(path):        # -s
    if not path:
        return None
    if hasattr(path, '_size'):
        return path._size
    return os.path.getsize(path)
