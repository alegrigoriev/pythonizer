import os
import re
import inspect
import warnings
import signal
import numbers
from collections import defaultdict
import collections.abc
import functools
try:
    import fcntl
except ModuleNotFoundError:     # windows
    pass

"""Library used by pythonizer at runtime"""

OS_ERROR = 0
TRACEBACK = 0
AUTODIE = 0

class Num(numbers.Number):
    """Define a perl-style number, which can be in int, float, or string and will be converted
    to the proper type when used in operations"""

    @staticmethod
    def _num(expr):
        """Convert expr to a number"""
        if not expr:
            return 0
        if isinstance(expr, Num):
            expr = expr.value
        if isinstance(expr, (int, float)):
            return expr
        try:
            return int(expr)
        except Exception:
            pass
        try:
            f = float(expr)
            if f.is_integer():
                return int(f)
            return f
        except Exception:
            # Check for a prefix that's a float number, and return that
            # see: https://squareperl.com/en/how-perl-convert-string-to-number
            if (m:=re.match(r'^\s*([+-]?(?:\d+(?:[.]\d*)?(?:[eE][+-]?\d+)?|[.]\d+(?:[eE][+-]?\d+)?))', expr)):
                f = float(m.group(1))
                if f.is_integer():
                    return int(f)
            caller = inspect.getframeinfo(inspect.stack()[1][0])
            warnings.warn(f"Argument \"{expr}\" isn't numeric in numeric context at {caller.filename}:{caller.lineno}")
        return 0
    
    def __init__(self, value):
        self.value = self._num(value)

    def __add__(self, other):
        return self.value + self._num(other)
    def __sub__(self, other):
        return self.value - self._num(other)
    def __mul__(self, other):
        return self.value * self._num(other)
    def __truediv__(self, other):
        return self.value / self._num(other)
    def __floordiv__(self, other):
        return self.value // self._num(other)
    def __divmod__(self, other):
        return divmod(self.value, self._num(other))
    def __mod__(self, other):
        return self.value % self._num(other)
    def __pow__(self, other):
        return self.value ** self._num(other)
    def __lshift__(self, other):
        return int(self.value) << int(self._num(other))
    def __rshift__(self, other):
        return int(self.value) >> int(self._num(other))
    def __and__(self, other):
        return int(self.value) & int(self._num(other))
    def __or__(self, other):
        return int(self.value) | int(self._num(other))
    def __xor__(self, other):
        return int(self.value) ^ int(self._num(other))

    def __radd__(self, other):
        return self._num(other) + self.value
    def __rsub__(self, other):
        return self._num(other) - self.value
    def __rmul__(self, other):
        return self._num(other) * self.value
    def __rtruediv__(self, other):
        return self._num(other) / self.value
    def __rfloordiv__(self, other):
        return self._num(other) // self.value
    def __rdivmod__(self, other):
        return divmod(self._num(other), self)
    def __rmod__(self, other):
        return self._num(other) % self.value
    def __rpow__(self, other):
        return self._num(other) ** self.value
    def __rlshift__(self, other):
        return int(self._num(other)) << int(self.value)
    def __rrshift__(self, other):
        return int(self._num(other)) >> int(self.value)
    def __rand__(self, other):
        return int(self._num(other)) & int(self.value)
    def __ror__(self, other):
        return int(self._num(other)) | int(self.value)
    def __rxor__(self, other):
        return int(self._num(other)) ^ int(self.value)

    def __neg__(self):
        return - self.value
    def __pos__(self):
        return self.value
    def __abs__(self):
        return abs(self.value)
    def __invert__(self):
        return ~ int(self)
    def __int__(self):
        return int(self.value)
    def __float__(self):
        return float(self.value)
    def __index__(self):
        return int(self.value)
    def __str__(self):
        return str(self.value)
    def __bool__(self):
        return bool(self.value)
    def __hash__(self):
        return hash(self.value)
    def __lt__(self, other):
        return self.value < self._num(other)
    def __gt__(self, other):
        return self.value > self._num(other)
    def __le__(self, other):
        return self.value <= self._num(other)
    def __ge__(self, other):
        return self.value >= self._num(other)
    def __eq__(self, other):
        return self.value == self._num(other)
    def __ne__(self, other):
        return self.value != self._num(other)


