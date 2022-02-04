
def _IOFile_tmpfile():
    """Implementation of IO::File->new_tmpfile"""
    fh = tempfile.NamedTemporaryFile()
    return _create_all_fh_methods(fh)
