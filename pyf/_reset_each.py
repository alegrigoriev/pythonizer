
def _reset_each(h_a):
    """Reset the 'each' iterator on keys/values calls"""
    key = str(id(h_a))       # Unique memory address of object
    if hasattr(_each, key):
        delattr(_each, key)
