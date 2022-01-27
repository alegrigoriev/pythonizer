
def _flatten(list):
    """Flatten a list down to 1 level"""
    result = []
    for elem in list:
        if hasattr(elem, 'isHash'):   # Array or Hash
            result = Array(result)
            if elem.isHash:
                for e in itertools.chain.from_iterable(elem.items()):
                    result.append(e)
            else:
                for e in elem:
                    result.append(e)
        elif isinstance(elem, collections.abc.Mapping):
            for e in itertools.chain.from_iterable(elem.items()):
                result.append(e)
        elif isinstance(elem, collections.abc.Iterable) and not isinstance(elem, str):
            for e in elem:
                result.append(e)
        else:
            result.append(elem)
    return result

