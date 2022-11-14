
_init_package('Getopt.Long')

def _preprocess_arguments():
    """Pre-process the command line arguments, changing -option to --option"""
    for i in range(1, len(sys.argv)):
        if len(sys.argv[i]) > 2 and sys.argv[i][0] == '-' and sys.argv[i][1] != '-':
            sys.argv[i] = '-' + sys.argv[i]
