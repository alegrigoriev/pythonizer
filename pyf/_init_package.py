
def _init_package(name):
    """Initialize a package by creating a namespace for it"""
    builtins.__PACKAGE__ = name
    if not hasattr(builtins, name):
        namespace = types.SimpleNamespace()
        namespace.__PACKAGE__ = name
        setattr(builtins, name, namespace)
