
def _is_empty_file(path):        # -z
    if not path:
        return None
    if hasattr(path, 'size'):
        return path.size == 0
    return not os.path.getsize(path)
