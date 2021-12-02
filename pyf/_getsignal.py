
def _getsignal(signum):
    """Handle references to %SIG not on the LHS of expression"""
    result = signal.getsignal(signum)
    if result == signal.SIG_IGN:
        return 'IGNORE'
    elif result == signal.SIG_DFL:
        return 'DEFAULT'
    return result

