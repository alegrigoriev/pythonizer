
def _looks_like_binary(path):        # -B
    """Implementation of perl -B"""
    if isinstance(path, tuple):
        return ValueError('-B not supported on File_stat')
    return not _looks_like_text(path)
