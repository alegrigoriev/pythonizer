
def _smartmatch(left, right):
    """Implement the perl smartmatch (~~) operator"""
    if right is None:
        return 1 if left is None else ''
    if hasattr(left, '__smartmatch__'):
        return left.__smartmatch__(right)
    if hasattr(right, '__rsmartmatch__'):
        return right.__rsmartmatch__(left)
    if (hasattr(right, 'isHash') and right.isHash) or (not hasattr(right, 'isHash') and isinstance(right, collections.abc.Mapping)):
        if (hasattr(left, 'isHash') and left.isHash) or (not hasattr(left, 'isHash') and isinstance(left, collections.abc.Mapping)):
            return _smartmatch(sorted(left.keys()), sorted(right.keys()))
        elif isinstance(left, collections.abc.Iterable) and not isinstance(left, str):
            return 1 if any(i in right for i in left) else ''
        elif isinstance(left, re.Pattern):
            return 1 if any(re.search(left, _str(i)) for i in right.keys()) else ''
        else:
            return 1 if left in right.keys() else ''
    elif isinstance(right, collections.abc.Iterable) and not isinstance(right, str):
        if (hasattr(left, 'isHash') and left.isHash) or (not hasattr(left, 'isHash') and isinstance(left, collections.abc.Mapping)):
            return 1 if any(i in left for i in right) else ''
        elif isinstance(left, collections.abc.Iterable) and not isinstance(left, str):
            ll = list(left)
            lll = len(ll)
            lr = list(right)
            if lll != len(lr):
                return ''
            for i in range(lll):
                if not _smartmatch(ll[i], lr[i]):
                    return ''
            return 1
        elif isinstance(left, re.Pattern):
            return 1 if any(re.search(left, _str(i)) for i in right) else ''
        elif all(isinstance(i, (int, float, str)) for i in right):
            return 1 if left in right else ''
        else:
            return 1 if any(left == i for i in right) else ''
    elif callable(right):
        if (hasattr(left, 'isHash') and left.isHash) or (not hasattr(left, 'isHash') and isinstance(left, collections.abc.Mapping)):
            return 1 if all(right(i) for i in left.keys()) else ''
        elif isinstance(left, collections.abc.Iterable) and not isinstance(left, str):
            return 1 if all(right(i) for i in left) else ''
        return 1 if right(left) else ''
    elif isinstance(right, re.Pattern):
        if (hasattr(left, 'isHash') and left.isHash) or (not hasattr(left, 'isHash') and isinstance(left, collections.abc.Mapping)):
            return 1 if any(re.search(right, i) for i in left.keys()) else ''
        elif isinstance(left, collections.abc.Iterable) and not isinstance(left, str):
            return 1 if any(re.search(right, _str(i)) for i in left) else ''
        else:
            return 1 if re.search(right, _str(left)) else ''
    elif isinstance(right, (int, float)):
        return 1 if _num(left) == right else ''
    elif isinstance(left, (int, float)):
        return 1 if left == _num(right) else ''
    elif isinstance(right, str):
        return 1 if left == right else ''
    elif left is None:
        return 1 if right is None else ''
    else:
        return 1 if left == right else ''
