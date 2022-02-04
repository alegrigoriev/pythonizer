
def _init_package(name):
    """Initialize a package by creating a namespace for it"""
    pieces = name.split('.')
    parent = builtins
    for piece in pieces:
        if not hasattr(parent, piece):
            namespace = types.SimpleNamespace()
            if hasattr(parent, '__PACKAGE__'):
                namespace.__PARENT__ = parent.__PACKAGE__
                namespace.__PACKAGE__ = parent.__PACKAGE__ + '.' + piece
            else:
                namespace.__PARENT__ = ''
                namespace.__PACKAGE__ = piece
            setattr(parent, piece, namespace)
            parent = namespace
