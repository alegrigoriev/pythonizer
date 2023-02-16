
def _hires_alarm(floating_seconds, interval_floating_seconds=0):
    """Implementation of Time::HiRes::alarm"""
    if interval_floating_seconds == 0:
        tm_py.alarm(floating_seconds)
        return floating_seconds
    else:
        import threading
        def send_sigalrm(start_time, interval):
            signal.raise_signal(signal.SIGALRM)
            current_time = tm_py.time()
            elapsed_time = current_time - start_time
            next_interval = interval - (elapsed_time % interval)
            t = threading.Timer(next_interval, send_sigalrm, [start_time, interval])
            t.start()

        start_time = tm_py.time() + floating_seconds
        t = threading.Timer(floating_seconds, send_sigalrm, [start_time, interval_floating_seconds])
        t.start()
        return floating_seconds
