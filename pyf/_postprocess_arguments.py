
def _postprocess_arguments(parser, parser_rem):
    """After argument parsing, see if we have any leftover arguments and
    flag those as errors"""
    errors = ''
    for arg in parser_rem:
        if len(arg) != 0 and arg[0] == '-':
            errors += f"Unknown option: {re.sub(r'^-*', '', arg)}\n"

    if errors:
        if parser.exit_on_error:
            print(errors, file=sys.stderr, end='')
            sys.exit(1)
        raise argparse.ArgumentError(None, errors)

