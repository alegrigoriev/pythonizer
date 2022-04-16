
def _set_breakpoint():
    """Sets a debugger breakpoint, but only if pdb is active, mimicking $DB::single"""
    if 'pdb' in sys.modules:
        import pdb
        pdb.set_trace()

