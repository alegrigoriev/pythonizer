
def _ungetc(fh, ordinal):
    """Implementation of perl $fh->ungetc method"""
    # We only support putting back what was there after a getc
    if hasattr(fh, "_last_pos"):    # Set by _getc
        fh.seek(fh._last_pos, 0)
        ch = fh.read(1)
        if ch == chr(ordinal):
            fh.seek(fh._last_pos, 0)
            delattr(fh, "_last_pos")
            return
        else:
            fh.seek(0, 2)

    raise NotImplementedError
