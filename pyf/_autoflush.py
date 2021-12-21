
def _autoflush(self, arg=1):
    """Method added to FH to support OO perl"""
    orig = self._autoflush if hasattr(self, '_autoflush') else 0
    self._autoflush = arg
    if arg:
        self._orig_writelines = self.writelines
        def new_writelines(self, lines):
            self._orig_writelines(lines)
            self.flush()
        self.writelines = types.MethodType(new_writelines, self)
        if hasattr(self, 'write'):
            self._orig_write = self.write
            def new_write(self, b):
                result = self._orig_write(b)
                self.flush()
                return result
            self.write = types.MethodType(new_write, self)
    elif hasattr(self, '_orig_writelines'):
        self.writelines = self._orig_writelines
        if hasattr(self, '_orig_write'):
            self.write = self._orig_write
    return orig
