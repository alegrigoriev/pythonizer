
def _rand(expr=0):
    """Implementation of perl rand function"""
    if expr == 0:
        expr = 1
    return random.random() * expr

