
def _can(self, methodname):
    """Implementation of CLASS::can and $obj->can"""
    if self is None:
        return None
    if isinstance(self, str):
        if hasattr(builtins, self):
            self = getattr(builtins, self)
    if hasattr(self, methodname):
        method = getattr(self, methodname)
        if callable(method):
            return method
    if methodname == 'can':
        return _can
    if methodname == 'isa':
        return _isa
    return None
