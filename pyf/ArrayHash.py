
class _ArrayHash(collections.defaultdict, collections.abc.Sequence):
    """Implements autovivification of array elements and hash keys"""
    def __init__(self, fcn, isHash=None):
       self.isHash = isHash   # Can be None (not determined yet), False (is an Array), or True (is a Hash)
       super().__init__(fcn)

    def append(self, value):
        if self.isHash is None:
            self.isHash = False
        elif self.isHash:
            raise TypeError('Not an ARRAY reference')
        self[len(self)] = value

    def copy(self):
        if self.isHash:
            return Hash(self)
        elif self.isHash is None:
            return ArrayHash(self)
        else:
            return Array(self)

    def extend(self, lst):
        if self.isHash is None:
            self.isHash = False
        elif self.isHash:
            raise TypeError('Not an ARRAY reference')
        ln = len(self)
        for item in lst:
            self[ln] = item
            ln += 1

    def update(self, values):
        if self.isHash is None:
            self.isHash = True
        elif not self.isHash:
            raise TypeError('Not a HASH reference')
        for k, v in values.items():
            self[k] = v

    def pop(self, key=-1, default=None):
        if self.isHash:
            if key in self:
                value = self[key]
                del self[key]
                return value
            return default
        else:
            ls = len(self)
            if not ls:
                return None
            if key < 0:
                key += ls
            if key < ls:
                value = self[key]
                for i in range(key, ls-1):
                    self[i] = self[i+1]
                del self[ls-1]
                return value
            return None

    def __getitem__(self, index):
        if isinstance(index, slice):
            return Array([self[i] for i in range(*index.indices(len(self)))])
        elif isinstance(index, int):
            if self.isHash is None:
                self.isHash = False
            elif self.isHash:
                raise TypeError('Not an ARRAY reference')
            if index < 0:
                index += len(self)
            return super().__getitem__(index)
        else:
            if self.isHash is None:
                self.isHash = True
            elif not self.isHash:
                raise TypeError('Not a HASH reference')
            return super().__getitem__(index)

    def __setitem__(self, index, value):
        if isinstance(index, slice):
            if self.isHash is None:
                self.isHash = False
            elif self.isHash:
                raise TypeError('Not an ARRAY reference')
            for i in range(len(self), index.start):
                super().__setitem__(i, None)
            value = iter(value)
            ndx = index.start
            for i in range(*index.indices(len(self))):
                try:
                    super().__setitem__(i, next(value))
                except StopIteration:
                    self.pop(i)
                ndx += 1
            rest = list(value)
            lr = len(rest)
            if lr:
                for i in range(len(self)-1,ndx-1,-1):  # Move everything else up
                    super().__setitem__(i+lr, super().__getitem__(i))
            for i in range(lr):
                super().__setitem__(i+ndx, rest[i])
        elif isinstance(index, int):
            if self.isHash is None:
                self.isHash = False
            elif self.isHash:
                raise TypeError('Not an ARRAY reference')
            if index < 0:
                index += len(self)
            for i in range(len(self), index):
                super().__setitem__(i, None)
            super().__setitem__(index, value)
        else:
            if self.isHash is None:
                self.isHash = True
            elif not self.isHash:
                raise TypeError('Not a HASH reference')
            super().__setitem__(index, value)

    def __delitem__(self, index):
        if isinstance(index, slice):
            if self.isHash:
                raise TypeError('Not an ARRAY reference')
            for i in range(*index.indices(len(self))):
                super().__delitem__(i)
        elif isinstance(index, int):
            if self.isHash:
                raise TypeError('Not an ARRAY reference')
            ls = len(self)
            if not ls:
                return
            if index < 0:
                index += len(self)
            super().__delitem__(index)
        else:
            if not self.isHash:
                raise TypeError('Not a HASH reference')
            super().__delitem__(index)

    def __iter__(self):
        if self.isHash:
            for i in self.keys():
                yield i
        else:
            for i in range(len(self)):
                yield self[i]

    def __str__(self):
        if self.isHash:
            return str(dict(self))
        return str(list(self))

    def __repr__(self):
        if self.isHash:
            return "Hash(" + self.__str__() + ")"
        elif self.isHash is None:
            return "ArrayHash(" + self.__str__() + ")"
        return "Array(" + self.__str__() + ")"

    def __getattribute__(self, name):
        if name in ('keys', 'values', 'items') and not self.isHash:
            raise AttributeError
        return super().__getattribute__(name)

    def __add__(self, other):
        result = ArrayHash(self)
        if self.isHash or (isinstance(other, dict) and not isinstance(other, _ArrayHash)) or (hasattr(other, 'isHash') and other.isHash):
            result.update(other)
        else:
            result.extend(other)
        return result

    def __iadd__(self, other):
        if self.isHash or (isinstance(other, dict) and not isinstance(other, _ArrayHash)) or (hasattr(other, 'isHash') and other.isHash):
            self.update(other)
        else:
            self.extend(other)
        return self

    def __radd__(self, other):
        result = ArrayHash()
        if self.isHash or (isinstance(other, dict) and not isinstance(other, _ArrayHash)) or (hasattr(other, 'isHash') and other.isHash):
            result.update(other)
            result.update(self)
        else:
            result.extend(other)
            result.extend(self)
        return result

    def __eq__(self, other):
        try:
            if(len(self) != len(other)):
                return False
            i1 = iter(self)
            i2 = iter(other)
            while True:
                if next(i1) != next(i2):
                    return False
            return True
        except StopIteration:
            return True
        except Exception:
            return False

def ArrayHash(init=None,isHash=None):
    """Acts like an array or hash with autovivification"""
    result = _ArrayHash(ArrayHash,isHash=isHash)
    if init is not None:
        if isinstance(init, _ArrayHash):
            if init.isHash:
                result.update(init)
            else:
                result.extend(init)
        elif isinstance(init, collections.abc.Mapping):
            result.update(init)
        elif isinstance(init, collections.abc.Iterable) and not isinstance(init, str):
            result.extend(init)
        else:
            result.append(init)
    return result
