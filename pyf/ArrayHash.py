
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
        if self.isHash:
            try:
                return super().__getitem__(index)
            except (TypeError, KeyError):
                return super().__getitem__(str(index))
        elif self.isHash is None:
            if isinstance(index, int) or isinstance(index, slice):
                self.isHash = False
            else:
                self.isHash = True
                try:
                    return super().__getitem__(index)
                except TypeError:
                    return super().__getitem__(str(index))
        if isinstance(index, int):
            if index < 0:
                index += len(self)
            return super().__getitem__(index)
        elif isinstance(index, slice):
            return Array([self[i] for i in range(*index.indices(len(self)))])
        else:
            raise TypeError('Not a HASH reference')

    def __setitem__(self, index, value):
        if self.isHash:
            try:
                super().__setitem__(index, value)
            except TypeError:
                super().__setitem__(str(index), value)
            return
        elif self.isHash is None:
            if isinstance(index, int) or isinstance(index, slice):
                self.isHash = False
            else:
                self.isHash = True
                try:
                    super().__setitem__(index, value)
                except TypeError:
                    super().__setitem__(str(index), value)
        if isinstance(index, int):
            if index < 0:
                index += len(self)
            for i in range(len(self), index):
                super().__setitem__(i, None)
            super().__setitem__(index, value)
            return
        elif isinstance(index, slice):
            for i in range(len(self), index.start):
                super().__setitem__(i, None)
            value = iter(value)
            ndx = index.start
            j = None
            for i in range(*index.indices(len(self))):
                try:
                    super().__setitem__(i, next(value))
                except StopIteration:
                    if j is None:
                        j = i
                    self.pop(j)
                ndx += 1
            rest = list(value)
            lr = len(rest)
            if lr:
                for i in range(len(self)-1,ndx-1,-1):  # Move everything else up
                    super().__setitem__(i+lr, super().__getitem__(i))
            for i in range(lr):
                super().__setitem__(i+ndx, rest[i])

    def __delitem__(self, index):
        if self.isHash:
            try:
                super().__delitem__(index)
            except (TypeError, KeyError):
                super().__delitem__(str(index))
        elif isinstance(index, int):
            if self.isHash:
                raise TypeError('Not an ARRAY reference')
            ls = len(self)
            if not ls:
                return
            if index < 0:
                index += len(self)
            super().__delitem__(index)
        elif isinstance(index, slice):
            if self.isHash:
                raise TypeError('Not an ARRAY reference')
            for i in range(*index.indices(len(self))):
                super().__delitem__(i)

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
        elif self.isHash is None:
            return ''
        return str(list(self))

    def __repr__(self):
        if self.isHash:
            return "Hash(" + self.__str__() + ")"
        elif self.isHash is None:
            return "ArrayHash(" + self.__str__() + ")"
        return "Array(" + self.__str__() + ")"

#    def __getattribute__(self, name):
#        if name in ('keys', 'values', 'items') and not self.isHash:
#            #raise AttributeError
#            def inner():
#                return []
#            return inner
#        return super().__getattribute__(name)

    def __add__(self, other):
        result = ArrayHash(self)
        if self.isHash or (isinstance(other, dict) and not isinstance(other, _ArrayHash)) or (hasattr(other, 'isHash') and other.isHash):
            result.update(other)
        elif self.isHash is None and isinstance(other, (int, float, str)):
            return other
        else:
            result.extend(other)
        return result

    def __iadd__(self, other):
        if self.isHash or (isinstance(other, dict) and not isinstance(other, _ArrayHash)) or (hasattr(other, 'isHash') and other.isHash):
            self.update(other)
        elif self.isHash is None and isinstance(other, (int, float, str)):
            return other
        else:
            self.extend(other)
        return self

    def __radd__(self, other):
        result = ArrayHash()
        if self.isHash or (isinstance(other, dict) and not isinstance(other, _ArrayHash)) or (hasattr(other, 'isHash') and other.isHash):
            result.update(other)
            result.update(self)
        elif self.isHash is None and isinstance(other, (int, float, str)):
            return other
        else:
            result.extend(other)
            result.extend(self)
        return result

    def __eq__(self, other):
        if self.isHash is None:
            if hasattr(other, 'isHash') and other.isHash is None:
                return True
            try:
                return '' == other
            except Exception:
                pass
            try:
                return 0 == other
            except Exception:
                pass
            try:
                return 0 == len(other)
            except Exception:
                pass
            if other is None:
                return True
            return False
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

    def __lt__(self, other):
        if self.isHash is None:
            if hasattr(other, 'isHash') and other.isHash is None:
                return False
            try:
                return '' < other
            except Exception:
                pass
            try:
                return 0 < other
            except Exception:
                pass
            try:
                return 0 < len(other)
            except Exception:
                pass
            if other is None:
                return False
            return False
        try:
            i1 = iter(self)
            i2 = iter(other)
            while True:
                ni1 = next(i1)
                try:
                    ni2 = next(i2)
                except StopIteration:
                    return False
                if ni1 < ni2:
                    return True
                elif ni1 > ni2:
                    return False
        except StopIteration:
            try:
                next(i2)
            except StopIteration:
                return False
            return True
        except Exception:
            return False

    def __ne__(self, other):
        return not self == other
    def __le__(self, other):
        return self < other or self == other
    def __ge__(self, other):
        return not self < other
    def __gt__(self, other):
        return not (self < other or self == other)

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
