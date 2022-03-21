
def _assign_hash(h, keys, values):
    """Assign a hash with a list of hash keys and a list of values"""
    keys = list(keys)
    values = list(values)
    if len(keys) == len(values):
        for i in range(len(keys)):
            h[_str(keys[i])] = values[i]
    else:
        for i in range(len(keys)):
            h[_str(keys[i])] = values[i] if i < len(values) else None
    return h
