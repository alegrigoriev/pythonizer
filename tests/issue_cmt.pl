# lines from cmt that generate syntax errors

sub test {
   return if not grep /DC_$year$month$day$hour.*-ifStats_Juniper_5MIN/,@dirfiles;
}
   if (-M $otherfile < -M $currentfile) {
       ;
   }

   $SIG{ALRM} = sub { die "timeout"; };

   $s = sprintf("$_\n");
   $s = sprintf "$_\n";
   $s = sprintf "%s\n", $_;
   $s = sprintf("%s\n", $_);
   printf(OUT "$_\n");
   printf(LOG "DC_info ($hour:$min:$sec): $_[0]");

   	if ($action eq "save" && ! -e $name) {
		system("scp -p $other:$name $name");
	} elsif ($action eq "delete" && -e $name &&
	  $name !~ /\/\.\.\// &&
	  ($name =~ /cmtweb.users.*saved/ ||
	   $name =~ /cmtweb.fareports/ ||
	   $name =~ /cmtweb.hotspotreports/)) {
		system("rm $name");
         }

   push @{$static{$r}{$ip}},$i;
   push @{$vrf2rt{$r}{$vrf}},$rt;

   &DCinfo("Running: $0 @ARGV\n");
   
   next if not exists $bundles{$cttmembers{$key}};
   next if exists $bidsinterface{$node}{$name}; 

   next unless exists $estimated_dmd{$d} && exists $gravity{$p} ||
		exists $estimated_fdmd{$d} && exists $nfdmd{$p};

    ($commented_timestamp = $PROPERTIES_ln ) if ( $. == 1 ) ;
    ($retVal = 1) if ($status == 0); # if successful

   $fh = IO::File->new_tmpfile or &DCerror("Unable to make new temporary file: $!") ;
   $fh->autoflush(1); 

    return $_ if /^\d{8}\/$type$/;

    @files=`$options{bin}/sftplist $remote $remotedir "$fname" 2>/dev/null`;

sub process_file
{     # Next/last breaks you out of any block, not just loops
      # if it's at the sub level, just change it to a "return"
      # else change all empty blocks to a "try:... finally: pass" 
      # and make this raise a catched exception
       next if not $in =~ /(flows)\.(\d+)\.gz/;
       last if($in eq '');
       if($in eq 'if_stmt') {
           next if $in =~ /next if/;
           $i = 4;
           last if $in =~ /last if/;
       }
       next;
       last;
       return;
}

{
    # here is a block that we will "next" and "last" out of
    $i = 1;
    next if($i == 1);
    $i = 2;
    last if($i == 2);
    $i = 3;
    next;
    last;
    return;
}

LINE: while(<>) {
    next LINE if /^#/;  # discard comments
}

goto SKIP_THIS_STUFF;
OUTER: 
for($i = 0; $i < 10; $i++) {
    INNER: 
    for($j = 0; $j < 10; $j++) {
        last OUTER if($i == $j);
    }
}

SKIP_THIS_STUFF: ;

$i = 0;
do {
    $i++;
} until ($i == 10);

   my $ua = LWP::UserAgent->new;

   $num{$key}{$hour} = 12;
   $num{$key}{$hour}++;
   --$num{$key}{$hour};
   if($num{$key}{$hour}++ == 12) {
       ;
   }
   if(--$num{$key}{$hour} == 12) {
       ;
   }

   foreach ($n=1; $n<=30; $n++)
   {
       ;
   }
   for ($n=1; $n<=30; $n++)
   {
       ;
   }

      my @sequence = sort bynum keys %{$routespans{$rin}};

            $interfaces{$key}{vrf} = $line[($dir =~ /agnip$/) ? 21:24];

sub deletefiles
{
   foreach $file (glob("$ldir/*/d2*.*.Z"))
   {
      next if not
         $file =~ /^$ldir\/(\d{4})(\d{2})(\d{2})\/d2*\.\d{2}\.Z$/;

      `rm $file`
         if $t-timegm(0,0,0,$3,$2-1,$1-1900) > $options{maxage}*24*60*60;
   }
}

		my %hop = ( 	"AClli" => $AClli,
			"ZClli" => $ZClli,
			"ID" => $circuitRow[$colNames{"ID"}],
			"mileage" => $circuitRow[$colNames{"mileage"}], 
			"type" => $circuitRow[$colNames{"type"}]
		);

      if (exists $atm{$r}{$vpi}{$vci})
      {
         $i = $atm{$r}{$vpi}{$vci};
      }

sub make_location_header
{
   $locdat = "CTTPS:Location\n";
   $locdat .= "#PlanVersion    RunID   Clli    Longitude       Latitude\n";
}

=head1 NAME

setroutes.pl - Set preferred routes for PVCs

=cut


# Generate bad code:

umask(022);

# We should guess this is an email address by looking at the char prior to @:
$options{other} = "m66828@zlp23061.vci.att.com";

sub makebytes
{
   local *LOG;

   open(LOG, '<', 'myfile.f') or die("Can't open myfile.f");
}

sub getTmpFileName {
    my $fileName;
    do { $fileName = POSIX::tmpnam() }
    until $fh = IO::File->new($fileName, O_RDWR|O_CREAT|O_EXCL);

#    END { unlink($fileName) };
    return $fileName;
	  
}

next if not open(CACHE_LOCK,"<$cachelock");
next if not flock(CACHE_LOCK, LOCK_SH|LOCK_NB);

open(TM_LOCK,">$lockfile") or die("cannot open $lockfile");
next if not flock(TM_LOCK,LOCK_EX|LOCK_NB);

sub ddd { die "not_timeout"; }

   $SIG{ __DIE__ } = sub { Carp::confess( @_ ) };	# SNOOPYJC
   $SIG{ INT } = sub { Carp::confess( @_ ) };		# SNOOPYJC
   $| = 1;                                              # SNOOPYJC - unbuffer STDOUT
   $SIG{ __DIE__ } = 'DEFAULT';

$s = $SIG{ALRM};
$my_flag = 0;
$SIG{ALRM} = sub { $my_flag = 1; };
$SIG{ALRM} = sub { $my_flag++; };
$SIG{ALRM} = $s;
$SIG{ALRM} = 'WHO KNOWS';
$SIG{ALRM} = 'IGNORE';
$SIG{ALRM} = 'DEFAULT';
$SIG{ALRM} = sub { die "timeout"; };

$retval = 0;

eval
{
 alarm($TIME);

 # to test the failure condition, uncomment the following sleep command...

 #sleep $TIME;

# system ("ssh -l $user $system date >/dev/null 2>/dev/null");

if ($interfacev eq "v1.0a") {
  $rc = system ("ssh -l $user $system date >/dev/null 2>/dev/null"); 
}
else{
  $rc = system ("echo vdate | ssh -l $user $system >/dev/null 2>/dev/null");
}
$retval = 1 if ($rc > 0); 

 alarm(0);

};

if ($@)
{
 if ($@ =~ /timeout/)
 {
  # timed out

  $retval = 1;
 }
 else
 {
  alarm (0);

  die;
 }

}

exit($retval);

sub test_os_error_in_sub
{
    open(FH, "<", "file");
    print "$!\n";
}

sub bynum
{
   $a <=> $b;
}   

my @sequence = sort bynum keys %{$routespans{$rin}};

foreach $seq (reverse sort {$a<=>$b} keys %{$rinspans{$rin}})
{
    ;
}

sub threeargs($$$) {
    $arg1 = shift;
    $arg2 = shift;
    $arg3 = shift;
    return $arg1+$arg2-$arg3;
}
