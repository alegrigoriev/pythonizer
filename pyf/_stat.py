
def stat_cando(self, mode, eff):
    if os.name == 'nt':
        if (self._mode & mode):
            return True
        return False
    uid = os.geteuid() if eff else os.getuid()
    def _ingroup(gid, eff):
        [egid, *supp] = os.getgrouplist(os.geteuid(), os.getegid())
        rgid = os.getgid()
        if gid == (egid if eff else rgid):
            return True
        if gid in supp:
            return True
        return False
    if uid == 0 or (sys.platform == 'cygwin' and _ingroup(544, eff)):    # Root
        if not (mode & 0o111):
            return True    # Not testing for executable: all file tests are true
        if (self._mode & 0o111) or stat.S_ISDIR(self._mode):
            return True
        return False
    if self._uid == uid:
        if (self._mode & mode):
            return True
    elif _ingroup(self._gid, eff):
        if (self._mode & (mode >> 3)):
            return True
    else:
        if (self._mode & (mode >> 6)):
            return True
    return False

@dataclasses.dataclass
class File_stat(collections.abc.Sequence):
    _dev: int
    _ino: int
    _mode: int
    _nlink: int
    _uid: int
    _gid: int
    _rdev: int
    _size: int
    _atime: int
    _mtime: int
    _ctime: int
    _blksize: int
    _blocks: int
    _item_map = {0:'_dev', 1:'_ino', 2:'_mode', 3:'_nlink', 4:'_uid', 5:'_gid',
            6:'_rdev', 7:'_size', 8:'_atime', 9:'_mtime', 10:'_ctime', 11:'_blksize', 12:'_blocks'}
    def dev(self):
        return self._dev
    def ino(self):
        return self._ino
    def mode(self):
        return self._mode
    def nlink(self):
        return self._nlink
    def uid(self):
        return self._uid
    def gid(self):
        return self._gid
    def rdev(self):
        return self._rdev
    def size(self):
        return self._size
    def atime(self):
        return self._atime
    def mtime(self):
        return self._mtime
    def ctime(self):
        return self._ctime
    def blksize(self):
        return self._blksize
    def blocks(self):
        return self._blocks
    def __len__(self):
        return len(self._item_map)
    def __getitem__(self, index):
        if isinstance(index, slice):
            return [self[i] for i in range(*index.indices(len(self)))]
        if index < 0:
            index += len(self)
        try:
            return getattr(self, self._item_map[index])
        except KeyError:
            raise IndexError('File_stat index out of range')
    def cando(self, mode, eff):
        return stat_cando(self, mode, eff)

def _stat(path):
    """Handle stat call with or without "use File::stat;" """
    if isinstance(path, File_stat):
        return path     # for '_' special variable
    try:
        s = os.stat(path)
    except Exception:
        return ()
    result = File_stat(_dev=s.st_dev, _ino=s.st_ino, _mode=s.st_mode,
            _nlink=s.st_nlink, _uid=s.st_uid, _gid=s.st_gid, 
            _rdev=s.st_rdev if hasattr(s, 'st_rdev') else 0,
            _size=s.st_size, _atime=s.st_atime, _mtime=s.st_mtime, _ctime=s.st_ctime,
            _blksize=s.st_blksize if hasattr(s, 'st_blksize') else 512,
            _blocks=s.st_blocks if hasattr(s, 'st_blocks') else s.st_size // 512)
    return result