class _ArrayHash(defaultdict, collections.abc.Sequence):
    def append(self, value):
        self[len(self)] = value

    def extend(self, lst):
        ln = len(self)
        for item in lst:
            self[ln] = item
            ln += 1

    def update(self, values):
        self.isHash = True
        for k, v in values.items():
            self[k] = v

    def __getitem__(self, index):
        if isinstance(index, slice):
            return [self[i] for i in range(*index.indices(len(self)))]
        elif isinstance(index, int):
            if index < 0:
                index += len(self)
            return super().__getitem__(index)
        else:
            self.isHash = True
            return super().__getitem__(index)

    def __setitem__(self, index, value):
        if isinstance(index, slice):
            try:
                if not hasattr(self, 'isHash'):
                    for i in range(len(self), index.start):
                        super().__setitem__(i, None)
                value = iter(value)
                ndx = index.start
                for i in range(*index.indices(len(self))):
                    super().__setitem__(i, next(value))
                    ndx += 1
                rest = list(value)
                lr = len(rest)
                if lr:
                    for i in range(len(self)-1,ndx-1,-1):  # Move everything else up
                        super().__setitem__(i+lr, super().__getitem__(i))
                for i in range(lr):
                    super().__setitem__(i+ndx, rest[i])
            except StopIteration:
                pass
        elif isinstance(index, int):
            if index < 0:
                index += len(self)
            if not hasattr(self, 'isHash'):
                for i in range(len(self), index):
                    super().__setitem__(i, None)
            super().__setitem__(index, value)
        else:
            self.isHash = True
            super().__setitem__(index, value)

    def __iter__(self):
        if hasattr(self, 'isHash'):
            for i in self.keys():
                yield i
        else:
            for i in range(len(self)):
                yield self[i]

    def __add__(self, other):
        result = ArrayHash(self)
        if hasattr(self, 'isHash') or (isinstance(other, dict) and not isinstance(other, _ArrayHash)) or hasattr(other, 'isHash'):
            result.update(other)
        else:
            result.extend(other)
        return result

    def __iadd__(self, other):
        if hasattr(self, 'isHash') or (isinstance(other, dict) and not isinstance(other, _ArrayHash)) or hasattr(other, 'isHash'):
            self.update(other)
        else:
            self.extend(other)
        return self

    def __radd__(self, other):
        result = ArrayHash()
        if hasattr(self, 'isHash') or (isinstance(other, dict) and not isinstance(other, _ArrayHash)) or hasattr(other, 'isHash'):
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


def ArrayHash(init=None,isHash=False):
    """Acts like an array with autovivification, unless you use a string as a key, then it becomes a hash"""
    result = _ArrayHash(ArrayHash)
    if isHash:
        result.isHash = True
    if init is not None:
        if isinstance(init, collections.abc.Sequence) and not isinstance(init, str):
            result.extend(init)
        elif isinstance(init, _ArrayHash):
            if(hasattr(init, 'isHash')):
                result.update(init)
            else:
                result.extend(init)
        elif isinstance(init, dict):
            result.update(init)
        else:
            result.append(init)
    return result



def _binmode(file,mode=None,encoding=None,errors=None):
    """Handle binmode"""
    global OS_ERROR, TRACEBACK, AUTODIE
    try:
        file.flush()
        omode = file.mode
        if mode is None:
            mode = omode.replace('b', '')
        else:
            mode = omode + mode
        if encoding is None:
            encoding = file.encoding
        if errors is None:
            errors = file.errors
        return os.fdopen(os.dup(file.fileno()), mode, encoding=encoding, errors=errors)
    except Exception as _e:
        OS_ERROR = str(_e)
        if TRACEBACK:
            traceback.print_exc()
        if AUTODIE:
            raise
        return None

