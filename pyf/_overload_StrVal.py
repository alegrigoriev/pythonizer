
def _overload_StrVal(obj):
    """Implementation of overload::StrVal($obj)"""
    cls = _ref_scalar(obj)
    if not cls:
        return obj
    if cls == 'ARRAY' or cls == 'HASH' or cls == 'CODE':
        return f"{cls}(0x{id(obj):x})"
    cls_type = 'HASH'
    if hasattr(obj, 'isHash') and not obj.isHash:
        cls_type = 'ARRAY'
    return f"{cls}={cls_type}(0x{id(obj):x})"
