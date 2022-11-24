
def _init_package(name, is_class=False, isa=(), autovivification=True):
    """Initialize a package by creating a namespace for it"""
    pieces = name.split('.')
    parent = builtins
    parent_name = ''
    package_name = ''
    for i, piece in enumerate(pieces):
        if hasattr(parent, piece):
            namespace = getattr(parent, piece)
        else:
            if is_class and i == len(pieces)-1:
                class_parents = []
                if autovivification:
                    class_parents.append(_ArrayHashClass)
                for p in isa:
                    py = p.replace("'", '.').replace('::', '.')
                    if hasattr(builtins, f"{py}_"):
                        py = f"{py}_"
                    if hasattr(builtins, py):
                        class_parents.append(getattr(builtins, py))
                if autovivification:
                    namespace = type(name, tuple(class_parents), Hash())
                else:
                    namespace = type(name, tuple(class_parents), dict())
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
    return namespace