def _cmp(a,b):
    """3-way comparison like the cmp operator in perl"""
    if a is None:
        a = ''
    if b is None:
        b = ''
    return (a > b) - (a < b)

def _die(message=None):
    """For when 'die' is used in a lambda function"""
    raise Die(message)

def _dup(file,mode):
    """Replacement for perl built-in open function when the mode contains '&'."""
    global OS_ERROR, TRACEBACK, AUTODIE
    try:
        if isinstance(file, io.IOBase):     # file handle
            file.flush()
            return os.fdopen(os.dup(file.fileno()), mode, encoding=file.encoding, errors=file.errors)
        if re.match(r'\d+', file):
            file = int(file)
        elif file in _DUP_MAP:
            file = _DUP_MAP[file]
        return os.fdopen(os.dup(file), mode)
    except Exception as _e:
        OS_ERROR = str(_e)
        if TRACEBACK:
            traceback.print_exc()
        if AUTODIE:
            raise
        return None


def _each(h_a):
    """See https://perldoc.perl.org/functions/each"""
    key = id(h_a)       # Unique memory address of object
    if not hasattr(_each, key):
        setattr(_each, key, iter(h_a))
    it = getattr(_each, key)
    try:
        v = next(it)
    except StopIteration:
        setattr(_each, key, iter(h_a))
        return []

    if isinstance(h_a, dict):
        return [v, h_a[v]]
    return v

def _exc(e):
    """Exception information like perl, e.g. message at issue_42.pl line 21."""
    global OS_ERROR
    try:
        OS_ERROR = m = str(e)
        if m.endswith('\n'):
            return m
        return f"{m} at {os.path.basename(sys.exc_info()[2].tb_frame.f_code.co_filename)} line {sys.exc_info()[2].tb_lineno}.\n"
    except Exception:
        return str(e)


def _fileparse(*args):
    """Split a path into basename, dirpath, and (optional) suffices"""
    fullname = args[0]
    suffices = args[1:]
    [dirpath,basename] = (_m:=re.search(re.compile(r'^(.*/)?(.*)',re.S),fullname),_m.groups() if _m else [None,None])[1]
    if not (dirpath):
        dirpath = './'

    tail=''
    suffix=''
    if suffices:
        for suffix in suffices:
            pat=f"({suffix})$"
            if (_m:=re.sub(re.compile(pat,re.S),r'',basename,count=1)):
                tail = _m.group(1) + tail

    return (basename, dirpath, tail)

def _flock(fd, operation):
    """ Replacement for perl Fcntl flock function"""
    global OS_ERROR, TRACEBACK, AUTODIE
    try:
        # To avoid the possibility of miscoordination, Perl now flushes FILEHANDLE before locking or unlocking it.
        fd.flush()
        fcntl.flock(fd, operation)
        return 1
    except Exception as _e:
        OS_ERROR = str(_e)
        if TRACEBACK:
            traceback.print_exc()
        if AUTODIE:
            raise
        return 0
    

def _getA(path):
    """perl -A: Get the start time of the script, minus the time of last
    access of path, in float days"""
    t = os.path.getatime(path)
    return (_script_start - t) / 86400.0
    

def _getC(path):
    """perl -C: Get the start time of the script, minus the time of last
    creation of path, in float days"""
    t = os.path.getctime(path)
    return (_script_start - t) / 86400.0
    

def _getM(path):
    """perl -M: Get the start time of the script, minus the time of last
    modification of path, in float days"""
    t = os.path.getmtime(path)
    return (_script_start - t) / 86400.0
    

def _getsignal(signum):
    """Handle references to %SIG not on the LHS of expression"""
    result = signal.getsignal(signum)
    if result == signal.SIG_IGN:
        return 'IGNORE'
    elif result == signal.SIG_DFL:
        return 'DEFAULT'
    return result


