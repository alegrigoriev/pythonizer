
def _nr():
    """Get the current INPUT_LINE_NUMBER"""
    try:
        return fileinput.lineno()
    except RuntimeError:
        return INPUT_LINE_NUMBER
