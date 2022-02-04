
def _is_empty_file(path):        # -z
    if not path:
        return None
    if hasattr(path, '_size'):
        return path._size == 0
    return not os.path.getsize(path)
