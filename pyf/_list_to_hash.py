
def _list_to_hash(lst):
    """Convert a flat list of key value pairs to a hash"""
    return {lst[i]: lst[i+1] for i in range(0, len(lst), 2)};
