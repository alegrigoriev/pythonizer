
def _syswrite(fh, scalar, length=None, offset=0):
    """Implementation of perl syswrite"""
    if length is None and hasattr(scalar, 'len'):
        length = len(scalar)-offset
    if isinstance(scalar, str):
        return os.write(fh.fileno(), scalar[offset:length+offset].encode())
    elif isinstance(scalar, bytes):
        return os.write(fh.fileno(), scalar[offset:length+offset])
    else:
        return os.write(fh.fileno(), str(scalar).encode())
