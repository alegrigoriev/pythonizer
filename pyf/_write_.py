
def _write_(fh, scalar, length=None, offset=0):
    """Implementation of perl $fh->write"""
    if length is None and hasattr(scalar, 'len'):
        length = len(scalar)-offset
    if 'b' in fh.mode:
        if isinstance(scalar, str):
            return fh.write(scalar[offset:length+offset].encode())
        elif isinstance(scalar, bytes):
            return fh.write(scalar[offset:length+offset])
        return fh.write(str(scalar).encode())
    else:
        if isinstance(scalar, str):
            return fh.write(scalar[offset:length+offset])
        elif isinstance(scalar, bytes):
            return fh.write(scalar[offset:length+offset].decode())
        return fh.write(str(scalar))

