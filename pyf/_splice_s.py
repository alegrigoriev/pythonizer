
def _splice_s(array, *args):
    """Implementation of splice function in scalar context"""
    offset = 0;
    if len(args) >= 1:
        offset = args[0]
    length = len(array)
    if len(args) >= 2:
        length = args[1]
    if offset < 0:
        offset += len(array)
    total = offset + length
    if length < 0:
        total = length
    removed = array[offset:total]
    array[offset:total] = args[2:]
    if not removed:
        return None
    return removed[-1]
