use CGI::Carp;
use Carp::Assert;

BEGIN {
    $| = 1;
    # Set the location of the HTTP server error log file
    $error_log_file = 'tmp.tmp';
    use CGI::Carp qw(carpout);
    open(LOG, '>', $error_log_file) or CORE::die "Unable to create tmp.tmp";
    LOG->autoflush(1);
    carpout(\*LOG);
}

sub test_cgi_carp {
  # Test that the carp function generates a warning message
  carp('This is a warning message');
  our_stderr;
  assert(message_displayed('This is a warning message'), 'carp function generated warning message');
  cgi_carp_stderr;

  # Test that the croak function generates an error message
  local *CGI::Carp::ineval = sub { 0 };     # Monkeypatch ineval
  eval { croak('This is an error message') };
  print STDERR $@;
  our_stderr;
  assert(message_displayed("This is an error message"), 'croak function generated error message');
  cgi_carp_stderr;

  eval { die 'This is a die message' };
  print STDERR $@;
  our_stderr;
  assert(message_displayed("This is a die message"), 'die generated error message');
  cgi_carp_stderr;

  my $nlines = lines_in_log_file();
  assert($nlines == 3, "Incorrect number of lines in log file, got $nlines, expecting 2!");
  unlink "tmp.tmp"; # Only unlink it if the test passes
}

*SAVERR;

sub cgi_carp_stderr {
   open(STDERR, ">&", SAVERR) or print "Can't restore CGI::Carp::STDERR\n";
}
sub our_stderr {
   open(SAVERR, ">&STDERR") or print "Can't save STDERR";
   open(STDERR, '>&', CGI::Carp::SAVEERR) or print "Can't restore STDERR\n";
}

test_cgi_carp();

sub message_displayed {
  my $msg = $_[0];
  # Open the error log file
  open(my $error_log, '<', $error_log_file) or print "Unable to open error log $error_log_file: $!\n";

  # Read the error log file line by line
  while (my $line = <$error_log>) {
    # Check whether the line contains a message and a valid timestamp
    if ($line =~ /^\[(.+?)\] $0: $msg at $0 line \d+\./i) {

      # Return true if the timestamp is valid
      close($error_log);
      return 1 if good_timestamp($1);
    }
  }

  # Return false if no warning message with a valid timestamp was found
  return 0;
}

sub good_timestamp {
      if($_[0] =~ /^(?:Sun|Mon|Tue|Wed|Thu|Fri|Sat) (?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec) [\s\d]\d \d\d:\d\d:\d\d 2\d\d\d/) {
          return 1;
      }
      #print "$_[0] is not a good timestamp!";
      return 0;
}

sub lines_in_log_file {
  # Open the error log file
  open(my $error_log, '<', $error_log_file) or print "Unable to open error log $error_log_file: $!\n";

  my $line_count = 0;
  # Read the error log file line by line
  while (my $line = <$error_log>) {
      $line_count++;
  }
  close($error_log);

  return $line_count;
}

#END {
#unlink $error_log_file;
#}

print "$0 - test passed\n";
