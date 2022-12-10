
def _list_of_at_least_n(lst, n):
    """For assignment to (list, ..., *last) - make this list at least the right size."""
    if lst is None or (hasattr(lst, 'isHash') and lst.isHash) or not (isinstance(lst, collections.abc.Sequence) and not isinstance(lst, str)):
        lst = [lst]
    la = len(lst)
    if la >= n:
        return lst
    return list(lst) + [None for _ in range(n-la)]

