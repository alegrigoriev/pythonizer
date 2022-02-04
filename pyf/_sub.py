
def _sub():
    """Implementation of __SUB__ in perl"""
    try:
        frame = sys._getframe(1)
        name = frame.f_code.co_name
        return frame.f_globals[name]
    except Exception:
        return None
