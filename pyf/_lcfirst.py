
def _lcfirst(string):
    """Implementation of lcfirst and \l in interpolated strings: lowercase the first char of the given string"""
    return string[0:1].lower() + string[1:]
