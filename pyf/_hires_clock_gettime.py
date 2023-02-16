
def _hires_clock_gettime(which):
    """Implementation of Time::HiRes::clock_gettime"""
    if not which or not hasattr(tm_py, 'clock_gettime'):
        return tm_py.time()
    return tm_py.clock_gettime(which)
