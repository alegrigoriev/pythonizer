
def _prep_import(filepath):
    """Prepare a filepath for import by getting the abspath, splitting
    it from the filename, and removing any extension.  Returns a tuple of
    the path and the filename"""
    return os.path.split(os.path.splitext(os.path.abspath(filepath))[0])