def _list_of_n(lst, n):
    """For assignment to (list, ...) - make this list the right size"""
    if lst is None:
        lst = []
    la = len(lst)
    if la == n:
        return lst
    if la > n:
        return lst[:n]
    return lst + [None for _ in range(n-la)]


def _make_list(expr):
    """For push/unshift @arr, expr;  We use extend/[0:0] so make sure expr is a list"""
    if isinstance(expr, collections.abc.Sequence) and not isinstance(expr, str):
        return expr
    return [expr]


def _flatten(list):
    """Flatten a list down to 1 level"""
    result = []
    for elem in list:
        if isinstance(elem, collections.abc.Sequence) and not isinstance(elem, str):
            for e in elem:
                result.append(e)
        elif isinstance(elem, dict):
            for e in functools.reduce(lambda x,y:x+y,elem.items()):
                result.append(e)
        else:
            result.append(elem)
    return result


def _mapf(func,arg):
    """Handle map with user function - in perl the global $_ is the arg"""
    global _d
    _d = arg
    return func([arg])


def _open(file,mode,encoding=None,errors=None):
    """Replacement for perl built-in open function when the mode is known."""
    global OS_ERROR, TRACEBACK, AUTODIE
    try:
        if mode == '|-':    # pipe to
            sp = subprocess.Popen(file, stdin=subprocess.PIPE, shell=True, text=True, encoding=encoding, errors=errors)
            if sp.returncode:
                raise Die(f"open(|{file}): failed with {sp.returncode}")
            return sp.stdin
        elif mode == '-|':  # pipe from
            sp = subprocess.Popen(file, stdout=subprocess.PIPE, shell=True, text=True, encoding=encoding, errors=errors)
            if sp.returncode:
                raise Die(f"open({file}|): failed with {sp.returncode}")
            return sp.stdout
        if file is None:
            return tempfile.TemporaryFile(mode=mode, encoding=encoding)
        return open(file,mode,encoding=encoding,errors=errors)
    except Exception as _e:
        OS_ERROR = str(_e)
        if TRACEBACK:
            traceback.print_exc()
        if AUTODIE:
            raise
        fh = io.StringIO()
        fh.close()
        return fh


def _open_dynamic(file,mode=None):
    """Replacement for perl built-in open function when the mode is unknown."""
    dup = None
    pipe = None
    if mode is None:
        m = re.match(r'^\s*([<>+|-]*)([&]?)\s*(.*?)\s*([|]?)\s*$', file)
        mode = m.group(1)
        dup = m.group(2)
        file = m.group(3)
        pipe = m.group(4)
    if mode == '<-':
        return sys.stdin
    if mode == '->':
        return sys.stdout
    ext = encoding = None
    if ':' in mode:
        mode, ext = mode.split(':')
    if mode in _OPEN_MODE_MAP:
        mode = _OPEN_MODE_MAP[mode]
        errors = None
        if ext:
            if ext == 'raw' or ext == 'bytes':
                mode += 'b'
            elif ext.startswith('encoding('):
                encoding = ext.replace('encoding(','').replace(')','')
            elif ext == 'utf8':
                encoding = 'UTF-8'
                errors = 'ignore'
        if dup:
            return _dup(file, mode,encoding=encoding,errors=errors)
        return _open(file, mode,encoding=encoding,errors=errors)
    if pipe:
        return _open(file, '-|')
    return _open(file, 'r')


def _perl_print(*args, **kwargs):
    """Replacement for perl built-in print function when used in an expression,
    where it must return True if successful"""
    global OS_ERROR, TRACEBACK, AUTODIE
    try:
        print(*args, **kwargs)
        return True
    except Exception as _e:
        OS_ERROR = str(_e)
        if TRACEBACK:
            traceback.print_exc()
        if AUTODIE:
            raise
        return False


