
def _substr(this, start, length, replacement):
    """Handle substr with replacement - returns a tuple
       with (new_this, chars_removed)"""
    chars_removed = this[start:start+length]
    new_this = this[:start] + replacement + this[start+length:]
    return (new_this, chars_removed)
