
def _exc(e):
    """Exception information like perl, e.g. message at issue_42.pl line 21."""
    try:
        m = str(e)
        if m.endswith('\n'):
            return m
        return f"{m} at {os.path.basename(sys.exc_info()[2].tb_frame.f_code.co_filename)} line {sys.exc_info()[2].tb_lineno}.\n"
    except Exception:
        return str(e)

