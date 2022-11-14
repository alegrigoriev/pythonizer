# issue s145 - complex nested hash/array initialization fails translation
# from netdb/dashboard/components/feed/src/xlsx2xml.pl
use Carp::Assert;
sub h2x {
   my ($id, $element_name, $element_type, $vendor, $region,$last_audit,$elements_audited,$discords,$parameters_audited,$failed_audits) = @_;

   my $data = {
        audit => {
                element => [
                        { id => $id ,
                             data =>
                                   [
                                       { last_audit => [$last_audit] ,
                                         elements_audited => [$elements_audited],
                                         discords => [$discords],
                                         parameters_audited => [$parameters_audited],
                                         weekly_audits => ['7'],
                                         audit_owner => ['1'],
                                         audit_owner_name => ['Tom'],
                                         compliance => ['50'],
                                         failed_audits => [$failed_audits],
                                         display_on => ['Y']
                                       }
                                   ],
                                    element_name => [$element_name],
                                    element_type => [$element_type],
                                    vendor => [$vendor],
                                    region => [$region]

                        },
                ],
        }
   };

   assert($data->{audit}->{element}->[0]->{id} == $id);
   assert($data->{audit}->{element}->[0]->{data}->[0]->{last_audit}->[0] == $last_audit);
   assert($data->{audit}->{element}->[0]->{element_name}->[0] eq $element_name);
}

h2x(1, 'name', 'type', 'vendor', 'region', 7, 'elements audited', 8, 9, 10);

print "$0 - test passed\n";
