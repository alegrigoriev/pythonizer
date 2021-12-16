
def _flatten(list):
    """Flatten a list down to 1 level"""
    result = []
    for elem in list:
        if isinstance(elem, collections.abc.Sequence) and not isinstance(elem, str):
            for e in elem:
                result.append(e)
        elif isinstance(elem, dict):
            for e in functools.reduce(lambda x,y:x+y,elem.items()):
                result.append(e)
        else:
            result.append(elem)
    return result

