# Test error produced on goto we don't handle

$i = 0;
LABEL:
$i++;
goto LABEL if $i < 10;
