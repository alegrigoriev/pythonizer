
def _subname(code):
    """Implementation of Sub::Util::subname"""
    def unescape(name):
        ns = name.split('.')
        result = []
        for n in ns:
            if n[-1] == '_' and n[:-1] in _PYTHONIZER_KEYWORDS:
                result.append(n[:-1])
            else:
                result.append(n)
        return '.'.join(result)

    name = unescape(code.__name__)
    if hasattr(builtins.main, name) and getattr(builtins.main, name) == code:
        return f"main::{name}"
    if hasattr(code, '__self__') and hasattr(code.__self__, '__PACKAGE__'):
        package = unescape(code.__self__.__PACKAGE__)
        return f"{package.replace('.', '::')}::{name}"

    for packagename in vars(builtins):
        namespace = getattr(builtins, packagename)
        if isinstance(namespace, type) or isinstance(namespace, types.SimpleNamespace):
            if hasattr(namespace, name):
                cd = getattr(namespace, name)
                if cd == code:
                    return f"{unescape(packagename).replace('.', '::')}::{name}"
                if hasattr(cd, '__func__'):
                    cd = cd.__func__
                if cd == code or (hasattr(code, '__func__') and cd == code.__func__):
                    return f"{unescape(packagename).replace('.', '::')}::{name}"

    return f"main::{name}"
