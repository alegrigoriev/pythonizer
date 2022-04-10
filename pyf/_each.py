
def _each(h_a):
    """See https://perldoc.perl.org/functions/each"""
    key = str(id(h_a))       # Unique memory address of object
    if not hasattr(_each, key):
        setattr(_each, key, iter(h_a))
    it = getattr(_each, key)
    try:
        v = next(it)
    except StopIteration:
        setattr(_each, key, iter(h_a))
        return []

    if hasattr(h_a, 'keys'):
        return [v, h_a[v]]
    ndx_key = key + 'i'
    i = 0;
    if hasattr(_each, ndx_key):
        i = getattr(_each, ndx_key)
    setattr(_each, ndx_key, i+1)
    return [i, v]
