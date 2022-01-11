
def stat_cando(self, mode, eff):
    if os.name == 'nt':
        if (self.mode & mode):
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
        if (self.mode & 0o111) or stat.S_ISDIR(self.mode):
            return True
        return False
    if self.uid == uid:
        if (self.mode & mode):
            return True
    elif _ingroup(self.gid, eff):
        if (self.mode & (mode >> 3)):
            return True
    else:
        if (self.mode & (mode >> 6)):
            return True
    return False

@dataclasses.dataclass
class File_stat(collections.abc.Sequence):
    dev: int
    ino: int
    mode: int
    nlink: int
    uid: int
    gid: int
    rdev: int
    size: int
    atime: int
    mtime: int
    ctime: int
    blksize: int
    blocks: int
    _item_map = {0:'dev', 1:'ino', 2:'mode', 3:'nlink', 4:'uid', 5:'gid',
            6:'rdev', 7:'size', 8:'atime', 9:'mtime', 10:'ctime', 11:'blksize', 12:'blocks'}
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
    result = File_stat(dev=s.st_dev, ino=s.st_ino, mode=s.st_mode,
            nlink=s.st_nlink, uid=s.st_uid, gid=s.st_gid, 
            rdev=s.st_rdev if hasattr(s, 'st_rdev') else 0,
            size=s.st_size, atime=s.st_atime, mtime=s.st_mtime, ctime=s.st_ctime,
            blksize=s.st_blksize if hasattr(s, 'st_blksize') else 512,
            blocks=s.st_blocks if hasattr(s, 'st_blocks') else s.st_size // 512)
    return result
