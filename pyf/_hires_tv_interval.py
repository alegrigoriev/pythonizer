
def _hires_tv_interval(t0, t1=None):
    """Implementation of Time::HiRes::tv_interval"""
    if t1 is None:
        t1 = _gettimeofday()
    return (t1[0] - t0[0]) + (t1[1] - t0[1]) / 1_000_000
