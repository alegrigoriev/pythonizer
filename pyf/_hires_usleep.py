
def _hires_usleep(useconds):
    """Implementation of Time::HiRes::usleep"""
    tm_py.sleep(useconds / 1_000_000)
