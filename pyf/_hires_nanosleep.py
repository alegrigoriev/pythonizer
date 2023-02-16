
def _hires_nanosleep(nanoseconds):
    """Implementation of Time::HiRes::nanosleep"""
    tm_py.sleep(nanoseconds / 1_000_000_000)

