
def _hires_clock_nanosleep(which, nanoseconds, flags=0):
    if flags:
        nanoseconds = (nanoseconds / 1_000_000_000 - tm_py.time()) * 1_000_000_000
    start_time = tm_py.time()
    if nanoseconds > 0:
        tm_py.sleep(nanoseconds / 1_000_000_000)
    if  flags:
        return tm_py.time() * 1_000_000_000
    return (tm_py.time() - start_time) * 1_000_000_000
