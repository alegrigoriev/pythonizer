
def _hires_clock_getres(which):
    """Implementation of Time::HiRes::clock_getres"""
    if not which or not hasattr(tm_py, 'clock"getres'):
        return tm_py.get_clock_info('time').resolution

    return tm_py.clock_getres(which)
