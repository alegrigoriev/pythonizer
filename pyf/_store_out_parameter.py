
def _store_out_parameter(arglist, arg, value, shifts=0):
    """Store the value of a sub out parameter both in the arglist and in a
    location where _fetch_out_parameter can retrieve it after the sub returns.  arg
    is the argument index, starting at 0, and value is the value to be stored.
    shifts specifies the number of shift operations that have been performed
    on the arglist.  Returns the value."""
    if arglist is not None:
        arglist[arg] = value
    setattr(builtins,  f"__outp{arg+shifts}__", value)
    return value
