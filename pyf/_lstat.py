
def _lstat(path):
    """Handle lstat call with or without "use File::stat;" """
    if isinstance(path, File_stat):
        return path     # for '_' special variable
    try:
        if hasattr(path, 'fileno') and os.lstat in os.supports_fd:
            path = path.fileno()
        elif hasattr(path, 'name'):
            path = path.name
        s = os.lstat(path)
    except Exception:
        return ()

    result = File_stat(_dev=s.st_dev, _ino=s.st_ino, _mode=s.st_mode,
            _nlink=s.st_nlink, _uid=s.st_uid, _gid=s.st_gid, 
            _rdev=s.st_rdev if hasattr(s, 'st_rdev') else 0,
            _size=s.st_size, _atime=s.st_atime, _mtime=s.st_mtime, _ctime=s.st_ctime,
            _blksize=s.st_blksize if hasattr(s, 'st_blksize') else 512,
            _blocks=s.st_blocks if hasattr(s, 'st_blocks') else s.st_size // 512)
    return result
