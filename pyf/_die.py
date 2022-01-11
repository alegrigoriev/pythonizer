
def _die(*args):
    """For when 'die' is used in a lambda function or expression"""
    m = ''.join(args)
    raise Die(m)
