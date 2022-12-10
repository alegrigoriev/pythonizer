
def _fetch_out_parameters(var, start=0):
    """Fetch the values of all sub out parameters from the
    location where _store_out_parameter saved them.  This is called after 
    the sub returns.  var is the array or hash to store them in. start is 
    the argument starting index, defaulting to 0.
    Returns the array or hash we saved."""
    if (hasattr(var, 'isHash') and var.isHash) or (not hasattr(var, 'isHash') and isinstance(var, collections.abc.Mapping)):
        ln = len(var.keys())
        var_copy = var.copy()
        var.clear()
        missing = 0;
        for arg in range(0, ln*2, 2):
            try:
                key = getattr(builtins,  f"__outp{arg+start}__")
                delattr(builtins,  f"__outp{arg+start}__")
                var[key] = getattr(builtins, f"__outp{arg+start+1}__")
                delattr(builtins,  f"__outp{arg+start+1}__")
            except Exception:
                missing += 1
        if missing:
            for k,v in var_copy.items():
                if k not in var:
                    var[k] = v
                    missing -= 1
                    if missing == 0:
                        break
        
    else:
        ln = len(var)
        var_copy = var.copy()
        var.clear()
        for arg in range(0, ln):
            try:
                var.append(getattr(builtins,  f"__outp{arg+start}__"))
                delattr(builtins,  f"__outp{arg+start}__")
            except Exception:
                var.append(var_copy[arg])
    return var

