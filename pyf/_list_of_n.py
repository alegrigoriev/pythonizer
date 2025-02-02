
def _list_of_n(lst, n):
    """For assignment to (list, ...) - make this list the right size"""
    if isinstance(lst, itertools.chain):
        lst = list(lst)
    if lst is None or (hasattr(lst, 'isHash') and lst.isHash) or not (isinstance(lst, collections.abc.Sequence) and not isinstance(lst, str)):
        lst = [lst]
    la = len(lst)
    if la == n:
        return lst
    if la > n:
        return lst[:n]
    return list(lst) + [None for _ in range(n-la)]

