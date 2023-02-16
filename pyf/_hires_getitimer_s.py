
def _hires_getitimer_s(which):
    """Implementation of Time::HiRes::getitimer in scalar context"""
    return signal.getitimer(which)[0]
