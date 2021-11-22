
def _list_of_n(lst, n):
    """For assignment to (list, ...) - make this list the right size"""
    if lst is None:
        lst = []
    la = len(lst)
    if la == n:
        return lst
    if la > n:
        return lst[:n]
    return lst + [None for _ in range(n-la)]

