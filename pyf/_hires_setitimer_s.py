
def _hires_setitimer_s(which, floating_seconds, interval_floating_seconds=0):
    """Implementation of Time::HiRes::setitimer in scalar context"""
    return signal.setitimer(which, floating_seconds, interval_floating_seconds)[0]
