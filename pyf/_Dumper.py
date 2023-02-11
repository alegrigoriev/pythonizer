
_init_package('Data.Dumper')

Data.Dumper.Indent_v = 2 # InIt
Data.Dumper.Trailingcomma_v = False # InIt
Data.Dumper.Purity_v = 0 # InIt
Data.Dumper.Pad_v = '' # InIt
Data.Dumper.Varname_v = "VAR" # InIt
Data.Dumper.Useqq_v = 0 # InIt
Data.Dumper.Terse_v = False # InIt
Data.Dumper.Freezer_v = '' # InIt
Data.Dumper.Toaster_v = '' # InIt
Data.Dumper.Deepcopy_v = 0 # InIt
Data.Dumper.Quotekeys_v = 1 # InIt
Data.Dumper.Bless_v = 'bless' # InIt
Data.Dumper.Pair_v = ':' # InIt
Data.Dumper.Maxdepth_v = 0 # InIt
Data.Dumper.Maxrecurse_v = 1000 # InIt
Data.Dumper.Useperl_v = 0 # InIt
Data.Dumper.Sortkeys_v = 0 # InIt
Data.Dumper.Deparse_v = False # InIt
Data.Dumper.Sparseseen_v = False # InIt

def _Dumper(*args):
    """Implementation of Data::Dumper"""
    result = []
    pp = pprint.PrettyPrinter(indent=Data.Dumper.Indent_v, 
                       depth=None if Data.Dumper.Maxdepth_v==0 else Data.Dumper.Maxdepth_v,
                       compact=Data.Dumper.Terse_v,
                       sort_dicts=Data.Dumper.Sortkeys_v)
    for i, arg in enumerate(args, start=1):
        if Data.Dumper.Terse_v:
            result.append(f"{Data.Dumper.Pad_v}" + pp.pformat(arg))
        else:
            result.append(f"{Data.Dumper.Pad_v}{Data.Dumper.Varname_v}{i} = " + pp.pformat(arg))
    spacer = " " if Data.Dumper.Indent_v == 0 else "\n"
    return spacer.join(result)
