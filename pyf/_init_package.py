
def _init_package(name):
    """Initialize a package by creating a namespace for it"""
    pieces = name.split('.')
    parent = builtins
    parent_name = ''
    package_name = ''
    for piece in pieces:
        if hasattr(parent, piece):
            namespace = getattr(parent, piece)
        else:
            namespace = types.SimpleNamespace()
            if parent_name:
                package_name = parent_name + '.' + piece
            else:
                package_name = piece
            namespace.__PARENT__ = parent_name
            namespace.__PACKAGE__ = package_name
            setattr(parent, piece, namespace)
            if parent != builtins:
                setattr(builtins, package_name, namespace)
        parent = namespace
        parent_name = package_name
