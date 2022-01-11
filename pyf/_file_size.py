
def _file_size(path):        # -s
    if not path:
        return None
    if hasattr(path, 'size'):
        return path.size
    return os.path.getsize(path)
