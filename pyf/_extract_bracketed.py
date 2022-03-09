
def _extract_bracketed(text, delimiters='{}()[]<>', prefix_pattern='^\s*'):
    """Implementation of Text::Bracketed::extract_bracketed in list context.  Returns a list with
    (extracted_substring, updated_text, skipped_prefix)"""
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

    prefix = ''
    orig_text = text
    if (_m := re.match(prefix_pattern, text)):
        prefix = _m.group(0)
        text = text[len(prefix):]

    if not text or text[0] not in open_to_close:
        return [None, orig_text, None]

    for i, c in enumerate(text):
        if c in open_to_close:
            stack.append(c)
        elif c in close_to_open:
            try:
                top = stack.pop()
                if top != close_to_open[c]:
                    return [None, orig_text, None]
                if not stack:
                    return [text[:i+1], text[i+1:], prefix]
            except IndexError:
                return [None, orig_text, None]
    return [None, orig_text, None]
