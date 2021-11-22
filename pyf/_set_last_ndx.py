
def _set_last_ndx(arr, ndx):
    """Implementation of assignment to perl array last index $#array"""
    del arr[ndx+1:]
    for _ in range((ndx+1)-len(arr)):
        arr.append(None)

