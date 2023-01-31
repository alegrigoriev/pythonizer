
def _exec(lst):
    """Implementation of perl exec with a list"""
    global OS_ERROR, TRACEBACK
    try:
        if isinstance(lst, str):
            lst = lst.split()
        program = lst[0]
        program = (program.split())[0]
        _execp(program, lst)
    except TypeError:
        OS_ERROR = "Undefined list on exec"
        if TRACEBACK:
            _cluck(f"exec({lst}) failed: {OS_ERROR}", skip=2)
    except IndexError:
        OS_ERROR = "Empty list on exec"
        if TRACEBACK:
            _cluck(f"exec({lst}) failed: {OS_ERROR}", skip=2)
    except Exception as _e:
        OS_ERROR = str(_e)
        if TRACEBACK:
            _cluck(f"exec({lst}) failed: {OS_ERROR}", skip=2)
