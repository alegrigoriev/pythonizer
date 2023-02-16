# Constants needed for the Time::HiRes module
# The functions are mostly in perllib proper
# NOTE: The 0 values are replaced by references to the python time package
# for those that are defined there.
# WARNING: DO NOT re-pythonizer this source, as the .py file was edited!!
# pragma pythonizer -aM
package Time::HiRes;
require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw( );
our @EXPORT_OK = qw (usleep sleep ualarm alarm gettimeofday time tv_interval
                 getitimer setitimer nanosleep clock_gettime clock_getres
                 clock clock_nanosleep
                 CLOCKS_PER_SEC
                 CLOCK_BOOTTIME
                 CLOCK_HIGHRES
                 CLOCK_MONOTONIC
                 CLOCK_MONOTONIC_COARSE
                 CLOCK_MONOTONIC_FAST
                 CLOCK_MONOTONIC_PRECISE
                 CLOCK_MONOTONIC_RAW
                 CLOCK_PROCESS_CPUTIME_ID
                 CLOCK_PROF
                 CLOCK_REALTIME
                 CLOCK_REALTIME_COARSE
                 CLOCK_REALTIME_FAST
                 CLOCK_REALTIME_PRECISE
                 CLOCK_REALTIME_RAW
                 CLOCK_SECOND
                 CLOCK_SOFTTIME
                 CLOCK_THREAD_CPUTIME_ID
                 CLOCK_TIMEOFDAY
                 CLOCK_UPTIME
                 CLOCK_UPTIME_COARSE
                 CLOCK_UPTIME_FAST
                 CLOCK_UPTIME_PRECISE
                 CLOCK_UPTIME_RAW
                 CLOCK_VIRTUAL
                 ITIMER_PROF
                 ITIMER_REAL
                 ITIMER_REALPROF
                 ITIMER_VIRTUAL
                 TIMER_ABSTIME
                 d_usleep d_ualarm d_gettimeofday d_getitimer d_setitimer
                 d_nanosleep d_clock_gettime d_clock_getres
                 d_clock d_clock_nanosleep d_hires_stat
                 d_futimens d_utimensat d_hires_utime
                 stat lstat utime
                );
 
our $VERSION = '1.9764';
sub CLOCKS_PER_SEC { 0 }
sub CLOCK_BOOTTIME { 0 }
sub CLOCK_HIGHRES { 0 }
sub CLOCK_MONOTONIC { 0 }
sub CLOCK_MONOTONIC_COARSE { 0 }
sub CLOCK_MONOTONIC_FAST { 0 }
sub CLOCK_MONOTONIC_PRECISE { 0 }
sub CLOCK_MONOTONIC_RAW { 0 }
sub CLOCK_PROCESS_CPUTIME_ID { 0 }
sub CLOCK_PROF { 0 }
sub CLOCK_REALTIME { 0 }
sub CLOCK_REALTIME_COARSE { 0 }
sub CLOCK_REALTIME_FAST { 0 }
sub CLOCK_REALTIME_PRECISE { 0 }
sub CLOCK_REALTIME_RAW { 0 }
sub CLOCK_SECOND { 0 }
sub CLOCK_SOFTTIME { 0 }
sub CLOCK_THREAD_CPUTIME_ID { 0 }
sub CLOCK_TIMEOFDAY { 0 }
sub CLOCK_UPTIME { 0 }
sub CLOCK_UPTIME_COARSE { 0 }
sub CLOCK_UPTIME_FAST { 0 }
sub CLOCK_UPTIME_PRECISE { 0 }
sub CLOCK_UPTIME_RAW { 0 }
sub CLOCK_VIRTUAL { 0 }
sub ITIMER_PROF { 1 }
sub ITIMER_REAL { 2 }
sub ITIMER_REALPROF { 3 }
sub ITIMER_VIRTUAL { 4 }
sub TIMER_ABSTIME { 1 }

# Methods that are not in perllib:
sub d_usleep { }
sub d_ualarm { }
sub d_gettimeofday { }
sub d_getitimer { }
sub d_setitimer{ }
sub d_nanosleep { }
sub d_clock_gettime { }
sub d_clock_getres{ }
sub d_clock { }
sub d_clock_nanosleep { }
sub d_hires_stat{ }
sub d_futimens { }
sub d_utimensat { }
sub d_hires_utime{ }
