
def _maketrans_c(arg1, arg2, delete=False):
    """Make a complement tr table for the 'c' flag.  If the 'd' flag is passed, then delete=True.  Ranges are expanded in arg1 and arg2 but arg2 is not otherwise normalized"""
    t = str.maketrans(arg1, arg1)
    d = dict()
    for i in range(257):
        if i not in t:
            if not arg2:
                if delete:
                    d[i] = None
                else:
                    d[i] = i
            elif i < len(arg2):
                d[i] = arg2[i]
            elif delete:
                d[i] = None
            else:
                d[i] = arg2[-1]

    return str.maketrans(d)

