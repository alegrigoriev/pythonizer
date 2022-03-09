
def _handle_open_pragma(mode, encoding, errors):
    """Handle any "use open" pragma that may be in effect"""
    if encoding is not None:
        return (mode, encoding, errors)
    layers = None
    if ('r' in mode or mode == '-|') and INPUT_LAYERS:
        layers = INPUT_LAYERS
    elif OUTPUT_LAYERS:
        layers = OUTPUT_LAYERS
    else:
        return (mode, encoding, errors)

    layers = layers.replace(':', '')
    if layers == 'raw' or layers == 'bytes':
        if 'b' not in mode:
            mode += 'b'
    elif layers.startswith('encoding('):
        encoding = layers.replace('encoding(','').replace(')','')
        errors = 'replace'
    elif layers == 'utf8':
        encoding = 'UTF-8'
        errors = 'ignore'

    return (mode, encoding, errors)
