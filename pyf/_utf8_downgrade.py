
def _utf8_downgrade(s, fail_ok=False):
    """Implementation of utf8::downgrade.  Returns a tuple of string and success"""
    if fail_ok:
        try:
            result = str(s)
            return (result, 1)
        except Exception:
            return (s, 0)

    return (str(s), 1)
