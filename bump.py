# Bump the pythonizer version

from datetime import date
import shutil
import yaml
import re

with open('bump.yaml', 'r') as conf:
    config = yaml.safe_load(conf)

today = date.today()

for file in config.keys():
    shutil.copy2(file, file+'.bak')
    print(f'Backing {file} up to {file}.bak')
    patterns = config[file]
    with open(file+'.bak', 'r') as inf:
        with open(file, 'w') as out:
            for line in inf:
                action = ''
                new_line = ''
                for pattern, act in patterns.items():
                    if (m:=re.search(pattern, line)):
                        action = act
                        for i, grp in enumerate(m.groups(), start=1):
                            if (m2:=re.match(r'(\d+)\.(\d\d\d)', grp)):   # Version
                                vers = int(m2.group(2))
                                bump = f'{vers+1:03d}'
                                print(f'In {file}, bumped version to {m2.group(1)}.{bump}')
                                new_line = new_line + m2.group(1) + '.' + bump
                            elif re.match(r'\d\d\d\d\/\d\d\/\d\d', grp):    # YYYY/MM/DD
                                dt = today.strftime("%Y/%m/%d")
                                new_line = new_line + dt
                            elif re.match(r'\d\d\d\d-\d\d-\d\d', grp):    # YYYY-MM-DD
                                dt = today.strftime("%Y-%m-%d")
                                new_line = new_line + dt
                            elif re.match(r'[A-Z][a-z][a-z] \d*, \d\d\d\d', grp):   # Mon DD, YYYY
                                dt = today.strftime("%b %d, %Y").replace(' 0', ' ')
                                new_line = new_line + dt
                            elif i == 1:
                                new_line = new_line + line[0:m.end(i)]
                            else:
                                new_line = new_line + line[m.end(i-1):m.end(i)]
                        if new_line[-1] != "\n":
                            new_line += "\n"

                if action == 'replace':
                    print(new_line, end='', file=out)
                elif action == 'append':
                    print(line, end='', file=out)
                    print(new_line, end='', file=out)
                elif action == 'history':
                    print(new_line, end='', file=out)
                    print('------------------', file=out)
                    print(file=out)
                    print('* ', file=out)
                    print(file=out)
                    print(line, end='', file=out)
                else:
                    print(line, end='', file=out)







