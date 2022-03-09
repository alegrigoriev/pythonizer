
_init_package('Data.Dumper')

Data.Dumper.Indent = 2
Data.Dumper.Trailingcomma = False
Data.Dumper.Purity = 0
Data.Dumper.Pad = ''
Data.Dumper.Varname = "VAR"
Data.Dumper.Useqq = 0
Data.Dumper.Terse = False
Data.Dumper.Freezer = ''
Data.Dumper.Toaster = ''
Data.Dumper.Deepcopy = 0
Data.Dumper.Quotekeys = 1
Data.Dumper.Bless = 'bless'
Data.Dumper.Pair = ':'
Data.Dumper.Maxdepth = 0
Data.Dumper.Maxrecurse = 1000
Data.Dumper.Useperl = 0
Data.Dumper.Sortkeys = 0
Data.Dumper.Deparse = False
Data.Dumper.Sparseseen = False

def _Dumper(*args):
    """Implementation of Data::Dumper"""
    result = []
    pp = pprint.PrettyPrinter(indent=Data.Dumper.Indent, 
                       depth=None if Data.Dumper.Maxdepth==0 else Data.Dumper.Maxdepth,
                       compact=Data.Dumper.Terse,
                       sort_dicts=Data.Dumper.Sortkeys)
    for i, arg in enumerate(args, start=1):
        if Data.Dumper.Terse:
            result.append(f"{Data.Dumper.Pad}" + pp.pformat(arg))
        else:
            result.append(f"{Data.Dumper.Pad}{Data.Dumper.Varname}{i} = " + pp.pformat(arg))
    spacer = " " if Data.Dumper.Indent == 0 else "\n"
    return spacer.join(result)
