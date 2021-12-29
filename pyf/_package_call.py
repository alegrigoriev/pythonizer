
def _package_call(package, function, *args, **kwargs):
    """Call a function in a different package"""
    cur_package = builtins.__PACKAGE__
    try:
        builtins.__PACKAGE__ = package.__PACKAGE__
        return function(*args, **kwargs)
    finally:
        builtins.__PACKAGE = cur_package
