# Issues with string escapes and interpolation in Eric's code
use Carp::Assert;

$s1 = "<input type=button value=\" Remove \" onClick=\"switchPartBox(form.value_list,form.v_fld,2,' ');\"";
assert($s1 eq q[<input type=button value=" Remove " onClick="switchPartBox(form.value_list,form.v_fld,2,' ');"]);

@desc=("DATE/TIME :");
${i} = 0;
$s2 = "<tr align=left><td><b>${desc[${i}]}</b></td>";
assert($s2 eq '<tr align=left><td><b>DATE/TIME :</b></td>');

print "$0 - test passed!\n";
