
def opendir(DIR):
    """Replacement for perl built-in directory function"""
    try:
        return [list(os.listdir(DIR)), 0]
    except Exception:
        return None    # sys.last_value will be set

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

