
def _abspath(*args):
    """Implementation of perl Cwd::abs_path function"""
    if len(args) == 0:
        return os.path.abspath(os.getcwd())
    return os.path.abspath(args[0])
