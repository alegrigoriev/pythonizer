
def _flatten(lst):
    """Flatten a list down to 1 level"""
    result = []
    if (not isinstance(lst, collections.abc.Iterable)) or isinstance(lst, str):
        return [lst]
    for elem in lst:
        if hasattr(elem, 'isHash'):   # Array or Hash
            result = Array(result)
            if elem.isHash:
                for e in itertools.chain.from_iterable(elem.items()):
                    result.extend(_flatten(e))
            else:
                for e in elem:
                    result.extend(_flatten(e))
        elif isinstance(elem, collections.abc.Mapping):
            for e in itertools.chain.from_iterable(elem.items()):
                result.extend(_flatten(e))
        elif isinstance(elem, collections.abc.Iterable) and not isinstance(elem, str):
            for e in elem:
                result.extend(_flatten(e))
        else:
            result.append(elem)
    return result

