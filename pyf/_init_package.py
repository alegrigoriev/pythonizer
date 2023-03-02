
def _init_package(name, is_class=False, isa=(), autovivification=True):
    """Initialize a package by creating a namespace for it"""
    global TRACEBACK, AUTODIE, TRACE_RUN, WARNING
    if name == 'main':
        if (v := os.environ.get('PERLLIB_TRACEBACK')) is not None:
            TRACEBACK = int(v) if v.isdecimal() else 1
        if (v := os.environ.get('PERLLIB_AUTODIE')) is not None:
            AUTODIE = int(v) if v.isdecimal() else 1
        if (v := os.environ.get('PERLLIB_TRACE_RUN')) is not None:
            TRACE_RUN = int(v) if v.isdecimal() else 1
        if (v := os.environ.get('PERLLIB_WARNING')) is not None:
            WARNING = int(v) if v.isdecimal() else 1

    pieces = name.split('.')
    parent = builtins
    parent_name = ''
    package_name = ''
    class perllibMeta(abc.ABCMeta):
        def __str__(self):      # so str(class_v) works
            return self.__name__ if isinstance(self, type) else super().__str__()

    for i, piece in enumerate(pieces):
        prior_namespace = namespace = None
        if hasattr(parent, piece):
            namespace = getattr(parent, piece)
            if parent_name:
                package_name = parent_name + '.' + piece
            else:
                package_name = piece
            if (is_class or isa) and i == len(pieces)-1 and not isinstance(namespace, type):
                prior_namespace = namespace     # we have the wrong type of namespace - copy it over below
                namespace = None
        if namespace is None:
            if (is_class or isa) and i == len(pieces)-1:
                class_parents = []
                any_parent_is_class = False
                if not hasattr(builtins, 'UNIVERSAL'):
                    if autovivification:
                        builtins.UNIVERSAL = _ArrayHashClass
                    else:
                        builtins.UNIVERSAL = type('UNIVERSAL', tuple(), dict())
                for p in isa:
                    py = p.replace("'", '.').replace('::', '.')
                    if hasattr(builtins, f"{py}_"): # handle names that need to be escaped
                        py = f"{py}_"
                    if hasattr(builtins, py):
                        parent_namespace = getattr(builtins, py)
                        if not isinstance(parent_namespace, type):
                            # Promote the parent namespace to a class if it isn't one already
                            if autovivification:
                                new_parent_namespace = type(name, (_ArrayHashClass,), Hash())
                            else:
                                new_parent_namespace = type(name, tuple(), dict())
                            new_parent_namespace.__class__ = perllibMeta
                            new_parent_namespace.__eq__ = lambda self, other: self is other
                            for k, v in parent_namespace.__dict__.items():
                                setattr(new_parent_namespace, k, v)
                            parent_package_name = parent_namespace.__PACKAGE__
                            setattr(builtins, parent_package_name, new_parent_namespace)
                            setattr(builtins, f"main.{parent_package_name}", new_parent_namespace)
                            if(parent_namespace.__PARENT__):
                                ppn_pieces = parent_package_name.split('.')
                                grandparent_package_name = parent_namespace.__PARENT__
                                grandparent_namespace = getattr(builtins, grandparent_package_name)
                                setattr(grandparent_namespace, ppn_pieces[-1], new_parent_namespace)
                            parent_namespace = new_parent_namespace
                        if class_parents and type(class_parents[0]) != type(parent_namespace) and \
                           type(class_parents[0]).__name__ == type(parent_namespace).__name__:
                            # Avoid: TypeError: metaclass conflict: the metaclass of a derived class must be a (non-strict) subclass of the metaclasses of all its bases
                            parent_namespace.__class__ = class_parents[0].__class__
                        class_parents.append(parent_namespace)
                        if isinstance(parent_namespace, type):
                            any_parent_is_class = True
                if autovivification:
                    if is_class and not any_parent_is_class:
                        class_parents.append(_ArrayHashClass)
                    namespace = type(name, tuple(class_parents), Hash())
                else:
                    if is_class and not any_parent_is_class:
                        class_parents.append(builtins.UNIVERSAL)
                    namespace = type(name, tuple(class_parents), dict())

                if is_class or any_parent_is_class:
                    for key in dir(namespace):
                        if isinstance(getattr(namespace, key), types.MethodType):
                            setattr(namespace, key, types.MethodType(getattr(namespace, key).__func__, namespace))

                if is_class or any_parent_is_class:
                    namespace.__class__ = perllibMeta
                    namespace.__eq__ = lambda self, other: self is other
                if prior_namespace is not None:
                    for k, v in prior_namespace.__dict__.items():
                        setattr(namespace, k, v)

            else:
                namespace = types.SimpleNamespace()
                namespace.__autovivification__ = autovivification
            if parent_name:
                package_name = parent_name + '.' + piece
            else:
                package_name = piece
            namespace.__PARENT__ = parent_name
            namespace.__PACKAGE__ = package_name
            setattr(parent, piece, namespace)
            if parent != builtins:
                setattr(builtins, package_name, namespace)
                if pieces[0] != 'main':
                    if not hasattr(builtins, 'main'):
                        _init_package('main')
                    setattr(builtins.main, package_name, namespace)
                setattr(builtins, f"main.{package_name}", namespace)
            elif name != 'main':
                setattr(builtins, f"main.{piece}", namespace)
                if pieces[0] != 'main':
                    if not hasattr(builtins, 'main'):
                        _init_package('main')
                    setattr(builtins.main, piece, namespace)
        parent = namespace
        parent_name = package_name
    if not hasattr(builtins, '__packages__'):
        builtins.__packages__ = set()
    builtins.__packages__.add(name)
    return namespace
