
def _assign_sparse(lst, indexes, values):
    """Assign a list with a sparse list of indexes and a list of values"""
    if len(indexes) == len(values):
        for i in range(len(indexes)):
            lst[_int(indexes[i])] = values[i]
    else:
        for i in range(len(indexes)):
            lst[_int(indexes[i])] = values[i] if i < len(values) else None
    return lst