def _range(var, pat1, flags1, pat2, flags2, key):
    """The line-range operator.  See https://perldoc.perl.org/perlop#Range-Operators"""
    if not hasattr(_range, key):
        setattr(_range, key, 0)
    seq = getattr(_range, key)
    if isinstance(seq, str):        # e.g. nnE0
        setattr(_range, key, 0)
        return False

    if seq == 0:                    # Waiting for left to become True
        if isinstance(pat1, str):
            val = re.search(pat1, var, flags=flags1)
        else:
            val = bool(pat1)
        if not val:
            return False

    seq += 1                        # once left becomes True, then the seq starts counting, and we check right
    setattr(_range, key, seq)
    if isinstance(pat2, str):
        val = re.search(pat2, var, flags=flags2)
    else:
        val = bool(pat2)
    if val:
        seq = str(seq)+'E0'         # end marker
        setattr(_range, key, seq)
    return seq

def _ref(r):
    """ref function in perl"""
    _ref_map = {"<class 'int'>": 'SCALAR', "<class 'str'>": 'SCALAR',
                "<class 'float'>": 'SCALAR', "<class 'NoneType'>": 'SCALAR',
                "<class 'list'>": 'ARRAY', "<class 'tuple'>": 'ARRAY',
                "<class 'dict'>": 'HASH'}
    t = str(type(r))
    if t in _ref_map:
        return _ref_map[t]
    return ''

def _reverse_scalar(expr):
    """reverse function implementation in scalar context"""
    if expr is None:
        return ''
    if isinstance(expr, dict):  # flatten hash (dict)
        expr = [_item for _k in expr for _item in (_k, expr[_k])]
    if isinstance(expr, collections.abc.Sequence) and not isinstance(expr, str):
        return ''.join(expr)[::-1]
    return expr[::-1]


def _set_last_ndx(arr, ndx):
    """Implementation of assignment to perl array last index $#array"""
    del arr[ndx+1:]
    for _ in range((ndx+1)-len(arr)):
        arr.append(None)


def _sortf(func,aa,bb):
    """Handle sort with user function - in perl the global $a and $b are compared"""
    global a, b
    a = aa
    b = bb
    return func([])


def _spaceship(a,b):
    """3-way comparison like the <=> operator in perl"""
    return (a > b) - (a < b)


def _time():
    """ Replacement for perl built-in time function"""
    return (tm_py.time_ns() // 1000000000)

def _wait():
    """Replacement for perl wait() call"""
    global CHILD_ERROR
    try:
        (pid, stat) = os.wait()
        CHILD_ERROR = stat
        return pid
    except Exception:
        return -1


def gmtime(secs=None):
    """Replacement for perl built-in gmtime function"""
    gmt = tm_py.gmtime(secs)
    return (gmt.tm_sec, gmt.tm_min, gmt.tm_hour, gmt.tm_mday, 
            gmt.tm_mon-1, gmt.tm_year-1900) 


def opendir(DIR):
    """Replacement for perl built-in directory functions"""
    global OS_ERROR, TRACEBACK, AUTODIE
    try:
        return [list(os.listdir(DIR)), 0]
    except Exception as _e:
        OS_ERROR = str(_e)
        if TRACEBACK:
            traceback.print_exc()
        if AUTODIE:
            raise
        return None

def readdir(DIR):
    try:
        result = (DIR[0])[DIR[1]]
        DIR[1] += 1
    except IndexError:
        return None

def telldir(DIR):
    return DIR[1]

def seekdir(DIR, pos):
    DIR[1] = pos

def rewinddir(DIR):
    DIR[1] = 0

def closedir(DIR):
    DIR[0] = None
    DIR[1] = None

def timelocal(sec, min, hour, mday, mon, year):
    """Replacement for perl built-in timelocal function"""
    return tm_py.mktime((year+1900, mon+1, mday, hour, min, sec, 0, 1, -1))

