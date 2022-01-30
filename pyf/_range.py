
def _range(var, pat1, flags1, pat2, flags2, key):
    """The line-range operator.  See https://perldoc.perl.org/perlop#Range-Operators"""
    if not hasattr(_range, key):
        setattr(_range, key, 0)
    seq = getattr(_range, key)
    if isinstance(seq, str):        # e.g. nnE0
        setattr(_range, key, 0)
        return False

    if seq == 0:                    # Waiting for left to become True
        if isinstance(pat1, str):
            val = re.search(pat1, var, flags=flags1)
        else:
            val = bool(pat1)
        if not val:
            return False

    seq += 1                        # once left becomes True, then the seq starts counting, and we check right
    setattr(_range, key, seq)
    if isinstance(pat2, str):
        val = re.search(pat2, var, flags=flags2)
    else:
        val = bool(pat2)
    if val:
        seq = str(seq)+'E0'         # end marker
        setattr(_range, key, seq)
    return seq
