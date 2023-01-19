
def _spaceship(a,b):
    """3-way comparison like the <=> operator in perl"""
    if hasattr(a, '__spaceship__'):
        return a.__spaceship__(b)
    if hasattr(b, '__rspaceship__'):
        return b.__rspaceship__(a)
    return (a > b) - (a < b)

