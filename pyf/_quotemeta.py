
def _quotemeta(string):
    """Implementation of perl quotemeta - all chars not matching /[A-Za-z_0-9]/ will be preceded by a backslash"""
    return re.sub(r'([^A-Za-z_0-9])', r'\\\g<1>', string, count=0)
