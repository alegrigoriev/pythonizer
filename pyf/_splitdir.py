
def _splitdir(*_args):
    """Implementation of File::Spec->splitdir"""
    return _split(r"/", _str(_args[0]), -1 - 1)  # Preserve trailing fields

