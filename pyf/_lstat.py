
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

    result = File_stat(dev=s.st_dev, ino=s.st_ino, mode=s.st_mode,
            nlink=s.st_nlink, uid=s.st_uid, gid=s.st_gid, 
            rdev=s.st_rdev if hasattr(s, 'st_rdev') else 0,
            size=s.st_size, atime=s.st_atime, mtime=s.st_mtime, ctime=s.st_ctime,
            blksize=s.st_blksize if hasattr(s, 'st_blksize') else 512,
            blocks=s.st_blocks if hasattr(s, 'st_blocks') else s.st_size // 512)
    return result
