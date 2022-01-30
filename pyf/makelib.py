import re, os, subprocess
import sys, keyword, builtins
from time import ctime
OUTPUT_FILE="../perllib/__init__.py"

def main():
    """makelib: Used to generate the perllib for the pythonizer
       Takes all of the modules which are in individual source files and
       bundles them together into one file, stripping off the leading "_" in
       the definitions in also in internal calls.
    """
    global_defs = eval(subprocess.run("""perl get_globals.pl""", capture_output=True,text=True,check=True, shell=True).stdout)
    files = [file for file in os.listdir() if file.endswith('.py') and file != "makelib.py" and not file.startswith('__')]
    under_functions_list = [file.replace('.py', '') for file in files if file.startswith('_')]
    under_functions_regex = re.compile(r'\b(?:' + '|'.join(under_functions_list) + r')[(,]')

    def under_repl(m):
        """Remove underscores from function names in calls"""
        func = m.group(0)
        result = func[1:-1]
        if keyword.iskeyword(result) or hasattr(builtins, result):
            result += '_'
        return result + func[-1]

    with open(OUTPUT_FILE, 'w') as of:
        print(f'# perllib module for pythonizer, generated by {sys.argv[0]} on {ctime()}', file=of)
        print('#', file=of);
        print("# WARNING: Do not edit this file - to change the functions or add new ones, edit them in the pyf directory,", file=of)
        print("#          then re-run makelib.py", file=of)
        print('#', file=of);
        print('import sys,os,re,fileinput,subprocess,collections.abc,warnings,inspect,itertools,signal,traceback,io,tempfile,calendar,types,random,dataclasses,builtins', file=of)
        print('import time as tm_py', file=of)
        print('import stat as st_py', file=of)
        print('try:', file=of)
        print('    import fcntl', file=of)
        print('except Exception:', file=of)
        print('    pass', file=of)
        Die = """
class Die(Exception):
    def __init(self, *args):
        (super).__init__(*args)
        if TRACEBACK:
            traceback.print_stack()
"""
        print(Die, file=of)
        for definition, value in global_defs.items():
            if re.match(r'^_[a-z]', definition):    # Remove anything lowercase like _locals_stack
                continue
            value = value.replace("\n", r'\n')
            print(f"{definition} = {value}", file=of)
        print(file=of)

        for file in files:
            under_func = file.replace('.py','')
            func = under_func[1:]
            if keyword.iskeyword(func) or hasattr(builtins, func):     # e.g. import has to remain _import
                func += '_'
            with open(file, 'r') as fh:
                for line in fh:
                    #line = re.sub(r'\bint\(', 'builtins.int(', line)    # We have our own int (formerly _int)
                    #line = re.sub(r'\bopen\(', 'builtins.open(', line)    # We have our own open (formerly _int)
                    #line = re.sub(r', int\)', ', builtins.int)', line)    # Like isinstance(xxx, int)
                    #line = re.sub(r'\(int,', '(builtins.int,', line)    # Like isinstance(xxx, (int, float))
                    #line = re.sub(r': int$', ': builtins.int', line)    # Like dev: int
                    line = re.sub(r'\bstat[.]', r'st_py.', line)        # we have a 'stat' function, so we have to rename the stat class
                    if under_func.startswith('_') and re.match(r'def _', line):
                        line = line.replace(f'def {under_func}', f'def {func}')
                    #elif re.match(r'\s+global ', line):
                        #continue        # Eliminate 'global' lines
                    line = re.sub(under_functions_regex, under_repl, line)
                    print(line, file=of, end='')

if __name__ == '__main__':
    main()

