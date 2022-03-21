
_init_package('Data.Dumper')

Data.Dumper.Indent_v = 2
Data.Dumper.Trailingcomma_v = False
Data.Dumper.Purity_v = 0
Data.Dumper.Pad_v = ''
Data.Dumper.Varname_v = "VAR"
Data.Dumper.Useqq_v = 0
Data.Dumper.Terse_v = False
Data.Dumper.Freezer_v = ''
Data.Dumper.Toaster_v = ''
Data.Dumper.Deepcopy_v = 0
Data.Dumper.Quotekeys_v = 1
Data.Dumper.Bless_v = 'bless'
Data.Dumper.Pair_v = ':'
Data.Dumper.Maxdepth_v = 0
Data.Dumper.Maxrecurse_v = 1000
Data.Dumper.Useperl_v = 0
Data.Dumper.Sortkeys_v = 0
Data.Dumper.Deparse_v = False
Data.Dumper.Sparseseen_v = False

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
