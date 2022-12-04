
def _fetch_out_parameter(arg):
    """Fetch the value of a sub out parameter from the
    location where _store_out_parameter saved it.  This is called after 
    the sub returns.  arg is the argument index, starting at 0.  
    Returns the value we saved."""
    try:
        result = getattr(builtins,  f"__outp{arg}__")
        delattr(builtins,  f"__outp{arg}__")
        return result
    except Exception:
        return None

