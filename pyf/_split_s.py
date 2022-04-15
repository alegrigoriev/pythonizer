
def _split_s(pattern, string, maxsplit=0, flags=0):
    """Split function in perl is similar to re.split but not quite
       the same - this is the version used in scalar context"""
    result = re.split(pattern, string, max(0, maxsplit), flags)
    if len(result) >= 1 and result[0] == '' and (m:=re.match(pattern, string, flags)) and len(m.group(0)) == 0:
        result = result[1:]   # A zero-width match at the beginning of EXPR never produces an empty field
    if maxsplit >= -1:  # We subtracted one from what the user specifies
        limit = len(result)
        # Empty results at the end are eliminated
        for i in range(limit-1, -1, -1):
            if result[i] == '':
                limit -= 1
            else:
                break
        return limit
    return len(result)
