
def _substitute_and_count(this, that, var, replace=True, count=0):
    """Perform a re substitute, but also count the # of matches"""
    (result, ctr) = re.subn(this, that, var, count=count)
    if not replace:
        return (var, result)
    return (result, ctr)
