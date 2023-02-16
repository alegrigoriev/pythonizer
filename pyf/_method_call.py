
def _method_call(cls_or_obj, methodname, *args, **kwargs):
    """Call a method by name in a class that can also be specified by name"""
    try:
        method = getattr(cls_or_obj, methodname)
        if hasattr(method, '__func__'):
            method = method.__func__
        return method(cls_or_obj, *args, **kwargs)
    except AttributeError:
        if isinstance(cls_or_obj, str):
            cls_or_obj = cls_or_obj.replace('::', '.')
            if hasattr(builtins, cls_or_obj):
                cls_or_obj = getattr(builtins, cls_or_obj)
                method = getattr(cls_or_obj, methodname)
                if hasattr(method, '__func__'):
                    method = method.__func__
                return method(cls_or_obj, *args, **kwargs)

    _cluck(f"Can't locate object method \"{methodname}\" via package \"{_str(cls_or_obj)}\"", skip=2)


