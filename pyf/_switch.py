
def _switch(s_val):
    """Implementation of switch/given statement in perl.  This
    returns a function that is called for each case."""
    def iter_to_bool(i):
        try:
            v = next(i)
            return True
        except StopIteration:
            return False

    if callable(s_val):
        def f_switch(c_val):
            if callable(c_val):
                return s_val == c_val
            if isinstance(c_val, collections.abc.Iterable) and not isinstance(c_val, str):
                return s_val(*c_val)
            return s_val(c_val)
        return f_switch
    elif isinstance(s_val, int) or isinstance(s_val, float):
        def n_switch(c_val):
            if isinstance(c_val, int) or isinstance(c_val, float):
                return s_val == c_val
            if callable(c_val):
                return c_val(s_val)
            if isinstance(c_val, collections.abc.Iterable) and not isinstance(c_val, str):
                if hasattr(c_val, 'isHash') and c_val.isHash:
                    return str(s_val) in c_val
                return s_val in c_val
            if isinstance(c_val, re.Pattern):
                return re.search(c_val, str(s_val))
            if isinstance(c_val, dict):
                return str(s_val) in c_val
            return str(s_val) == str(c_val)
        return n_switch
    elif isinstance(s_val, str):
        def s_switch(c_val):
            if (isinstance(c_val, collections.abc.Iterable) and not isinstance(c_val, str)) or isinstance(c_val, dict):
                return s_val in c_val       # list, Array, or Hash
            if callable(c_val):
                return c_val(s_val)
            if isinstance(c_val, re.Pattern):
                return re.search(c_val, s_val)
            return s_val == str(c_val)
        return s_switch
    elif isinstance(s_val, dict) and (not hasattr(s_val, 'isHash') or s_val.isHash):
        def h_switch(c_val):
            if isinstance(c_val, dict) and (not hasattr(c_val, 'isHash') or c_val.isHash):
                return s_val == c_val
            if isinstance(c_val, collections.abc.Iterable) and not isinstance(c_val, str):
                return iter_to_bool(filter(lambda _d: _d in s_val and s_val[_d], c_val))
            if callable(c_val):
                return c_val(s_val)
            if isinstance(c_val, re.Pattern):
                return iter_to_bool(filter(lambda _d: re.search(c_val, _d) and _d in s_val and s_val[_d], s_val.keys()))
            return str(c_val) in s_val and s_val[str(c_val)]
        return h_switch
    elif isinstance(s_val, collections.abc.Iterable) and (not hasattr(s_val, 'isHash') or not s_val.isHash):
        def a_switch(c_val):
            if isinstance(c_val, dict) and (not hasattr(c_val, 'isHash') or c_val.isHash):
                return iter_to_bool(filter(lambda _d: str(_d) in c_val and c_val[str(_d)], s_val))
            if isinstance(c_val, collections.abc.Iterable) and not isinstance(c_val, str):
                for item in s_val:
                    if item not in c_val:
                        return False
                return True
            if callable(c_val):
                return c_val(*(map(str, s_val)))
            if isinstance(c_val, re.Pattern):
                return iter_to_bool(filter(lambda _d: re.search(c_val, _d), map(str, s_val)))
            return c_val in s_val
        return a_switch
    elif isinstance(s_val, re.Pattern):
        def r_switch(c_val):
            if isinstance(c_val, dict) and (not hasattr(c_val, 'isHash') or c_val.isHash):
                return iter_to_bool(filter(lambda _d: re.search(s_val, _d) and c_val[_d], c_val.keys()))
            if isinstance(c_val, collections.abc.Iterable) and not isinstance(c_val, str):
                return iter_to_bool(filter(lambda _d: re.search(s_val, _d), map(str, c_val)))
            if callable(c_val):
                return c_val(s_val)
            if isinstance(c_val, re.Pattern):
                return s_val.pattern == c_val.pattern
            return re.search(s_val, str(c_val))
        return r_switch
    else:
        def n_switch(c_val):
            return False
        return n_switch
