
def _each(h_a):
    """See https://perldoc.perl.org/functions/each"""
    key = id(h_a)       # Unique memory address of object
    if not hasattr(_each, key):
        setattr(_each, key, iter(h_a))
    it = getattr(_each, key)
    try:
        v = next(it)
    except StopIteration:
        setattr(_each, key, iter(h_a))
        return []

    if isinstance(h_a, dict):
        return [v, h_a[v]]
    return v
