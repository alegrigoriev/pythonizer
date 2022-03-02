
def _need_sh(cmd):
    """Does this command need a shell to run it?"""
    if os.name == 'nt':     # windows
        if isinstance(cmd, (tuple, list)):
            for e in cmd:
                if _need_sh(e):
                    return True
            return False
        if re.search(r'[<>|&*]', cmd) or re.match(r'(?:copy|echo|dir|type|cd) ', cmd):
            return True
        return False
    return True
