
def _hires_gettimeofday():
    """Implementation of Time::HiRes::gettimeofday in list context"""
    current_time = tm_py.time()
    seconds, fraction = divmod(current_time, 1)
    microseconds = int(fraction * 1_000_000)
    return (seconds, microseconds)
