
def _filter_map(f, i):
    """Given a function f that returns a tuple of (new_val, include) and
    an iterable i, return an iterable of new_vals where include is True"""
    for v in i:
        (new_val, include) = f(v)
        if include:
            yield new_val

