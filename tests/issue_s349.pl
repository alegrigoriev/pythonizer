# issue s349 - Initializing a %hash with a qw(...) causes it to be an array
use Carp::Assert;
%Lang = qw(
            catalan     catalan
            ca          catalan

            danish      danish
            da          danish

            dutch       dutch
            nederlands  dutch
            nl          dutch

            english     english
            en          english
            en_us       english

            finnish     finnish
            fi          finnish
            fi_fi       finnish

            french      french
            fr          french
            fr_fr       french

            german      german
            de          german
            de_de       german

            italian     italian
            it          italian
            it_it       italian

            norwegian   norwegian
            nb          norwegian
            nb_no       norwegian

            polish      polish
            pl          polish
            pl_pl       polish

            portuguese  portugue
            pt          portugue
            pt_pt       portugue

            romanian    romanian
            ro          romanian
            ro_ro       romanian

            russian     russian
            ru          russian
            ru_ru       russian

            spanish     spanish
            es          spanish
            es_es       spanish

            swedish     swedish
            sv          swedish

            turkish     turkish
            tr          turkish
            tr_tr       turkish
         );

assert($Lang{en} eq 'english');
assert($Lang{italian} eq 'italian');
assert($Lang{fi} eq 'finnish');
assert(scalar(%Lang) == 45);

my ($v1, $v2, %ha) = qw(v1 v2 key value);
assert($v1 eq 'v1');
assert($v2 eq 'v2');
assert($ha{key} eq 'value');
assert(scalar(%ha) == 1);

my %qq = qw(' " " ' '" "');
assert($qq{'"'} eq "'");
assert($qq{"'"} eq '"');
assert($qq{"'\""} eq '"\'');
assert(scalar(%qq) == 3);

print "$0 - test passed!\n";
