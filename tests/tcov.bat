REM Test Coverage generator for Pythonizer
REM cover -delete
REM Run the modules thru
for /f %%f IN ('dir /b *.pm') do perl -MDevel::Cover ..\pythonizer %%f
REM Now run the rest of the tests thru
for /f %%f IN ('dir /b *.pl') do perl -MDevel::Cover ..\pythonizer %%f
cover
