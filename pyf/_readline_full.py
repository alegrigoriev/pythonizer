
def _readline_full(fh):
    """Reads a line from a file, handles perl $/ and sets $. """
    global INPUT_RECORD_SEPARATOR, INPUT_LINE_NUMBER
    if INPUT_RECORD_SEPARATOR == "\n":
        result = fh.readline()
        if not result:
            return None
    elif INPUT_RECORD_SEPARATOR is None:
        result = fh.read()
    else:
        if not hasattr(fh, '_data'):
            fh._data = fh.read()
            fh._pos = 0
        irs = INPUT_RECORD_SEPARATOR
        if irs == '':       # paragraph mode
            pos = fh._pos
            while(fh._data[pos] == "\n"):
                pos += 1
            fh._pos = pos
            irs = "\n\n"
        pos = fh._pos
        ndx = fh._data.index(irs, pos)
        if ndx < 0:
            fh._pos = len(fh._data)
        fh._pos = ndx + len(irs)
        result = fh._data[pos:fh._pos]

    if not result:
        if hasattr(fh, '_data'):
            del fh._data
        if hasattr(fh, '_at_eof') and fh._at_eof:
            return None
        else:
            fh._at_eof = True
    else:
        fh._at_eof = False
    if not hasattr(fh, '_lno'):
        INPUT_LINE_NUMBER = fh._lno = 1
    else:
        fh._lno += 1
        INPUT_LINE_NUMBER = fh._lno
    return result

