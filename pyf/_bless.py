
def _bless(obj, classname, isa=()):
    """Create an object for obj in classname"""
    if not isinstance(classname, str):
        if hasattr(classname, '__name__'):  # They sent us the class object
            classname = classname.__name__
        elif hasattr(classname, '__class__'): # They sent us an instance
            classname = classname.__class__.__name__
    if not hasattr(builtins, classname):
        _init_package(classname, is_class=True, isa=isa)
    result_class = getattr(builtins, classname)
    result = result_class()
    self = result
    if hasattr(obj, 'isHash'):
        if obj.isHash:
            result.isHash = True
            for key, value in obj.items():
                self[key] = value
        else:
            result.isHash = False
            for i, value in enumerate(obj):
                self[i] = value
    elif isinstance(obj, collections.abc.Mapping):
        for key, value in obj.items():
            self[key] = value
    elif isinstance(obj, collections.abc.Iterable) and not isinstance(obj, str):
        for i, value in enumerate(obj):
            self[i] = value
    elif WARNING:
        _carp(f"'bless' {classname} not implemented on {type(obj)} type object")

    return result
