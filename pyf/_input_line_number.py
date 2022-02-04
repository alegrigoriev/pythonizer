
def _input_line_number(fh, value=None):
    """Implementation of perl input_line_number"""
    global INPUT_LINE_NUMBER
    if value is None:
        try:
            return fileinput.lineno()
        except RuntimeError:
            return INPUT_LINE_NUMBER
    else:
        prev = _input_line_number(fh)
        INPUT_LINE_NUMBER = value
        return prev
    
    
