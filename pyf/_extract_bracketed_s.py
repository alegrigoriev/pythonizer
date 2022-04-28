
def _extract_bracketed_s(text, delimiters='{}()[]<>', prefix_pattern='^\s*'):
    """Implementation of Text::Bracketed::extract_bracketed in scalar context.  Returns a tuple with
    (updated_text, extracted_substring)"""
    open_to_close=dict()
    close_to_open=dict()
    if '{' in delimiters:
        open_to_close['{'] = '}'
        close_to_open['}'] = '{'
    if '(' in delimiters:
        open_to_close['('] = ')'
        close_to_open[')'] = '('
    if '[' in delimiters:
        open_to_close['['] = ']'
        close_to_open[']'] = '['
    if '<' in delimiters:
        open_to_close['<'] = '>'
        close_to_open['>'] = '<'

    stack = []

    if (_m := re.match(prefix_pattern, text)):
        text = text[len(_m.group(0)):]

    if not text or text[0] not in open_to_close:
        return (text, None)

    for i, c in enumerate(text):
        if c in open_to_close:
            stack.append(c)
        elif c in close_to_open:
            try:
                top = stack.pop()
                if top != close_to_open[c]:
                    return (text, None)
                if not stack:
                    return (text[i+1:], text[:i+1])
            except IndexError:
                return (text, None)
    return (text, None)
