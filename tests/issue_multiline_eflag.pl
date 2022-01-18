# Multi-line regex with e flag didn't work
use Carp::Assert;

# From Config_heavy.pl:
$summary_expanded = '';
sub myconfig {
    return $summary_expanded if $summary_expanded;
    ($summary_expanded = $summary) =~ s{\$(\w+)}
		 {
			my $c;
			if ($1 eq 'git_ancestor_line') {
				if ($Config::Config{git_ancestor}) {
					$c= "\n  Ancestor: $Config::Config{git_ancestor}";
				} else {
					$c= "";
				}
			} else {
                     		$c = $Config::Config{$1};
			}
			defined($c) ? $c : 'undef'
		}ge;
    $summary_expanded;
}
$summary_expanded = 'passed';

assert(myconfig() eq 'passed');

print "$0 - test passed\n";
