
def _hires_stat(path):
    """Implementation of Time::HiRes::stat"""
    try:
        if hasattr(path, 'fileno') and os.stat in os.supports_fd:
            path = path.fileno()
        elif hasattr(path, 'name'):
            path = path.name
        s = os.stat(path)
    except Exception:
        return ()
    result = (s.st_dev, s.st_ino, s.st_mode,
              s.st_nlink, s.st_uid, s.st_gid, 
              s.st_rdev if hasattr(s, 'st_rdev') else 0,
              s.st_size, 
              s.st_atime_ns / 1_000_000_000,
              s.st_mtime_ns / 1_000_000_000, 
              s.st_ctime_ns / 1_000_000_000,
              s.st_blksize if hasattr(s, 'st_blksize') else 512,
              s.st_blocks if hasattr(s, 'st_blocks') else s.st_size // 512)
    return result
