
def _hires_ualarm(useconds, interval_useconds=0):
    """Implementation of Time::HiRes::ualarm"""
    return _hires_alarm(useconds / 1_000_000, interval_useconds / 1_000_000)
