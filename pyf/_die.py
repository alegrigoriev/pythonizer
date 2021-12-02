
def _die(message=None):
    """For when 'die' is used in a lambda function"""
    raise Die(message)
