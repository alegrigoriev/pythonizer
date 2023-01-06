
def _utf8_upgrade(s):
    """Implementation of utf8::upgrade.  Returns a tuple with the result and the length"""
    result = str(s)
    return (result, len(result))
