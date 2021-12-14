 [Softpano-W317]:  Debug flag is set to 5


PYTHONIZER: Fuzzy translator of Python to Perl. Version 0.924 (mtime 211213_0111) Started at 21/12/13 01:31

Logs are at /tmp/Pythonizer/pythonizer.211213_0131.log. Type -h for help.
=============================================================================================================
Results of transcription are written to the file  issue_95.py
=========================================================================================================================

Lexem 0 Current token='c' perl='use' value='NoTrans!' Tokenstr |c| translated: NoTrans!
Lexem 1 Current token='i' perl='Carp::Assert' value='Carp.Assert' Tokenstr |ci| translated: NoTrans! Carp.Assert
Use of uninitialized value $Perlscan::nesting_last in concatenation (.) or string at /d/pythonizer/pythonizer/Perlscan.pm line 522, <> line 2.
Got ; balance=0, tno=2, nesting_last=
Lexem 0 Current token='t' perl='my' value='' Tokenstr |t| translated: 
Lexem 1 Current token='s' perl='$t' value='t' Tokenstr |ts| translated:  t
Lexem 2 Current token='=' perl='=' value='=' Tokenstr |ts=| translated:  t =
Lexem 3 Current token='d' perl='1' value='1' Tokenstr |ts=d| translated:  t = 1
Use of uninitialized value $Perlscan::nesting_last in concatenation (.) or string at /d/pythonizer/pythonizer/Perlscan.pm line 522, <> line 4.
Got ; balance=0, tno=4, nesting_last=
check_ref(main, t) at 1
expr_type(3, 3, main)
merge_types(t, main, I)
Lexem 0 Current token='c' perl='if' value='if ' Tokenstr |c| translated: if 
Lexem 1 Current token='(' perl='(' value='(' Tokenstr |c(| translated: if  (
Lexem 2 Current token='s' perl='$t' value='t' Tokenstr |c(s| translated: if  ( t
Lexem 3 Current token='>' perl='==' value='==' Tokenstr |c(s>| translated: if  ( t ==
Lexem 4 Current token='d' perl='1' value='1' Tokenstr |c(s>d| translated: if  ( t == 1
Lexem 5 Current token=')' perl=')' value=')' Tokenstr |c(s>d)| translated: if  ( t == 1 )
enter_block at line 5, prior nesting_level=0, ValPerl=if ( $t == 1 ) {
Use of uninitialized value in join or string at /d/pythonizer/pythonizer/Perlscan.pm line 372, <> line 5.
nesting_info=cur_sub  is_loop  in_sub 0 in_loop 0 is_sub  lno 5 is_eval  type if  level 0
check_ref(main, t) at 2
scalar_reference_type(2) = I
Lexem 0 Current token='s' perl='$t' value='t' Tokenstr |s| translated: t
Lexem 1 Current token='=' perl='=' value='=' Tokenstr |s=| translated: t =
Lexem 2 Current token='d' perl='2' value='2' Tokenstr |s=d| translated: t = 2
Got }, tno=3, source=}
Got }, tno=3, ValClass=s = d }, source=}
parens_are_balanced
check_ref(main, t) at 0
expr_type(2, 2, main)
merge_types(t, main, I)
merge_types: otype=I
expr_type(0, 2, main)
Got }, tno=0, source=}
exit_block at line 7, prior nesting_level=1
Lexem 0 Current token='c' perl='assert' value='assert' Tokenstr |c| translated: assert
Lexem 1 Current token='(' perl='(' value='(' Tokenstr |c(| translated: assert (
Lexem 2 Current token='s' perl='$t' value='t' Tokenstr |c(s| translated: assert ( t
Lexem 3 Current token='>' perl='==' value='==' Tokenstr |c(s>| translated: assert ( t ==
Lexem 4 Current token='d' perl='2' value='2' Tokenstr |c(s>d| translated: assert ( t == 2
Lexem 5 Current token=')' perl=')' value=')' Tokenstr |c(s>d)| translated: assert ( t == 2 )
Got ; balance=0, tno=6, nesting_last=HASH(0x8001f93d8)
check_ref(main, t) at 2
scalar_reference_type(2) = I
Lexem 0 Current token='t' perl='my' value='' Tokenstr |t| translated: 
Lexem 1 Current token='s' perl='$ctr' value='ctr' Tokenstr |ts| translated:  ctr
Lexem 2 Current token='=' perl='=' value='=' Tokenstr |ts=| translated:  ctr =
Lexem 3 Current token='d' perl='0' value='0' Tokenstr |ts=d| translated:  ctr = 0
Got ; balance=0, tno=4, nesting_last=HASH(0x8001f93d8)
check_ref(main, ctr) at 1
expr_type(3, 3, main)
merge_types(ctr, main, I)
Lexem 0 Current token='c' perl='for' value='for' Tokenstr |c| translated: for
Lexem 1 Current token='s' perl='$i' value='i' Tokenstr |cs| translated: for i
Lexem 2 Current token='(' perl='(' value='(' Tokenstr |cs(| translated: for i (
Lexem 3 Current token='d' perl='0' value='0' Tokenstr |cs(d| translated: for i ( 0
Lexem 4 Current token='r' perl='..' value='..' Tokenstr |cs(dr| translated: for i ( 0 ..
Lexem 5 Current token='d' perl='5' value='5' Tokenstr |cs(drd| translated: for i ( 0 .. 5
Lexem 6 Current token=')' perl=')' value=')' Tokenstr |cs(drd)| translated: for i ( 0 .. 5 )
enter_block at line 11, prior nesting_level=0, ValPerl=for $i ( 0 .. 5 ) {
Use of uninitialized value in join or string at /d/pythonizer/pythonizer/Perlscan.pm line 372, <> line 11.
nesting_info=lno 11 is_eval  type for level 0 cur_sub  is_loop 1 in_sub 0 in_loop 1 is_sub 
check_ref(main, i) at 1
expr_type(2, 6, main)
expr_type(3, 5, main)
merge_types(i, main, u)
enter_block at line 12, prior nesting_level=1, ValPerl={
Use of uninitialized value in join or string at /d/pythonizer/pythonizer/Perlscan.pm line 372, <> line 12.
nesting_info=is_eval  lno 12 type { level 1 cur_sub  in_loop 1 is_sub  is_loop 1 in_sub 0
Lexem 0 Current token='s' perl='$ctr' value='ctr' Tokenstr |s| translated: ctr
Lexem 1 Current token='^' perl='++' value='+=1' Tokenstr |s^| translated: ctr +=1
Got }, tno=2, source=}
Got }, tno=2, ValClass=s ^ }, source=}
parens_are_balanced
check_ref(main, ctr) at 0
merge_types(ctr, main, I)
merge_types: otype=I
expr_type(0, 1, main)
Got }, tno=0, source=}
exit_block at line 14, prior nesting_level=2
Lexem 0 Current token='c' perl='if' value='if ' Tokenstr |c| translated: if 
Lexem 1 Current token='(' perl='(' value='(' Tokenstr |c(| translated: if  (
Lexem 2 Current token='s' perl='$i' value='i' Tokenstr |c(s| translated: if  ( i
Lexem 3 Current token='>' perl='==' value='==' Tokenstr |c(s>| translated: if  ( i ==
Lexem 4 Current token='d' perl='0' value='0' Tokenstr |c(s>d| translated: if  ( i == 0
Lexem 5 Current token=')' perl=')' value=')' Tokenstr |c(s>d)| translated: if  ( i == 0 )
enter_block at line 15, prior nesting_level=1, ValPerl=if ( $i == 0 ) {
Use of uninitialized value in join or string at /d/pythonizer/pythonizer/Perlscan.pm line 372, <> line 15.
nesting_info=cur_sub  in_loop 1 is_sub  is_loop  in_sub 0 is_eval  lno 15 type if  level 1
check_ref(main, i) at 2
scalar_reference_type(2) = I
merge_types(i, main, I)
merge_types: otype=u
Lexem 0 Current token='k' perl='next' value='continue' Tokenstr |k| translated: continue
Got }, tno=1, source=} elsif(0) {
Got }, tno=1, ValClass=k }, source=} elsif(0) {
parens_are_balanced
Got }, tno=0, source=} elsif(0) {
exit_block at line 17, prior nesting_level=2
Lexem 0 Current token='C' perl='elsif' value='elif ' Tokenstr |C| translated: elif 
Lexem 1 Current token='(' perl='(' value='(' Tokenstr |C(| translated: elif  (
Lexem 2 Current token='d' perl='0' value='0' Tokenstr |C(d| translated: elif  ( 0
Lexem 3 Current token=')' perl=')' value=')' Tokenstr |C(d)| translated: elif  ( 0 )
enter_block at line 17, prior nesting_level=1, ValPerl=elsif ( 0 ) {
Use of uninitialized value in join or string at /d/pythonizer/pythonizer/Perlscan.pm line 372, <> line 17.
nesting_info=level 1 type elif  lno 17 is_eval  in_sub 0 is_loop  is_sub  in_loop 1 cur_sub 
Lexem 0 Current token='k' perl='next' value='continue' Tokenstr |k| translated: continue
Got }, tno=1, source=} else {
Got }, tno=1, ValClass=k }, source=} else {
parens_are_balanced
Got }, tno=0, source=} else {
exit_block at line 19, prior nesting_level=2
Lexem 0 Current token='C' perl='else' value='else: ' Tokenstr |C| translated: else: 
enter_block at line 19, prior nesting_level=1, ValPerl=else {
Use of uninitialized value in join or string at /d/pythonizer/pythonizer/Perlscan.pm line 372, <> line 19.
nesting_info=is_eval  lno 19 level 1 type else:  cur_sub  is_sub  in_loop 1 in_sub 0 is_loop 
Lexem 0 Current token='k' perl='last' value='break' Tokenstr |k| translated: break
Got }, tno=1, source=}
Got }, tno=1, ValClass=k }, source=}
parens_are_balanced
Got }, tno=0, source=}
exit_block at line 21, prior nesting_level=2
Got }, tno=0, source=}
exit_block at line 22, prior nesting_level=1
Lexem 0 Current token='c' perl='assert' value='assert' Tokenstr |c| translated: assert
Lexem 1 Current token='(' perl='(' value='(' Tokenstr |c(| translated: assert (
Lexem 2 Current token='s' perl='$ctr' value='ctr' Tokenstr |c(s| translated: assert ( ctr
Lexem 3 Current token='>' perl='==' value='==' Tokenstr |c(s>| translated: assert ( ctr ==
Lexem 4 Current token='d' perl='2' value='2' Tokenstr |c(s>d| translated: assert ( ctr == 2
Lexem 5 Current token=')' perl=')' value=')' Tokenstr |c(s>d)| translated: assert ( ctr == 2 )
Got ; balance=0, tno=6, nesting_last=HASH(0x8005abfe0)
check_ref(main, ctr) at 2
scalar_reference_type(2) = I
Lexem 0 Current token='s' perl='$g' value='g' Tokenstr |s| translated: g
Lexem 1 Current token='=' perl='=' value='=' Tokenstr |s=| translated: g =
Lexem 2 Current token='d' perl='0' value='0' Tokenstr |s=d| translated: g = 0
Got ; balance=0, tno=3, nesting_last=HASH(0x8005abfe0)
check_ref(main, g) at 0
expr_type(2, 2, main)
merge_types(g, main, I)
expr_type(0, 2, main)
Lexem 0 Current token='k' perl='sub' value='def' Tokenstr |k| translated: def
Lexem 1 Current token='i' perl='func' value='func' Tokenstr |ki| translated: def func
enter_block at line 27, prior nesting_level=0, ValPerl=sub func {
nesting_info=cur_sub func in_sub 1 is_loop  is_sub 1 in_loop 0 lno 27 is_eval  level 0 type def
get_globals: switching to 'func' at line 27
expr_type(1, 1, func)
Lexem 0 Current token='s' perl='$g' value='g' Tokenstr |s| translated: g
Lexem 1 Current token='=' perl='=' value='=' Tokenstr |s=| translated: g =
Lexem 2 Current token='d' perl='14' value='14' Tokenstr |s=d| translated: g = 14
Got }, tno=3, source=}
Got }, tno=3, ValClass=s = d }, source=}
parens_are_balanced
check_ref(func, g) at 0
expr_type(2, 2, func)
merge_types(g, func, I)
expr_type(0, 2, func)
Got }, tno=0, source=}
exit_block at line 29, prior nesting_level=1
get_globals: switching back to 'main' at line 29
merge_types(func, main, u)
Lexem 0 Current token='c' perl='if' value='if ' Tokenstr |c| translated: if 
Lexem 1 Current token='(' perl='(' value='(' Tokenstr |c(| translated: if  (
Lexem 2 Current token='s' perl='$t' value='t' Tokenstr |c(s| translated: if  ( t
Lexem 3 Current token='>' perl='==' value='==' Tokenstr |c(s>| translated: if  ( t ==
Lexem 4 Current token='d' perl='2' value='2' Tokenstr |c(s>d| translated: if  ( t == 2
Lexem 5 Current token=')' perl=')' value=')' Tokenstr |c(s>d)| translated: if  ( t == 2 )
enter_block at line 31, prior nesting_level=0, ValPerl=if ( $t == 2 ) {
Use of uninitialized value in join or string at /d/pythonizer/pythonizer/Perlscan.pm line 372, <> line 31.
nesting_info=lno 31 is_eval  level 0 type if  cur_sub  in_sub 0 is_loop  is_sub  in_loop 0
check_ref(main, t) at 2
scalar_reference_type(2) = I
Lexem 0 Current token='i' perl='func' value='func' Tokenstr |i| translated: func
Got }, tno=1, source=}
Got }, tno=1, ValClass=i }, source=}
parens_are_balanced
Got }, tno=0, source=}
exit_block at line 33, prior nesting_level=1
enter_block at line 34, prior nesting_level=0, ValPerl={
Use of uninitialized value in join or string at /d/pythonizer/pythonizer/Perlscan.pm line 372, <> line 34.
nesting_info=is_eval  lno 34 type { level 0 cur_sub  in_loop 1 is_sub  is_loop 1 in_sub 0
Lexem 0 Current token='c' perl='assert' value='assert' Tokenstr |c| translated: assert
Lexem 1 Current token='(' perl='(' value='(' Tokenstr |c(| translated: assert (
Lexem 2 Current token='s' perl='$g' value='g' Tokenstr |c(s| translated: assert ( g
Lexem 3 Current token='>' perl='==' value='==' Tokenstr |c(s>| translated: assert ( g ==
Lexem 4 Current token='d' perl='14' value='14' Tokenstr |c(s>d| translated: assert ( g == 14
Lexem 5 Current token=')' perl=')' value=')' Tokenstr |c(s>d)| translated: assert ( g == 14 )
Got }, tno=6, source=}
Got }, tno=6, ValClass=c ( s > d ) }, source=}
parens_are_balanced
check_ref(main, g) at 2
scalar_reference_type(2) = I
Got }, tno=0, source=}
exit_block at line 36, prior nesting_level=1
Lexem 0 Current token='c' perl='assert' value='assert' Tokenstr |c| translated: assert
Lexem 1 Current token='(' perl='(' value='(' Tokenstr |c(| translated: assert (
Lexem 2 Current token='s' perl='$g' value='g' Tokenstr |c(s| translated: assert ( g
Lexem 3 Current token='>' perl='==' value='==' Tokenstr |c(s>| translated: assert ( g ==
Lexem 4 Current token='d' perl='14' value='14' Tokenstr |c(s>d| translated: assert ( g == 14
Lexem 5 Current token=')' perl=')' value=')' Tokenstr |c(s>d)| translated: assert ( g == 14 )
Got ; balance=0, tno=6, nesting_last=HASH(0x80053aa30)
check_ref(main, g) at 2
scalar_reference_type(2) = I
Lexem 0 Current token='C' perl='do' value='do' Tokenstr |C| translated: do
enter_block at line 39, prior nesting_level=0, ValPerl=do {
Use of uninitialized value in join or string at /d/pythonizer/pythonizer/Perlscan.pm line 372, <> line 39.
nesting_info=lno 39 is_eval  type do level 0 cur_sub  is_loop  in_sub 0 in_loop 0 is_sub 
Lexem 0 Current token='s' perl='$g' value='g' Tokenstr |s| translated: g
Lexem 1 Current token='^' perl='++' value='+=1' Tokenstr |s^| translated: g +=1
Got }, tno=2, source=} until($g == 16);
Got }, tno=2, ValClass=s ^ }, source=} until($g == 16);
parens_are_balanced
check_ref(main, g) at 0
merge_types(g, main, I)
merge_types: otype=I
expr_type(0, 1, main)
Got }, tno=0, source=} until($g == 16);
exit_block at line 41, prior nesting_level=1
Lexem 0 Current token='c' perl='until' value='while not ' Tokenstr |c| translated: while not 
Lexem 1 Current token='(' perl='(' value='(' Tokenstr |c(| translated: while not  (
Lexem 2 Current token='s' perl='$g' value='g' Tokenstr |c(s| translated: while not  ( g
Lexem 3 Current token='>' perl='==' value='==' Tokenstr |c(s>| translated: while not  ( g ==
Lexem 4 Current token='d' perl='16' value='16' Tokenstr |c(s>d| translated: while not  ( g == 16
Lexem 5 Current token=')' perl=')' value=')' Tokenstr |c(s>d)| translated: while not  ( g == 16 )
Got ; balance=0, tno=6, nesting_last=HASH(0x8005abdd0)
check_ref(main, g) at 2
scalar_reference_type(2) = I
Lexem 0 Current token='c' perl='assert' value='assert' Tokenstr |c| translated: assert
Lexem 1 Current token='(' perl='(' value='(' Tokenstr |c(| translated: assert (
Lexem 2 Current token='s' perl='$g' value='g' Tokenstr |c(s| translated: assert ( g
Lexem 3 Current token='>' perl='==' value='==' Tokenstr |c(s>| translated: assert ( g ==
Lexem 4 Current token='d' perl='16' value='16' Tokenstr |c(s>d| translated: assert ( g == 16
Lexem 5 Current token=')' perl=')' value=')' Tokenstr |c(s>d)| translated: assert ( g == 16 )
Got ; balance=0, tno=6, nesting_last=HASH(0x8005abdd0)
check_ref(main, g) at 2
scalar_reference_type(2) = I
Lexem 0 Current token='C' perl='do' value='do' Tokenstr |C| translated: do
enter_block at line 44, prior nesting_level=0, ValPerl=do {
Use of uninitialized value in join or string at /d/pythonizer/pythonizer/Perlscan.pm line 372, <> line 44.
nesting_info=lno 44 is_eval  type do level 0 cur_sub  is_loop  in_sub 0 in_loop 0 is_sub 
Lexem 0 Current token='s' perl='$g' value='g' Tokenstr |s| translated: g
Lexem 1 Current token='^' perl='++' value='+=1' Tokenstr |s^| translated: g +=1
Got }, tno=2, source=} while($g == 20);
Got }, tno=2, ValClass=s ^ }, source=} while($g == 20);
parens_are_balanced
check_ref(main, g) at 0
merge_types(g, main, I)
merge_types: otype=I
expr_type(0, 1, main)
Got }, tno=0, source=} while($g == 20);
exit_block at line 46, prior nesting_level=1
Lexem 0 Current token='c' perl='while' value='while' Tokenstr |c| translated: while
Lexem 1 Current token='(' perl='(' value='(' Tokenstr |c(| translated: while (
Lexem 2 Current token='s' perl='$g' value='g' Tokenstr |c(s| translated: while ( g
Lexem 3 Current token='>' perl='==' value='==' Tokenstr |c(s>| translated: while ( g ==
Lexem 4 Current token='d' perl='20' value='20' Tokenstr |c(s>d| translated: while ( g == 20
Lexem 5 Current token=')' perl=')' value=')' Tokenstr |c(s>d)| translated: while ( g == 20 )
Got ; balance=0, tno=6, nesting_last=HASH(0x800553e68)
check_ref(main, g) at 2
scalar_reference_type(2) = I
Lexem 0 Current token='c' perl='assert' value='assert' Tokenstr |c| translated: assert
Lexem 1 Current token='(' perl='(' value='(' Tokenstr |c(| translated: assert (
Lexem 2 Current token='s' perl='$g' value='g' Tokenstr |c(s| translated: assert ( g
Lexem 3 Current token='>' perl='==' value='==' Tokenstr |c(s>| translated: assert ( g ==
Lexem 4 Current token='d' perl='17' value='17' Tokenstr |c(s>d| translated: assert ( g == 17
Lexem 5 Current token=')' perl=')' value=')' Tokenstr |c(s>d)| translated: assert ( g == 17 )
Got ; balance=0, tno=6, nesting_last=HASH(0x800553e68)
check_ref(main, g) at 2
scalar_reference_type(2) = I
Lexem 0 Current token='s' perl='$ctr' value='ctr' Tokenstr |s| translated: ctr
Lexem 1 Current token='=' perl='=' value='=' Tokenstr |s=| translated: ctr =
Lexem 2 Current token='d' perl='0' value='0' Tokenstr |s=d| translated: ctr = 0
Got ; balance=0, tno=3, nesting_last=HASH(0x800553e68)
check_ref(main, ctr) at 0
expr_type(2, 2, main)
merge_types(ctr, main, I)
merge_types: otype=I
expr_type(0, 2, main)
Lexem 0 Current token='C' perl='do' value='do' Tokenstr |C| translated: do
enter_block at line 49, prior nesting_level=0, ValPerl=do {
Use of uninitialized value in join or string at /d/pythonizer/pythonizer/Perlscan.pm line 372, <> line 49.
nesting_info=is_sub  in_loop 0 in_sub 0 is_loop  cur_sub  level 0 type do is_eval  lno 49
Lexem 0 Current token='s' perl='$g' value='g' Tokenstr |s| translated: g
Lexem 1 Current token='^' perl='++' value='+=1' Tokenstr |s^| translated: g +=1
Got }, tno=2, source=};
Got }, tno=2, ValClass=s ^ }, source=};
parens_are_balanced
check_ref(main, g) at 0
merge_types(g, main, I)
merge_types: otype=I
expr_type(0, 1, main)
Got }, tno=0, source=};
exit_block at line 51, prior nesting_level=1
Got ; balance=0, tno=0, nesting_last=HASH(0x800077a88)
Lexem 0 Current token='c' perl='while' value='while' Tokenstr |c| translated: while
Lexem 1 Current token='(' perl='(' value='(' Tokenstr |c(| translated: while (
Lexem 2 Current token='s' perl='$g' value='g' Tokenstr |c(s| translated: while ( g
Lexem 3 Current token='>' perl='<' value='<' Tokenstr |c(s>| translated: while ( g <
Lexem 4 Current token='d' perl='20' value='20' Tokenstr |c(s>d| translated: while ( g < 20
Lexem 5 Current token=')' perl=')' value=')' Tokenstr |c(s>d)| translated: while ( g < 20 )
enter_block at line 52, prior nesting_level=0, ValPerl=while ( $g < 20 ) {
Use of uninitialized value in join or string at /d/pythonizer/pythonizer/Perlscan.pm line 372, <> line 52.
nesting_info=is_sub  in_loop 1 in_sub 0 is_loop 1 cur_sub  level 0 type while is_eval  lno 52
check_ref(main, g) at 2
scalar_reference_type(2) = I
Lexem 0 Current token='s' perl='$g' value='g' Tokenstr |s| translated: g
Lexem 1 Current token='^' perl='++' value='+=1' Tokenstr |s^| translated: g +=1
Got ; balance=0, tno=2, nesting_last=HASH(0x800077a88)
check_ref(main, g) at 0
merge_types(g, main, I)
merge_types: otype=I
expr_type(0, 1, main)
Lexem 0 Current token='s' perl='$ctr' value='ctr' Tokenstr |s| translated: ctr
Lexem 1 Current token='^' perl='++' value='+=1' Tokenstr |s^| translated: ctr +=1
Got }, tno=2, source=}
Got }, tno=2, ValClass=s ^ }, source=}
parens_are_balanced
check_ref(main, ctr) at 0
merge_types(ctr, main, I)
merge_types: otype=I
expr_type(0, 1, main)
Got }, tno=0, source=}
exit_block at line 55, prior nesting_level=1
Lexem 0 Current token='c' perl='assert' value='assert' Tokenstr |c| translated: assert
Lexem 1 Current token='(' perl='(' value='(' Tokenstr |c(| translated: assert (
Lexem 2 Current token='s' perl='$g' value='g' Tokenstr |c(s| translated: assert ( g
Lexem 3 Current token='>' perl='==' value='==' Tokenstr |c(s>| translated: assert ( g ==
Lexem 4 Current token='d' perl='20' value='20' Tokenstr |c(s>d| translated: assert ( g == 20
Lexem 5 Current token=')' perl=')' value=')' Tokenstr |c(s>d)| translated: assert ( g == 20 )
Got ; balance=0, tno=6, nesting_last=HASH(0x800535490)
check_ref(main, g) at 2
scalar_reference_type(2) = I
Lexem 0 Current token='c' perl='assert' value='assert' Tokenstr |c| translated: assert
Lexem 1 Current token='(' perl='(' value='(' Tokenstr |c(| translated: assert (
Lexem 2 Current token='s' perl='$ctr' value='ctr' Tokenstr |c(s| translated: assert ( ctr
Lexem 3 Current token='>' perl='==' value='==' Tokenstr |c(s>| translated: assert ( ctr ==
Lexem 4 Current token='d' perl='2' value='2' Tokenstr |c(s>d| translated: assert ( ctr == 2
Lexem 5 Current token=')' perl=')' value=')' Tokenstr |c(s>d)| translated: assert ( ctr == 2 )
Got ; balance=0, tno=6, nesting_last=HASH(0x800535490)
check_ref(main, ctr) at 2
scalar_reference_type(2) = I
Lexem 0 Current token='s' perl='$hell_freezes_over' value='hell_freezes_over' Tokenstr |s| translated: hell_freezes_over
Lexem 1 Current token='=' perl='=' value='=' Tokenstr |s=| translated: hell_freezes_over =
Lexem 2 Current token='d' perl='0' value='0' Tokenstr |s=d| translated: hell_freezes_over = 0
Got ; balance=0, tno=3, nesting_last=HASH(0x800535490)
check_ref(main, hell_freezes_over) at 0
expr_type(2, 2, main)
merge_types(hell_freezes_over, main, I)
expr_type(0, 2, main)
Lexem 0 Current token='i' perl='looper' value='looper' Tokenstr |i| translated: looper
def_label(looper)
enter_block at line 60, prior nesting_level=0, ValPerl={
Use of uninitialized value in join or string at /d/pythonizer/pythonizer/Perlscan.pm line 372, <> line 60.
nesting_info=label looper cur_sub  is_loop 1 in_sub 0 in_loop 1 is_sub  lno 60 is_eval  type { level 0
Lexem 0 Current token='C' perl='do' value='do' Tokenstr |C| translated: do
enter_block at line 61, prior nesting_level=1, ValPerl=do {
Use of uninitialized value in join or string at /d/pythonizer/pythonizer/Perlscan.pm line 372, <> line 61.
nesting_info=cur_sub  is_loop  in_sub 0 in_loop 1 is_sub  lno 61 is_eval  type do level 1
Lexem 0 Current token='s' perl='$g' value='g' Tokenstr |s| translated: g
Lexem 1 Current token='^' perl='++' value='+=1' Tokenstr |s^| translated: g +=1
Got ; balance=0, tno=2, nesting_last=HASH(0x800535490)
check_ref(main, g) at 0
merge_types(g, main, I)
merge_types: otype=I
expr_type(0, 1, main)
Lexem 0 Current token='k' perl='last' value='break' Tokenstr |k| translated: break
Lexem 1 Current token='c' perl='if' value='if ' Tokenstr |kc| translated: break if 
Lexem 2 Current token='(' perl='(' value='(' Tokenstr |kc(| translated: break if  (
Lexem 3 Current token='s' perl='$ctr' value='ctr' Tokenstr |kc(s| translated: break if  ( ctr
Lexem 4 Current token='>' perl='==' value='==' Tokenstr |kc(s>| translated: break if  ( ctr ==
Lexem 5 Current token='d' perl='2' value='2' Tokenstr |kc(s>d| translated: break if  ( ctr == 2
Lexem 6 Current token=')' perl=')' value=')' Tokenstr |kc(s>d)| translated: break if  ( ctr == 2 )
Got ; balance=0, tno=7, nesting_last=HASH(0x800535490)
check_ref(main, ctr) at 3
scalar_reference_type(3) = I
expr_type(1, 6, main)
Got }, tno=0, source=} until($hell_freezes_over);
exit_block at line 64, prior nesting_level=2
Lexem 0 Current token='c' perl='until' value='while not ' Tokenstr |c| translated: while not 
Lexem 1 Current token='(' perl='(' value='(' Tokenstr |c(| translated: while not  (
Lexem 2 Current token='s' perl='$hell_freezes_over' value='hell_freezes_over' Tokenstr |c(s| translated: while not  ( hell_freezes_over
Lexem 3 Current token=')' perl=')' value=')' Tokenstr |c(s)| translated: while not  ( hell_freezes_over )
Got ; balance=0, tno=4, nesting_last=HASH(0x80063ee00)
check_ref(main, hell_freezes_over) at 2
scalar_reference_type(2) = u
Got }, tno=0, source=}
exit_block at line 65, prior nesting_level=1
Lexem 0 Current token='f' perl='print' value='print' Tokenstr |f| translated: print
Lexem 1 Current token='"' perl='$0 - test passed!\n' value='f"{__file__} - test passed!\n"' Tokenstr |f"| translated: print f"{__file__} - test passed!\n"
Got ; balance=0, tno=2, nesting_last=HASH(0x80053abb0)
expr_type(0, 1, main)
VarSubMap = $VAR1 = {
  'TRACEBACK' => {
    'main' => '+'
  },
  'g' => {
    'func' => '+',
    'main' => '+'
  },
  '_DUP_MAP' => {
    'main' => '+'
  },
  't' => {
    'main' => '+'
  },
  'hell_freezes_over' => {
    'main' => '+'
  },
  'CHILD_ERROR' => {
    'main' => '+'
  },
  'AUTODIE' => {
    'main' => '+'
  },
  'i' => {
    'main' => '+'
  },
  'LIST_SEPARATOR' => {
    'main' => '+'
  },
  'OS_ERROR' => {
    'main' => '+'
  },
  '_script_start' => {
    'main' => '+'
  },
  '_OPEN_MODE_MAP' => {
    'main' => '+'
  },
  'ctr' => {
    'main' => '+'
  }
};

VarType = $VAR1 = {
  '_script_start' => {
    'main' => 'I'
  },
  'OS_ERROR' => {
    'main' => 'S'
  },
  'func' => {
    'main' => 'u'
  },
  'LIST_SEPARATOR' => {
    'main' => 'S'
  },
  'i' => {
    'main' => 'I'
  },
  'main' => {},
  'hell_freezes_over' => {
    'main' => 'I'
  },
  'EVAL_ERROR' => {
    'main' => 'S'
  },
  't' => {
    'main' => 'I'
  },
  'g' => {
    'func' => 'I',
    'main' => 'I'
  },
  'os.name' => {
    'main' => 'S'
  },
  'os.environ' => {
    'main' => 'h of S'
  },
  'ctr' => {
    'main' => 'I'
  },
  'sys.argv' => {
    'main' => 'a of S'
  }
};

initialized = $VAR1 = {
  'func' => {
    'g' => 'I'
  },
  'main' => {
    'sys.argv' => 'a of S',
    'ctr' => 'I',
    'hell_freezes_over' => 'I',
    'EVAL_ERROR' => 'S',
    'g' => 'I',
    't' => 'I',
    'OS_ERROR' => 'S',
    '_script_start' => 'I',
    'LIST_SEPARATOR' => 'S',
    'os.name' => 'S',
    'os.environ' => 'h of S',
    'i' => 'u'
  }
};

NeedsInitializing = $VAR1 = {};

sub_external_last_nexts = $VAR1 = {};

line_needs_try_block = $VAR1 = {};


DETECTED GLOBAL VARIABLES:
	main: global g
	func: global g

AUTO-INITIALIZED VARIABLES:

List of local subroutines:
func main
mkdir: cannot create directory ‘/c/Users/Joe’: File exists
cp: target 'Orost/Archive/pythonizer' is not a directory
cp: target 'Orost/Archive/Softpano.pm' is not a directory
cp: target 'Orost/Archive/Perlscan.pm' is not a directory
cp: target 'Orost/Archive/Pythonizer.pm' is not a directory
   1 | 0 |   |#!/usr/bin/python3 -u
   1 | 0 |   |# Generated by pythonizer 0.924 run by Joe Orost on Mon Dec 13 01:31:23 2021
   1 | 0 |   |# issue 95 - Bad code generated if last statement in block before else or elsif doesn't end in ;
   2 | 0 |   |import sys,os,re,fcntl,math,fileinput,subprocess,inspect,collections.abc,argparse,glob,warnings,inspect,functools,signal,traceback,io,tempfile,atexit,calendar
   2 | 0 |   |import time as tm_py
   2 | 0 |   |_OPEN_MODE_MAP = {'<': 'r', '>': 'w', '+<': 'r+', '+>': 'w+', '>>': 'a', '+>>': 'a+', '|': '|-'}
   2 | 0 |   |_DUP_MAP = dict(STDIN=0, STDOUT=1, STDERR=2)
   2 | 0 |   |TRACEBACK = 0
   2 | 0 |   |CHILD_ERROR = 0
   2 | 0 |   |LIST_SEPARATOR = ' '
   2 | 0 |   |AUTODIE = 0
   2 | 0 |   |OS_ERROR = ''
   2 | 0 |   |_script_start = tm_py.time()
   2 | 0 |   |class Die(Exception):
    pass
   2 | 0 |   |class EvalReturn(Exception):
    pass
   2 | 0 |   |class LoopControl(Exception):
    pass
   2 | 0 |   |class LoopControl_looper(Exception):
    pass
   2 | 0 |   |_args = sys.argv[1:]
Main loop, line=use Carp::Assert;


 === Line 2 Perl source:use Carp::Assert;===

Lexem 0 Current token='c' perl='use' value='NoTrans!' Tokenstr |c| translated: NoTrans!
Lexem 1 Current token='i' perl='Carp::Assert' value='Carp.Assert' Tokenstr |ci| translated: NoTrans! Carp.Assert
Got ; balance=0, tno=2, nesting_last=HASH(0x80053abb0)

Line:    2 TokenStr: =|ci|= @ValPy: NoTrans! Carp.Assert
   2 | 0 |   |#SKIPPED: use Carp::Assert;
   3 | 0 |   |
Main loop, line=my $t = 1;


 === Line 4 Perl source:my $t = 1;===

Lexem 0 Current token='t' perl='my' value='' Tokenstr |t| translated: 
Lexem 1 Current token='s' perl='$t' value='t' Tokenstr |ts| translated:  t
Lexem 2 Current token='=' perl='=' value='=' Tokenstr |ts=| translated:  t =
Lexem 3 Current token='d' perl='1' value='1' Tokenstr |ts=d| translated:  t = 1
Got ; balance=0, tno=4, nesting_last=HASH(0x80053abb0)

Line:    4 TokenStr: =|ts=d|= @ValPy:  t = 1
   4 | 0 |   |t=1                                                                                     #PL: my $t = 1;
Main loop, line=if($t == 1) {


 === Line 5 Perl source:if($t == 1) {===

Lexem 0 Current token='c' perl='if' value='if ' Tokenstr |c| translated: if 
Lexem 1 Current token='(' perl='(' value='(' Tokenstr |c(| translated: if  (
Lexem 2 Current token='s' perl='$t' value='t' Tokenstr |c(s| translated: if  ( t
Lexem 3 Current token='>' perl='==' value='==' Tokenstr |c(s>| translated: if  ( t ==
Lexem 4 Current token='d' perl='1' value='1' Tokenstr |c(s>d| translated: if  ( t == 1
Lexem 5 Current token=')' perl=')' value=')' Tokenstr |c(s>d)| translated: if  ( t == 1 )
enter_block at line 5, prior nesting_level=0, ValPerl=if ( $t == 1 ) {
Use of uninitialized value in join or string at /d/pythonizer/pythonizer/Perlscan.pm line 372, <> line 5.
nesting_info=cur_sub  is_loop  in_sub 0 in_loop 0 is_sub  lno 5 is_eval  type if  level 0

Line:    5 TokenStr: =|c(s>d)|= @ValPy: if  ( t == 1 )
control(0) =|c(s>d)|= if ( $t == 1 )

control-parens removed, begin=0 start=1 =|cs>d|= if $t == 1

Generated partial line if 
expression(1, 3, 0) =|cs>d|= if $t == 1

Generated partial line if t
Generated partial line if t==
Generated partial line if t==1
expression returns 4
Generated partial line if t==1:
   5 | 0 |   |if t == 1:                                                                              #PL: 

Tokens: cs>d ValPy: 
Main loop, line={


 === Line 5 Perl source:{===


Line:    5 TokenStr: =|{|= @ValPy: {
Use of uninitialized value in join or string at /d/pythonizer/pythonizer/Perlscan.pm line 466, <> line 5.
loop_needs_try_block(0), top=cur_sub  is_loop  in_sub 0 in_loop 0 is_sub  lno 5 is_eval  type if  level 0
Main loop, line=$t = 2


 === Line 6 Perl source:$t = 2===

Lexem 0 Current token='s' perl='$t' value='t' Tokenstr |s| translated: t
Lexem 1 Current token='=' perl='=' value='=' Tokenstr |s=| translated: t =
Lexem 2 Current token='d' perl='2' value='2' Tokenstr |s=d| translated: t = 2
Got }, tno=3, source=}
Got }, tno=3, ValClass=s = d }, source=}
parens_are_balanced

Line:    7 TokenStr: =|s=d|= @ValPy: t = 2
assignment(0, 2) =|s=d|= $t = 2

Generated partial line t
Generated partial line t=
assign, ValClass[limit] = d, ValPy=2, ValPerl=2

Generated partial line t=2
   7 | 1 |   |    t = 2                                                                               #PL: 

Tokens: s=d ValPy: 
Main loop, line=}


 === Line 7 Perl source:}===

Got }, tno=0, source=}
exit_block at line 7, prior nesting_level=1

Line:    7 TokenStr: =|}|= @ValPy: }
Use of uninitialized value in join or string at /d/pythonizer/pythonizer/Perlscan.pm line 466, <> line 7.
loop_needs_try_block(1), top=cur_sub  is_loop  in_sub 0 in_loop 0 is_sub  lno 5 is_eval  type if  level 0
   7 | 1 |   |
Main loop, line=assert($t == 2);


 === Line 8 Perl source:assert($t == 2);===

Lexem 0 Current token='c' perl='assert' value='assert' Tokenstr |c| translated: assert
Lexem 1 Current token='(' perl='(' value='(' Tokenstr |c(| translated: assert (
Lexem 2 Current token='s' perl='$t' value='t' Tokenstr |c(s| translated: assert ( t
Lexem 3 Current token='>' perl='==' value='==' Tokenstr |c(s>| translated: assert ( t ==
Lexem 4 Current token='d' perl='2' value='2' Tokenstr |c(s>d| translated: assert ( t == 2
Lexem 5 Current token=')' perl=')' value=')' Tokenstr |c(s>d)| translated: assert ( t == 2 )
Got ; balance=0, tno=6, nesting_last=HASH(0x800535538)

Line:    8 TokenStr: =|c(s>d)|= @ValPy: assert ( t == 2 )
control(0) =|c(s>d)|= assert ( $t == 2 )

control-parens removed, begin=0 start=1 =|cs>d|= assert $t == 2

Generated partial line assert
expression(1, 3, 0) =|cs>d|= assert $t == 2

Generated partial line assertt
Generated partial line assertt==
Generated partial line assertt==2
expression returns 4
   9 | 0 |   |
  10 | 0 |   |assert t == 2                                                                           #PL: my $ctr = 0;

Tokens: cs>d ValPy: 
Main loop, line=my $ctr = 0;


 === Line 10 Perl source:my $ctr = 0;===

Lexem 0 Current token='t' perl='my' value='' Tokenstr |t| translated: 
Lexem 1 Current token='s' perl='$ctr' value='ctr' Tokenstr |ts| translated:  ctr
Lexem 2 Current token='=' perl='=' value='=' Tokenstr |ts=| translated:  ctr =
Lexem 3 Current token='d' perl='0' value='0' Tokenstr |ts=d| translated:  ctr = 0
Got ; balance=0, tno=4, nesting_last=HASH(0x800535538)

Line:   10 TokenStr: =|ts=d|= @ValPy:  ctr = 0
  10 | 0 |   |ctr=0                                                                                   #PL: my $ctr = 0;
Main loop, line=for $i (0..5) {


 === Line 11 Perl source:for $i (0..5) {===

Lexem 0 Current token='c' perl='for' value='for' Tokenstr |c| translated: for
Lexem 1 Current token='s' perl='$i' value='i' Tokenstr |cs| translated: for i
Lexem 2 Current token='(' perl='(' value='(' Tokenstr |cs(| translated: for i (
Lexem 3 Current token='d' perl='0' value='0' Tokenstr |cs(d| translated: for i ( 0
Lexem 4 Current token='r' perl='..' value='..' Tokenstr |cs(dr| translated: for i ( 0 ..
Lexem 5 Current token='d' perl='5' value='5' Tokenstr |cs(drd| translated: for i ( 0 .. 5
Lexem 6 Current token=')' perl=')' value=')' Tokenstr |cs(drd)| translated: for i ( 0 .. 5 )
enter_block at line 11, prior nesting_level=0, ValPerl=for $i ( 0 .. 5 ) {
Use of uninitialized value in join or string at /d/pythonizer/pythonizer/Perlscan.pm line 372, <> line 11.
nesting_info=type for level 0 lno 11 is_eval  is_loop 1 in_sub 0 in_loop 1 is_sub  cur_sub 

Line:   11 TokenStr: =|cs(drd)|= @ValPy: for i ( 0 .. 5 )
control(0) =|cs(drd)|= for $i ( 0 .. 5 )

Generated partial line for
Generated partial line fori in 
Generated partial line fori in range(
expression(3, 3, 0) =|cs(drd)|= for $i ( 0 .. 5 )

Generated partial line fori in range(0
expression returns 4
Generated partial line fori in range(0,
expression(5, 5, 0) =|cs(drd)|= for $i ( 0 .. 5 )

Generated partial line fori in range(0,5
expression returns 6
Generated partial line fori in range(0,5+1)
Generated partial line fori in range(0,5+1):
  11 | 0 |   |for i in range(0, 5+1):                                                                 #PL: 

Tokens: cs(drd) ValPy: 
Main loop, line={


 === Line 11 Perl source:{===


Line:   11 TokenStr: =|{|= @ValPy: {
Use of uninitialized value in join or string at /d/pythonizer/pythonizer/Perlscan.pm line 466, <> line 11.
loop_needs_try_block(0), top=type for level 0 lno 11 is_eval  is_loop 1 in_sub 0 in_loop 1 is_sub  cur_sub 
Main loop, line={


 === Line 12 Perl source:{===

enter_block at line 12, prior nesting_level=1, ValPerl={
Use of uninitialized value in join or string at /d/pythonizer/pythonizer/Perlscan.pm line 372, <> line 12.
nesting_info=level 1 type { is_eval  lno 12 is_sub  in_loop 1 in_sub 0 is_loop 1 cur_sub 

Line:   12 TokenStr: =|{|= @ValPy: {
  12 | 1 |   |    for _ in range(1):                                                                  #PL: 

Tokens: { ValPy: 
Use of uninitialized value in join or string at /d/pythonizer/pythonizer/Perlscan.pm line 466, <> line 12.
loop_needs_try_block(0), top=level 1 type { is_eval  lno 12 is_sub  in_loop 1 in_sub 0 is_loop 1 cur_sub 
Main loop, line=$ctr++


 === Line 13 Perl source:$ctr++===

Lexem 0 Current token='s' perl='$ctr' value='ctr' Tokenstr |s| translated: ctr
Lexem 1 Current token='^' perl='++' value='+=1' Tokenstr |s^| translated: ctr +=1
Got }, tno=2, source=}
Got }, tno=2, ValClass=s ^ }, source=}
parens_are_balanced

Line:   14 TokenStr: =|s^|= @ValPy: ctr +=1
handle_incr_decr(0, 1, 1) with ++assignment(0, 1) =|s^|= $ctr ++

Generated partial line ctr+=1
  14 | 2 |   |        ctr+=1                                                                          #PL: 

Tokens: s^ ValPy: 
Main loop, line=}


 === Line 14 Perl source:}===

Got }, tno=0, source=}
exit_block at line 14, prior nesting_level=2

Line:   14 TokenStr: =|}|= @ValPy: }
Use of uninitialized value in join or string at /d/pythonizer/pythonizer/Perlscan.pm line 466, <> line 14.
loop_needs_try_block(1), top=level 1 type { is_eval  lno 12 is_sub  in_loop 1 in_sub 0 is_loop 1 cur_sub 
  14 | 2 |   |
Main loop, line=if($i == 0) {


 === Line 15 Perl source:if($i == 0) {===

Lexem 0 Current token='c' perl='if' value='if ' Tokenstr |c| translated: if 
Lexem 1 Current token='(' perl='(' value='(' Tokenstr |c(| translated: if  (
Lexem 2 Current token='s' perl='$i' value='i' Tokenstr |c(s| translated: if  ( i
Lexem 3 Current token='>' perl='==' value='==' Tokenstr |c(s>| translated: if  ( i ==
Lexem 4 Current token='d' perl='0' value='0' Tokenstr |c(s>d| translated: if  ( i == 0
Lexem 5 Current token=')' perl=')' value=')' Tokenstr |c(s>d)| translated: if  ( i == 0 )
enter_block at line 15, prior nesting_level=1, ValPerl=if ( $i == 0 ) {
Use of uninitialized value in join or string at /d/pythonizer/pythonizer/Perlscan.pm line 372, <> line 15.
nesting_info=is_sub  in_loop 1 in_sub 0 is_loop  cur_sub  level 1 type if  is_eval  lno 15

Line:   15 TokenStr: =|c(s>d)|= @ValPy: if  ( i == 0 )
control(0) =|c(s>d)|= if ( $i == 0 )

control-parens removed, begin=0 start=1 =|cs>d|= if $i == 0

Generated partial line if 
expression(1, 3, 0) =|cs>d|= if $i == 0

Generated partial line if i
Generated partial line if i==
Generated partial line if i==0
expression returns 4
Generated partial line if i==0:
  15 | 1 |   |    if i == 0:                                                                          #PL: 

Tokens: cs>d ValPy: 
Main loop, line={


 === Line 15 Perl source:{===


Line:   15 TokenStr: =|{|= @ValPy: {
Use of uninitialized value in join or string at /d/pythonizer/pythonizer/Perlscan.pm line 466, <> line 15.
loop_needs_try_block(0), top=is_sub  in_loop 1 in_sub 0 is_loop  cur_sub  level 1 type if  is_eval  lno 15
Main loop, line=next


 === Line 16 Perl source:next===

Lexem 0 Current token='k' perl='next' value='continue' Tokenstr |k| translated: continue
Got }, tno=1, source=} elsif(0) {
Got }, tno=1, ValClass=k }, source=} elsif(0) {
parens_are_balanced

Line:   17 TokenStr: =|k|= @ValPy: continue
Generated partial line continue
  17 | 2 |   |        continue                                                                        #PL: } elsif(0) {

Tokens: k ValPy: 
Main loop, line=} elsif(0) {


 === Line 17 Perl source:} elsif(0) {===

Got }, tno=0, source=} elsif(0) {
exit_block at line 17, prior nesting_level=2

Line:   17 TokenStr: =|}|= @ValPy: }
Use of uninitialized value in join or string at /d/pythonizer/pythonizer/Perlscan.pm line 466, <> line 17.
loop_needs_try_block(1), top=is_sub  in_loop 1 in_sub 0 is_loop  cur_sub  level 1 type if  is_eval  lno 15
Main loop, line=elsif(0) {


 === Line 17 Perl source:elsif(0) {===

Lexem 0 Current token='C' perl='elsif' value='elif ' Tokenstr |C| translated: elif 
Lexem 1 Current token='(' perl='(' value='(' Tokenstr |C(| translated: elif  (
Lexem 2 Current token='d' perl='0' value='0' Tokenstr |C(d| translated: elif  ( 0
Lexem 3 Current token=')' perl=')' value=')' Tokenstr |C(d)| translated: elif  ( 0 )
enter_block at line 17, prior nesting_level=1, ValPerl=elsif ( 0 ) {
Use of uninitialized value in join or string at /d/pythonizer/pythonizer/Perlscan.pm line 372, <> line 17.
nesting_info=cur_sub  is_loop  in_sub 0 in_loop 1 is_sub  lno 17 is_eval  type elif  level 1

Line:   17 TokenStr: =|C(d)|= @ValPy: elif  ( 0 )
Generated partial line elif 
expression(2, 2, 0) =|C(d)|= elsif ( 0 )

Generated partial line elif 0
expression returns 3
Generated partial line elif 0:
  17 | 1 |   |    elif 0:                                                                             #PL: elsif(0) {

Tokens: C(d) ValPy: 
Main loop, line={


 === Line 17 Perl source:{===


Line:   17 TokenStr: =|{|= @ValPy: {
Use of uninitialized value in join or string at /d/pythonizer/pythonizer/Perlscan.pm line 466, <> line 17.
loop_needs_try_block(0), top=cur_sub  is_loop  in_sub 0 in_loop 1 is_sub  lno 17 is_eval  type elif  level 1
Main loop, line=next


 === Line 18 Perl source:next===

Lexem 0 Current token='k' perl='next' value='continue' Tokenstr |k| translated: continue
Got }, tno=1, source=} else {
Got }, tno=1, ValClass=k }, source=} else {
parens_are_balanced

Line:   19 TokenStr: =|k|= @ValPy: continue
Generated partial line continue
  19 | 2 |   |        continue                                                                        #PL: } else {

Tokens: k ValPy: 
Main loop, line=} else {


 === Line 19 Perl source:} else {===

Got }, tno=0, source=} else {
exit_block at line 19, prior nesting_level=2

Line:   19 TokenStr: =|}|= @ValPy: }
Use of uninitialized value in join or string at /d/pythonizer/pythonizer/Perlscan.pm line 466, <> line 19.
loop_needs_try_block(1), top=cur_sub  is_loop  in_sub 0 in_loop 1 is_sub  lno 17 is_eval  type elif  level 1
Main loop, line=else {


 === Line 19 Perl source:else {===

Lexem 0 Current token='C' perl='else' value='else: ' Tokenstr |C| translated: else: 
enter_block at line 19, prior nesting_level=1, ValPerl=else {
Use of uninitialized value in join or string at /d/pythonizer/pythonizer/Perlscan.pm line 372, <> line 19.
nesting_info=lno 19 is_eval  type else:  level 1 cur_sub  is_loop  in_sub 0 in_loop 1 is_sub 

Line:   19 TokenStr: =|C|= @ValPy: else: 
Generated partial line else:
  19 | 1 |   |    else:                                                                               #PL: else {

Tokens: C ValPy: 
Main loop, line={


 === Line 19 Perl source:{===


Line:   19 TokenStr: =|{|= @ValPy: {
Use of uninitialized value in join or string at /d/pythonizer/pythonizer/Perlscan.pm line 466, <> line 19.
loop_needs_try_block(0), top=lno 19 is_eval  type else:  level 1 cur_sub  is_loop  in_sub 0 in_loop 1 is_sub 
Main loop, line=last


 === Line 20 Perl source:last===

Lexem 0 Current token='k' perl='last' value='break' Tokenstr |k| translated: break
Got }, tno=1, source=}
Got }, tno=1, ValClass=k }, source=}
parens_are_balanced

Line:   21 TokenStr: =|k|= @ValPy: break
Generated partial line break
  21 | 2 |   |        break                                                                           #PL: 

Tokens: k ValPy: 
Main loop, line=}


 === Line 21 Perl source:}===

Got }, tno=0, source=}
exit_block at line 21, prior nesting_level=2

Line:   21 TokenStr: =|}|= @ValPy: }
Use of uninitialized value in join or string at /d/pythonizer/pythonizer/Perlscan.pm line 466, <> line 21.
loop_needs_try_block(1), top=lno 19 is_eval  type else:  level 1 cur_sub  is_loop  in_sub 0 in_loop 1 is_sub 
  21 | 2 |   |
Main loop, line=}


 === Line 22 Perl source:}===

Got }, tno=0, source=}
exit_block at line 22, prior nesting_level=1

Line:   22 TokenStr: =|}|= @ValPy: }
Use of uninitialized value in join or string at /d/pythonizer/pythonizer/Perlscan.pm line 466, <> line 22.
loop_needs_try_block(1), top=type for level 0 lno 11 is_eval  is_loop 1 in_sub 0 in_loop 1 is_sub  cur_sub 
  22 | 1 |   |
Main loop, line=assert($ctr == 2);


 === Line 23 Perl source:assert($ctr == 2);===

Lexem 0 Current token='c' perl='assert' value='assert' Tokenstr |c| translated: assert
Lexem 1 Current token='(' perl='(' value='(' Tokenstr |c(| translated: assert (
Lexem 2 Current token='s' perl='$ctr' value='ctr' Tokenstr |c(s| translated: assert ( ctr
Lexem 3 Current token='>' perl='==' value='==' Tokenstr |c(s>| translated: assert ( ctr ==
Lexem 4 Current token='d' perl='2' value='2' Tokenstr |c(s>d| translated: assert ( ctr == 2
Lexem 5 Current token=')' perl=')' value=')' Tokenstr |c(s>d)| translated: assert ( ctr == 2 )
Got ; balance=0, tno=6, nesting_last=HASH(0x800514838)

Line:   23 TokenStr: =|c(s>d)|= @ValPy: assert ( ctr == 2 )
control(0) =|c(s>d)|= assert ( $ctr == 2 )

control-parens removed, begin=0 start=1 =|cs>d|= assert $ctr == 2

Generated partial line assert
expression(1, 3, 0) =|cs>d|= assert $ctr == 2

Generated partial line assertctr
Generated partial line assertctr==
Generated partial line assertctr==2
expression returns 4
  24 | 0 |   |
  25 | 0 |   |assert ctr == 2                                                                         #PL: $g = 0;

Tokens: cs>d ValPy: 
Main loop, line=$g = 0;


 === Line 25 Perl source:$g = 0;===

Lexem 0 Current token='s' perl='$g' value='g' Tokenstr |s| translated: g
Lexem 1 Current token='=' perl='=' value='=' Tokenstr |s=| translated: g =
Lexem 2 Current token='d' perl='0' value='0' Tokenstr |s=d| translated: g = 0
Got ; balance=0, tno=3, nesting_last=HASH(0x800514838)

Line:   25 TokenStr: =|s=d|= @ValPy: g = 0
assignment(0, 2) =|s=d|= $g = 0

Generated partial line g
Generated partial line g=
assign, ValClass[limit] = d, ValPy=0, ValPerl=0

Generated partial line g=0
  26 | 0 |   |g = 0                                                                                   #PL: sub func

Tokens: s=d ValPy: 
Main loop, line=sub func


 === Line 26 Perl source:sub func===

Lexem 0 Current token='k' perl='sub' value='def' Tokenstr |k| translated: def
Lexem 1 Current token='i' perl='func' value='func' Tokenstr |ki| translated: def func
enter_block at line 27, prior nesting_level=0, ValPerl=sub func {
nesting_info=lno 27 is_eval  level 0 type def cur_sub func in_sub 1 is_loop  is_sub 1 in_loop 0

Line:   27 TokenStr: =|ki|= @ValPy: def func
Generated partial line deffunc(_args):
  27 | 0 |   |def func(_args):                                                                        #PL: sub func

Tokens: ki ValPy: 
  27 | 1 |   |    global g                                                                            #PL: sub func
Main loop, line={


 === Line 27 Perl source:{===


Line:   27 TokenStr: =|{|= @ValPy: {
loop_needs_try_block(0), top=lno 27 is_eval  level 0 type def cur_sub func in_sub 1 is_loop  is_sub 1 in_loop 0
Main loop, line=$g = 14


 === Line 28 Perl source:$g = 14===

Lexem 0 Current token='s' perl='$g' value='g' Tokenstr |s| translated: g
Lexem 1 Current token='=' perl='=' value='=' Tokenstr |s=| translated: g =
Lexem 2 Current token='d' perl='14' value='14' Tokenstr |s=d| translated: g = 14
Got }, tno=3, source=}
Got }, tno=3, ValClass=s = d }, source=}
parens_are_balanced

Line:   29 TokenStr: =|s=d|= @ValPy: g = 14
assignment(0, 2) =|s=d|= $g = 14

Generated partial line g
Generated partial line g=
assign, ValClass[limit] = d, ValPy=14, ValPerl=14

Generated partial line g=14
finish: prev_line=$g = 14, PythonCode=g = 14
finish: Resetting line to return $g ;
  29 | 1 |   |    g = 14                                                                              #PL: 

Tokens: s=d ValPy: 
Main loop, line=return $g ;


 === Line 29 Perl source:return $g ;===

Lexem 0 Current token='k' perl='return' value='return' Tokenstr |k| translated: return
Lexem 1 Current token='s' perl='$g' value='g' Tokenstr |ks| translated: return g
Got ; balance=0, tno=2, nesting_last=HASH(0x800514838)

Line:   29 TokenStr: =|ks|= @ValPy: return g
Generated partial line return
expression(1, 1, 0) =|ks|= return $g

Generated partial line returng
expression returns 2
  29 | 1 |   |    return g                                                                            #PL: 

Tokens: ks ValPy: 
Main loop, line=}


 === Line 29 Perl source:}===

Got }, tno=0, source=}
exit_block at line 29, prior nesting_level=1

Line:   29 TokenStr: =|}|= @ValPy: }
loop_needs_try_block(1), top=lno 27 is_eval  level 0 type def cur_sub func in_sub 1 is_loop  is_sub 1 in_loop 0
initialize_globals_for_state_vars: 
  29 | 0 |   |
  30 | 0 |   |
Main loop, line=if($t == 2) {


 === Line 31 Perl source:if($t == 2) {===

Lexem 0 Current token='c' perl='if' value='if ' Tokenstr |c| translated: if 
Lexem 1 Current token='(' perl='(' value='(' Tokenstr |c(| translated: if  (
Lexem 2 Current token='s' perl='$t' value='t' Tokenstr |c(s| translated: if  ( t
Lexem 3 Current token='>' perl='==' value='==' Tokenstr |c(s>| translated: if  ( t ==
Lexem 4 Current token='d' perl='2' value='2' Tokenstr |c(s>d| translated: if  ( t == 2
Lexem 5 Current token=')' perl=')' value=')' Tokenstr |c(s>d)| translated: if  ( t == 2 )
enter_block at line 31, prior nesting_level=0, ValPerl=if ( $t == 2 ) {
Use of uninitialized value in join or string at /d/pythonizer/pythonizer/Perlscan.pm line 372, <> line 31.
nesting_info=is_eval  lno 31 type if  level 0 cur_sub  in_loop 0 is_sub  is_loop  in_sub 0

Line:   31 TokenStr: =|c(s>d)|= @ValPy: if  ( t == 2 )
control(0) =|c(s>d)|= if ( $t == 2 )

control-parens removed, begin=0 start=1 =|cs>d|= if $t == 2

Generated partial line if 
expression(1, 3, 0) =|cs>d|= if $t == 2

Generated partial line if t
Generated partial line if t==
Generated partial line if t==2
expression returns 4
Generated partial line if t==2:
  31 | 0 |   |if t == 2:                                                                              #PL: 

Tokens: cs>d ValPy: 
Main loop, line={


 === Line 31 Perl source:{===


Line:   31 TokenStr: =|{|= @ValPy: {
Use of uninitialized value in join or string at /d/pythonizer/pythonizer/Perlscan.pm line 466, <> line 31.
loop_needs_try_block(0), top=is_eval  lno 31 type if  level 0 cur_sub  in_loop 0 is_sub  is_loop  in_sub 0
Main loop, line=func


 === Line 32 Perl source:func===

Lexem 0 Current token='i' perl='func' value='func' Tokenstr |i| translated: func
Got }, tno=1, source=}
Got }, tno=1, ValClass=i }, source=}
parens_are_balanced

Line:   33 TokenStr: =|i|= @ValPy: func
expression(0, 0, 0) =|i|= func

Generated partial line func
Generated partial line func([
Generated partial line func([])
expression returns 1
  33 | 1 |   |    func([])                                                                            #PL: 

Tokens: i ValPy: 
Main loop, line=}


 === Line 33 Perl source:}===

Got }, tno=0, source=}
exit_block at line 33, prior nesting_level=1

Line:   33 TokenStr: =|}|= @ValPy: }
Use of uninitialized value in join or string at /d/pythonizer/pythonizer/Perlscan.pm line 466, <> line 33.
loop_needs_try_block(1), top=is_eval  lno 31 type if  level 0 cur_sub  in_loop 0 is_sub  is_loop  in_sub 0
initialize_globals_for_state_vars: 
  33 | 0 |   |
Main loop, line={


 === Line 34 Perl source:{===

enter_block at line 34, prior nesting_level=0, ValPerl={
Use of uninitialized value in join or string at /d/pythonizer/pythonizer/Perlscan.pm line 372, <> line 34.
nesting_info=cur_sub  is_loop 1 in_sub 0 in_loop 1 is_sub  lno 34 is_eval  type { level 0

Line:   34 TokenStr: =|{|= @ValPy: {
  34 | 0 |   |for _ in range(1):                                                                      #PL: 

Tokens: { ValPy: 
Use of uninitialized value in join or string at /d/pythonizer/pythonizer/Perlscan.pm line 466, <> line 34.
loop_needs_try_block(0), top=cur_sub  is_loop 1 in_sub 0 in_loop 1 is_sub  lno 34 is_eval  type { level 0
Main loop, line=assert($g == 14)


 === Line 35 Perl source:assert($g == 14)===

Lexem 0 Current token='c' perl='assert' value='assert' Tokenstr |c| translated: assert
Lexem 1 Current token='(' perl='(' value='(' Tokenstr |c(| translated: assert (
Lexem 2 Current token='s' perl='$g' value='g' Tokenstr |c(s| translated: assert ( g
Lexem 3 Current token='>' perl='==' value='==' Tokenstr |c(s>| translated: assert ( g ==
Lexem 4 Current token='d' perl='14' value='14' Tokenstr |c(s>d| translated: assert ( g == 14
Lexem 5 Current token=')' perl=')' value=')' Tokenstr |c(s>d)| translated: assert ( g == 14 )
Got }, tno=6, source=}
Got }, tno=6, ValClass=c ( s > d ) }, source=}
parens_are_balanced

Line:   36 TokenStr: =|c(s>d)|= @ValPy: assert ( g == 14 )
control(0) =|c(s>d)|= assert ( $g == 14 )

control-parens removed, begin=0 start=1 =|cs>d|= assert $g == 14

Generated partial line assert
expression(1, 3, 0) =|cs>d|= assert $g == 14

Generated partial line assertg
Generated partial line assertg==
Generated partial line assertg==14
expression returns 4
  36 | 1 |   |    assert g == 14                                                                      #PL: 

Tokens: cs>d ValPy: 
Main loop, line=}


 === Line 36 Perl source:}===

Got }, tno=0, source=}
exit_block at line 36, prior nesting_level=1

Line:   36 TokenStr: =|}|= @ValPy: }
Use of uninitialized value in join or string at /d/pythonizer/pythonizer/Perlscan.pm line 466, <> line 36.
loop_needs_try_block(1), top=cur_sub  is_loop 1 in_sub 0 in_loop 1 is_sub  lno 34 is_eval  type { level 0
initialize_globals_for_state_vars: 
  36 | 0 |   |
Main loop, line=assert($g == 14);


 === Line 37 Perl source:assert($g == 14);===

Lexem 0 Current token='c' perl='assert' value='assert' Tokenstr |c| translated: assert
Lexem 1 Current token='(' perl='(' value='(' Tokenstr |c(| translated: assert (
Lexem 2 Current token='s' perl='$g' value='g' Tokenstr |c(s| translated: assert ( g
Lexem 3 Current token='>' perl='==' value='==' Tokenstr |c(s>| translated: assert ( g ==
Lexem 4 Current token='d' perl='14' value='14' Tokenstr |c(s>d| translated: assert ( g == 14
Lexem 5 Current token=')' perl=')' value=')' Tokenstr |c(s>d)| translated: assert ( g == 14 )
Got ; balance=0, tno=6, nesting_last=HASH(0x800513b60)

Line:   37 TokenStr: =|c(s>d)|= @ValPy: assert ( g == 14 )
control(0) =|c(s>d)|= assert ( $g == 14 )

control-parens removed, begin=0 start=1 =|cs>d|= assert $g == 14

Generated partial line assert
expression(1, 3, 0) =|cs>d|= assert $g == 14

Generated partial line assertg
Generated partial line assertg==
Generated partial line assertg==14
expression returns 4
  38 | 0 |   |
  39 | 0 |   |assert g == 14                                                                          #PL: do {

Tokens: cs>d ValPy: 
Main loop, line=do {


 === Line 39 Perl source:do {===

Lexem 0 Current token='C' perl='do' value='do' Tokenstr |C| translated: do
enter_block at line 39, prior nesting_level=0, ValPerl=do {
Use of uninitialized value in join or string at /d/pythonizer/pythonizer/Perlscan.pm line 372, <> line 39.
nesting_info=in_sub 0 is_loop  is_sub  in_loop 0 cur_sub  level 0 type do lno 39 is_eval 

Line:   39 TokenStr: =|C|= @ValPy: do
  39 | 0 |   |_do_39 = True                                                                           #PL: do {

Tokens: C ValPy: 
Generated partial line while _do_39:
  39 | 0 |   |while _do_39:                                                                           #PL: 

Tokens: C ValPy: 
Main loop, line={


 === Line 39 Perl source:{===


Line:   39 TokenStr: =|{|= @ValPy: {
Use of uninitialized value in join or string at /d/pythonizer/pythonizer/Perlscan.pm line 466, <> line 39.
loop_needs_try_block(0), top=in_sub 0 is_loop  is_sub  in_loop 0 cur_sub  level 0 type do lno 39 is_eval 
Main loop, line=$g++


 === Line 40 Perl source:$g++===

Lexem 0 Current token='s' perl='$g' value='g' Tokenstr |s| translated: g
Lexem 1 Current token='^' perl='++' value='+=1' Tokenstr |s^| translated: g +=1
Got }, tno=2, source=} until($g == 16);
Got }, tno=2, ValClass=s ^ }, source=} until($g == 16);
parens_are_balanced

Line:   41 TokenStr: =|s^|= @ValPy: g +=1
handle_incr_decr(0, 1, 1) with ++assignment(0, 1) =|s^|= $g ++

Generated partial line g+=1
  41 | 1 |   |    g+=1                                                                                #PL: } until($g == 16);

Tokens: s^ ValPy: 
Main loop, line=} until($g == 16);


 === Line 41 Perl source:} until($g == 16);===

Got }, tno=0, source=} until($g == 16);
exit_block at line 41, prior nesting_level=1

Line:   41 TokenStr: =|}|= @ValPy: }
Use of uninitialized value in join or string at /d/pythonizer/pythonizer/Perlscan.pm line 466, <> line 41.
loop_needs_try_block(1), top=in_sub 0 is_loop  is_sub  in_loop 0 cur_sub  level 0 type do lno 39 is_eval 
initialize_globals_for_state_vars: 
Main loop, line=until($g == 16);


 === Line 41 Perl source:until($g == 16);===

Lexem 0 Current token='c' perl='until' value='while not ' Tokenstr |c| translated: while not 
Lexem 1 Current token='(' perl='(' value='(' Tokenstr |c(| translated: while not  (
Lexem 2 Current token='s' perl='$g' value='g' Tokenstr |c(s| translated: while not  ( g
Lexem 3 Current token='>' perl='==' value='==' Tokenstr |c(s>| translated: while not  ( g ==
Lexem 4 Current token='d' perl='16' value='16' Tokenstr |c(s>d| translated: while not  ( g == 16
Lexem 5 Current token=')' perl=')' value=')' Tokenstr |c(s>d)| translated: while not  ( g == 16 )
Got ; balance=0, tno=6, nesting_last=HASH(0x800555f00)

Line:   41 TokenStr: =|c(s>d)|= @ValPy: while not  ( g == 16 )
control(0) =|c(s>d)|= until ( $g == 16 )

control-parens removed, begin=0 start=1 =|cs>d|= until $g == 16

Generated partial line _do_39 = (not 
expression(1, 3, 0) =|cs>d|= until $g == 16

Generated partial line _do_39 = (not g
Generated partial line _do_39 = (not g==
Generated partial line _do_39 = (not g==16
expression returns 4
Generated partial line _do_39 = (not g==16)
  41 | 1 |   |    _do_39 = (not g == 16)                                                              #PL: until($g == 16);

Tokens: cs>d ValPy: 
Main loop, line=assert($g == 16);


 === Line 42 Perl source:assert($g == 16);===

Lexem 0 Current token='c' perl='assert' value='assert' Tokenstr |c| translated: assert
Lexem 1 Current token='(' perl='(' value='(' Tokenstr |c(| translated: assert (
Lexem 2 Current token='s' perl='$g' value='g' Tokenstr |c(s| translated: assert ( g
Lexem 3 Current token='>' perl='==' value='==' Tokenstr |c(s>| translated: assert ( g ==
Lexem 4 Current token='d' perl='16' value='16' Tokenstr |c(s>d| translated: assert ( g == 16
Lexem 5 Current token=')' perl=')' value=')' Tokenstr |c(s>d)| translated: assert ( g == 16 )
Use of uninitialized value $Perlscan::nesting_last in concatenation (.) or string at /d/pythonizer/pythonizer/Perlscan.pm line 522, <> line 42.
Got ; balance=0, tno=6, nesting_last=

Line:   42 TokenStr: =|c(s>d)|= @ValPy: assert ( g == 16 )
control(0) =|c(s>d)|= assert ( $g == 16 )

control-parens removed, begin=0 start=1 =|cs>d|= assert $g == 16

Generated partial line assert
expression(1, 3, 0) =|cs>d|= assert $g == 16

Generated partial line assertg
Generated partial line assertg==
Generated partial line assertg==16
expression returns 4
  43 | 0 |   |
  44 | 0 |   |assert g == 16                                                                          #PL: do {

Tokens: cs>d ValPy: 
Main loop, line=do {


 === Line 44 Perl source:do {===

Lexem 0 Current token='C' perl='do' value='do' Tokenstr |C| translated: do
enter_block at line 44, prior nesting_level=0, ValPerl=do {
Use of uninitialized value in join or string at /d/pythonizer/pythonizer/Perlscan.pm line 372, <> line 44.
nesting_info=level 0 type do is_eval  lno 44 is_sub  in_loop 0 in_sub 0 is_loop  cur_sub 

Line:   44 TokenStr: =|C|= @ValPy: do
  44 | 0 |   |_do_44 = True                                                                           #PL: do {

Tokens: C ValPy: 
Generated partial line while _do_44:
  44 | 0 |   |while _do_44:                                                                           #PL: 

Tokens: C ValPy: 
Main loop, line={


 === Line 44 Perl source:{===


Line:   44 TokenStr: =|{|= @ValPy: {
Use of uninitialized value in join or string at /d/pythonizer/pythonizer/Perlscan.pm line 466, <> line 44.
loop_needs_try_block(0), top=level 0 type do is_eval  lno 44 is_sub  in_loop 0 in_sub 0 is_loop  cur_sub 
Main loop, line=$g++


 === Line 45 Perl source:$g++===

Lexem 0 Current token='s' perl='$g' value='g' Tokenstr |s| translated: g
Lexem 1 Current token='^' perl='++' value='+=1' Tokenstr |s^| translated: g +=1
Got }, tno=2, source=} while($g == 20);
Got }, tno=2, ValClass=s ^ }, source=} while($g == 20);
parens_are_balanced

Line:   46 TokenStr: =|s^|= @ValPy: g +=1
handle_incr_decr(0, 1, 1) with ++assignment(0, 1) =|s^|= $g ++

Generated partial line g+=1
  46 | 1 |   |    g+=1                                                                                #PL: } while($g == 20);

Tokens: s^ ValPy: 
Main loop, line=} while($g == 20);


 === Line 46 Perl source:} while($g == 20);===

Got }, tno=0, source=} while($g == 20);
exit_block at line 46, prior nesting_level=1

Line:   46 TokenStr: =|}|= @ValPy: }
Use of uninitialized value in join or string at /d/pythonizer/pythonizer/Perlscan.pm line 466, <> line 46.
loop_needs_try_block(1), top=level 0 type do is_eval  lno 44 is_sub  in_loop 0 in_sub 0 is_loop  cur_sub 
initialize_globals_for_state_vars: 
Main loop, line=while($g == 20);


 === Line 46 Perl source:while($g == 20);===

Lexem 0 Current token='c' perl='while' value='while' Tokenstr |c| translated: while
Lexem 1 Current token='(' perl='(' value='(' Tokenstr |c(| translated: while (
Lexem 2 Current token='s' perl='$g' value='g' Tokenstr |c(s| translated: while ( g
Lexem 3 Current token='>' perl='==' value='==' Tokenstr |c(s>| translated: while ( g ==
Lexem 4 Current token='d' perl='20' value='20' Tokenstr |c(s>d| translated: while ( g == 20
Lexem 5 Current token=')' perl=')' value=')' Tokenstr |c(s>d)| translated: while ( g == 20 )
Got ; balance=0, tno=6, nesting_last=HASH(0x800536630)

Line:   46 TokenStr: =|c(s>d)|= @ValPy: while ( g == 20 )
control(0) =|c(s>d)|= while ( $g == 20 )

control-parens removed, begin=0 start=1 =|cs>d|= while $g == 20

Generated partial line _do_44 = (
expression(1, 3, 0) =|cs>d|= while $g == 20

Generated partial line _do_44 = (g
Generated partial line _do_44 = (g==
Generated partial line _do_44 = (g==20
expression returns 4
Generated partial line _do_44 = (g==20)
  46 | 1 |   |    _do_44 = (g == 20)                                                                  #PL: while($g == 20);

Tokens: cs>d ValPy: 
Main loop, line=assert($g == 17);


 === Line 47 Perl source:assert($g == 17);===

Lexem 0 Current token='c' perl='assert' value='assert' Tokenstr |c| translated: assert
Lexem 1 Current token='(' perl='(' value='(' Tokenstr |c(| translated: assert (
Lexem 2 Current token='s' perl='$g' value='g' Tokenstr |c(s| translated: assert ( g
Lexem 3 Current token='>' perl='==' value='==' Tokenstr |c(s>| translated: assert ( g ==
Lexem 4 Current token='d' perl='17' value='17' Tokenstr |c(s>d| translated: assert ( g == 17
Lexem 5 Current token=')' perl=')' value=')' Tokenstr |c(s>d)| translated: assert ( g == 17 )
Use of uninitialized value $Perlscan::nesting_last in concatenation (.) or string at /d/pythonizer/pythonizer/Perlscan.pm line 522, <> line 47.
Got ; balance=0, tno=6, nesting_last=

Line:   47 TokenStr: =|c(s>d)|= @ValPy: assert ( g == 17 )
control(0) =|c(s>d)|= assert ( $g == 17 )

control-parens removed, begin=0 start=1 =|cs>d|= assert $g == 17

Generated partial line assert
expression(1, 3, 0) =|cs>d|= assert $g == 17

Generated partial line assertg
Generated partial line assertg==
Generated partial line assertg==17
expression returns 4
  48 | 0 |   |assert g == 17                                                                          #PL: $ctr = 0;

Tokens: cs>d ValPy: 
Main loop, line=$ctr = 0;


 === Line 48 Perl source:$ctr = 0;===

Lexem 0 Current token='s' perl='$ctr' value='ctr' Tokenstr |s| translated: ctr
Lexem 1 Current token='=' perl='=' value='=' Tokenstr |s=| translated: ctr =
Lexem 2 Current token='d' perl='0' value='0' Tokenstr |s=d| translated: ctr = 0
Use of uninitialized value $Perlscan::nesting_last in concatenation (.) or string at /d/pythonizer/pythonizer/Perlscan.pm line 522, <> line 48.
Got ; balance=0, tno=3, nesting_last=

Line:   48 TokenStr: =|s=d|= @ValPy: ctr = 0
assignment(0, 2) =|s=d|= $ctr = 0

Generated partial line ctr
Generated partial line ctr=
assign, ValClass[limit] = d, ValPy=0, ValPerl=0

Generated partial line ctr=0
  49 | 0 |   |ctr = 0                                                                                 #PL: do {

Tokens: s=d ValPy: 
Main loop, line=do {


 === Line 49 Perl source:do {===

Lexem 0 Current token='C' perl='do' value='do' Tokenstr |C| translated: do
enter_block at line 49, prior nesting_level=0, ValPerl=do {
Use of uninitialized value in join or string at /d/pythonizer/pythonizer/Perlscan.pm line 372, <> line 49.
nesting_info=type do level 0 is_eval  lno 49 in_loop 0 is_sub  is_loop  in_sub 0 cur_sub 

Line:   49 TokenStr: =|C|= @ValPy: do
  49 | 0 |   |_do_49 = True                                                                           #PL: do {

Tokens: C ValPy: 
Generated partial line while _do_49:
  49 | 0 |   |while _do_49:                                                                           #PL: 

Tokens: C ValPy: 
Main loop, line={


 === Line 49 Perl source:{===


Line:   49 TokenStr: =|{|= @ValPy: {
Use of uninitialized value in join or string at /d/pythonizer/pythonizer/Perlscan.pm line 466, <> line 49.
loop_needs_try_block(0), top=type do level 0 is_eval  lno 49 in_loop 0 is_sub  is_loop  in_sub 0 cur_sub 
Main loop, line=$g++


 === Line 50 Perl source:$g++===

Lexem 0 Current token='s' perl='$g' value='g' Tokenstr |s| translated: g
Lexem 1 Current token='^' perl='++' value='+=1' Tokenstr |s^| translated: g +=1
Got }, tno=2, source=};
Got }, tno=2, ValClass=s ^ }, source=};
parens_are_balanced

Line:   51 TokenStr: =|s^|= @ValPy: g +=1
handle_incr_decr(0, 1, 1) with ++assignment(0, 1) =|s^|= $g ++

Generated partial line g+=1
  51 | 1 |   |    g+=1                                                                                #PL: };

Tokens: s^ ValPy: 
Main loop, line=};


 === Line 51 Perl source:};===

Got }, tno=0, source=};
exit_block at line 51, prior nesting_level=1

Line:   51 TokenStr: =|}|= @ValPy: }
Use of uninitialized value in join or string at /d/pythonizer/pythonizer/Perlscan.pm line 466, <> line 51.
loop_needs_try_block(1), top=type do level 0 is_eval  lno 49 in_loop 0 is_sub  is_loop  in_sub 0 cur_sub 
initialize_globals_for_state_vars: 
Main loop, line=;


 === Line 51 Perl source:;===

Got ; balance=0, tno=0, nesting_last=HASH(0x8005143e8)

Line:   51 TokenStr: =|c(d)|= @ValPy: while ( False )
control(0) =|c(d)|= while ( 0 )

control-parens removed, begin=0 start=1 =|cd|= while 0

Use of uninitialized value within @ValPy in numeric eq (==) at ../pythonizer line 2023, <> line 51.
Generated partial line _do_49 = (
expression(1, 1, 0) =|cd|= while 0

Generated partial line _do_49 = (False
expression returns 2
Generated partial line _do_49 = (False)
Use of uninitialized value $Perlscan::ValCom[-1] in numeric gt (>) at /d/pythonizer/pythonizer/Perlscan.pm line 2113, <> line 51.
  51 | 1 |   |    _do_49 = ( False )                                                                  #PL: ;

Tokens: cd ValPy: 
Main loop, line=while($g < 20) {


 === Line 52 Perl source:while($g < 20) {===

Lexem 0 Current token='c' perl='while' value='while' Tokenstr |c| translated: while
Lexem 1 Current token='(' perl='(' value='(' Tokenstr |c(| translated: while (
Lexem 2 Current token='s' perl='$g' value='g' Tokenstr |c(s| translated: while ( g
Lexem 3 Current token='>' perl='<' value='<' Tokenstr |c(s>| translated: while ( g <
Lexem 4 Current token='d' perl='20' value='20' Tokenstr |c(s>d| translated: while ( g < 20
Lexem 5 Current token=')' perl=')' value=')' Tokenstr |c(s>d)| translated: while ( g < 20 )
enter_block at line 52, prior nesting_level=0, ValPerl=while ( $g < 20 ) {
Use of uninitialized value in join or string at /d/pythonizer/pythonizer/Perlscan.pm line 372, <> line 52.
nesting_info=level 0 type while lno 52 is_eval  in_sub 0 is_loop 1 is_sub  in_loop 1 cur_sub 

Line:   52 TokenStr: =|c(s>d)|= @ValPy: while ( g < 20 )
control(0) =|c(s>d)|= while ( $g < 20 )

control-parens removed, begin=0 start=1 =|cs>d|= while $g < 20

Generated partial line while
expression(1, 3, 0) =|cs>d|= while $g < 20

Generated partial line whileg
Generated partial line whileg<
Generated partial line whileg<20
expression returns 4
Generated partial line whileg<20:
  52 | 0 |   |while g < 20:                                                                           #PL: 

Tokens: cs>d ValPy: 
Main loop, line={


 === Line 52 Perl source:{===


Line:   52 TokenStr: =|{|= @ValPy: {
Use of uninitialized value in join or string at /d/pythonizer/pythonizer/Perlscan.pm line 466, <> line 52.
loop_needs_try_block(0), top=level 0 type while lno 52 is_eval  in_sub 0 is_loop 1 is_sub  in_loop 1 cur_sub 
Main loop, line=$g++;


 === Line 53 Perl source:$g++;===

Lexem 0 Current token='s' perl='$g' value='g' Tokenstr |s| translated: g
Lexem 1 Current token='^' perl='++' value='+=1' Tokenstr |s^| translated: g +=1
Use of uninitialized value $Perlscan::nesting_last in concatenation (.) or string at /d/pythonizer/pythonizer/Perlscan.pm line 522, <> line 53.
Got ; balance=0, tno=2, nesting_last=

Line:   53 TokenStr: =|s^|= @ValPy: g +=1
handle_incr_decr(0, 1, 1) with ++assignment(0, 1) =|s^|= $g ++

Generated partial line g+=1
  54 | 1 |   |    g+=1                                                                                #PL: $ctr++

Tokens: s^ ValPy: 
Main loop, line=$ctr++


 === Line 54 Perl source:$ctr++===

Lexem 0 Current token='s' perl='$ctr' value='ctr' Tokenstr |s| translated: ctr
Lexem 1 Current token='^' perl='++' value='+=1' Tokenstr |s^| translated: ctr +=1
Got }, tno=2, source=}
Got }, tno=2, ValClass=s ^ }, source=}
parens_are_balanced

Line:   55 TokenStr: =|s^|= @ValPy: ctr +=1
handle_incr_decr(0, 1, 1) with ++assignment(0, 1) =|s^|= $ctr ++

Generated partial line ctr+=1
  55 | 1 |   |    ctr+=1                                                                              #PL: 

Tokens: s^ ValPy: 
Main loop, line=}


 === Line 55 Perl source:}===

Got }, tno=0, source=}
exit_block at line 55, prior nesting_level=1

Line:   55 TokenStr: =|}|= @ValPy: }
Use of uninitialized value in join or string at /d/pythonizer/pythonizer/Perlscan.pm line 466, <> line 55.
loop_needs_try_block(1), top=level 0 type while lno 52 is_eval  in_sub 0 is_loop 1 is_sub  in_loop 1 cur_sub 
initialize_globals_for_state_vars: 
  55 | 0 |   |
Main loop, line=assert($g == 20);


 === Line 56 Perl source:assert($g == 20);===

Lexem 0 Current token='c' perl='assert' value='assert' Tokenstr |c| translated: assert
Lexem 1 Current token='(' perl='(' value='(' Tokenstr |c(| translated: assert (
Lexem 2 Current token='s' perl='$g' value='g' Tokenstr |c(s| translated: assert ( g
Lexem 3 Current token='>' perl='==' value='==' Tokenstr |c(s>| translated: assert ( g ==
Lexem 4 Current token='d' perl='20' value='20' Tokenstr |c(s>d| translated: assert ( g == 20
Lexem 5 Current token=')' perl=')' value=')' Tokenstr |c(s>d)| translated: assert ( g == 20 )
Got ; balance=0, tno=6, nesting_last=HASH(0x80053ac40)

Line:   56 TokenStr: =|c(s>d)|= @ValPy: assert ( g == 20 )
control(0) =|c(s>d)|= assert ( $g == 20 )

control-parens removed, begin=0 start=1 =|cs>d|= assert $g == 20

Generated partial line assert
expression(1, 3, 0) =|cs>d|= assert $g == 20

Generated partial line assertg
Generated partial line assertg==
Generated partial line assertg==20
expression returns 4
  57 | 0 |   |assert g == 20                                                                          #PL: assert($ctr == 2);

Tokens: cs>d ValPy: 
Main loop, line=assert($ctr == 2);


 === Line 57 Perl source:assert($ctr == 2);===

Lexem 0 Current token='c' perl='assert' value='assert' Tokenstr |c| translated: assert
Lexem 1 Current token='(' perl='(' value='(' Tokenstr |c(| translated: assert (
Lexem 2 Current token='s' perl='$ctr' value='ctr' Tokenstr |c(s| translated: assert ( ctr
Lexem 3 Current token='>' perl='==' value='==' Tokenstr |c(s>| translated: assert ( ctr ==
Lexem 4 Current token='d' perl='2' value='2' Tokenstr |c(s>d| translated: assert ( ctr == 2
Lexem 5 Current token=')' perl=')' value=')' Tokenstr |c(s>d)| translated: assert ( ctr == 2 )
Got ; balance=0, tno=6, nesting_last=HASH(0x80053ac40)

Line:   57 TokenStr: =|c(s>d)|= @ValPy: assert ( ctr == 2 )
control(0) =|c(s>d)|= assert ( $ctr == 2 )

control-parens removed, begin=0 start=1 =|cs>d|= assert $ctr == 2

Generated partial line assert
expression(1, 3, 0) =|cs>d|= assert $ctr == 2

Generated partial line assertctr
Generated partial line assertctr==
Generated partial line assertctr==2
expression returns 4
  58 | 0 |   |
  59 | 0 |   |assert ctr == 2                                                                         #PL: $hell_freezes_over = 0;

Tokens: cs>d ValPy: 
Main loop, line=$hell_freezes_over = 0;


 === Line 59 Perl source:$hell_freezes_over = 0;===

Lexem 0 Current token='s' perl='$hell_freezes_over' value='hell_freezes_over' Tokenstr |s| translated: hell_freezes_over
Lexem 1 Current token='=' perl='=' value='=' Tokenstr |s=| translated: hell_freezes_over =
Lexem 2 Current token='d' perl='0' value='0' Tokenstr |s=d| translated: hell_freezes_over = 0
Got ; balance=0, tno=3, nesting_last=HASH(0x80053ac40)

Line:   59 TokenStr: =|s=d|= @ValPy: hell_freezes_over = 0
assignment(0, 2) =|s=d|= $hell_freezes_over = 0

Generated partial line hell_freezes_over
Generated partial line hell_freezes_over=
assign, ValClass[limit] = d, ValPy=0, ValPerl=0

Generated partial line hell_freezes_over=0
  60 | 0 |   |hell_freezes_over = 0                                                                   #PL: looper:{

Tokens: s=d ValPy: 
Main loop, line=looper:{


 === Line 60 Perl source:looper:{===

Lexem 0 Current token='i' perl='looper' value='looper' Tokenstr |i| translated: looper
def_label(looper)

Line:   60 TokenStr: =|i:|= @ValPy: looper :
  60 | 0 |   |# looper:
Main loop, line={


 === Line 60 Perl source:{===

enter_block at line 60, prior nesting_level=0, ValPerl={
Use of uninitialized value in join or string at /d/pythonizer/pythonizer/Perlscan.pm line 372, <> line 60.
nesting_info=lno 60 is_eval  level 0 type { label looper cur_sub  in_sub 0 is_loop 1 is_sub  in_loop 1

Line:   60 TokenStr: =|{|= @ValPy: {
  60 | 0 |   |for _ in range(1):                                                                      #PL: 

Tokens: { ValPy: 
Use of uninitialized value in join or string at /d/pythonizer/pythonizer/Perlscan.pm line 466, <> line 60.
loop_needs_try_block(0), top=lno 60 is_eval  level 0 type { label looper cur_sub  in_sub 0 is_loop 1 is_sub  in_loop 1
Main loop, line=do {


 === Line 61 Perl source:do {===

Lexem 0 Current token='C' perl='do' value='do' Tokenstr |C| translated: do
enter_block at line 61, prior nesting_level=1, ValPerl=do {
Use of uninitialized value in join or string at /d/pythonizer/pythonizer/Perlscan.pm line 372, <> line 61.
nesting_info=is_loop  in_sub 0 in_loop 1 is_sub  cur_sub  type do level 1 lno 61 is_eval 

Line:   61 TokenStr: =|C|= @ValPy: do
  61 | 1 |   |    _do_61 = True                                                                       #PL: do {

Tokens: C ValPy: 
Generated partial line while _do_61:
  61 | 1 |   |    while _do_61:                                                                       #PL: 

Tokens: C ValPy: 
Main loop, line={


 === Line 61 Perl source:{===


Line:   61 TokenStr: =|{|= @ValPy: {
Use of uninitialized value in join or string at /d/pythonizer/pythonizer/Perlscan.pm line 466, <> line 61.
loop_needs_try_block(0), top=is_loop  in_sub 0 in_loop 1 is_sub  cur_sub  type do level 1 lno 61 is_eval 
Main loop, line=$g++;


 === Line 62 Perl source:$g++;===

Lexem 0 Current token='s' perl='$g' value='g' Tokenstr |s| translated: g
Lexem 1 Current token='^' perl='++' value='+=1' Tokenstr |s^| translated: g +=1
Got ; balance=0, tno=2, nesting_last=HASH(0x80053ac40)

Line:   62 TokenStr: =|s^|= @ValPy: g +=1
handle_incr_decr(0, 1, 1) with ++assignment(0, 1) =|s^|= $g ++

Generated partial line g+=1
  63 | 2 |   |        g+=1                                                                            #PL: last if($ctr == 2);

Tokens: s^ ValPy: 
Main loop, line=last if($ctr == 2);


 === Line 63 Perl source:last if($ctr == 2);===

Lexem 0 Current token='k' perl='last' value='break' Tokenstr |k| translated: break
Lexem 0 Current token='c' perl='if' value='if ' Tokenstr |c| translated: if 
Lexem 1 Current token='(' perl='(' value='(' Tokenstr |c(| translated: if  (
Lexem 2 Current token='s' perl='$ctr' value='ctr' Tokenstr |c(s| translated: if  ( ctr
Lexem 3 Current token='>' perl='==' value='==' Tokenstr |c(s>| translated: if  ( ctr ==
Lexem 4 Current token='d' perl='2' value='2' Tokenstr |c(s>d| translated: if  ( ctr == 2
Lexem 5 Current token=')' perl=')' value=')' Tokenstr |c(s>d)| translated: if  ( ctr == 2 )
Got ; balance=0, tno=6, nesting_last=HASH(0x80053ac40)

Line:   63 TokenStr: =|c(s>d)|= @ValPy: if  ( ctr == 2 )
control(0) =|c(s>d)|= if ( $ctr == 2 )

control-parens removed, begin=0 start=1 =|cs>d|= if $ctr == 2

Generated partial line if 
expression(1, 3, 0) =|cs>d|= if $ctr == 2

Generated partial line if ctr
Generated partial line if ctr==
Generated partial line if ctr==2
expression returns 4
Generated partial line if ctr==2:
  63 | 2 |   |        if ctr == 2:                                                                    #PL: last if($ctr == 2);

Tokens: cs>d ValPy: 
Main loop, line=last if($ctr == 2);
enter_block at line 63, prior nesting_level=2, ValPerl={
Use of uninitialized value in join or string at /d/pythonizer/pythonizer/Perlscan.pm line 372, <> line 63.
nesting_info=cur_sub  is_sub  in_loop 1 in_sub 0 is_loop  is_eval  lno 63 level 2 type if
Use of uninitialized value in join or string at /d/pythonizer/pythonizer/Perlscan.pm line 466, <> line 63.
loop_needs_try_block(0), top=cur_sub  is_sub  in_loop 1 in_sub 0 is_loop  is_eval  lno 63 level 2 type if
Main loop, line=last if($ctr == 2);
Generated partial line break
  63 | 3 |   |            break                                                                       #PL: last if($ctr == 2);

Tokens: k ValPy: 
Main loop, line=last if($ctr == 2);
exit_block at line 63, prior nesting_level=3
Use of uninitialized value in join or string at /d/pythonizer/pythonizer/Perlscan.pm line 466, <> line 63.
loop_needs_try_block(1), top=cur_sub  is_sub  in_loop 1 in_sub 0 is_loop  is_eval  lno 63 level 2 type if
Main loop, line=} until($hell_freezes_over);


 === Line 64 Perl source:} until($hell_freezes_over);===

Got }, tno=0, source=} until($hell_freezes_over);
exit_block at line 64, prior nesting_level=2

Line:   64 TokenStr: =|}|= @ValPy: }
Use of uninitialized value in join or string at /d/pythonizer/pythonizer/Perlscan.pm line 466, <> line 64.
loop_needs_try_block(1), top=is_loop  in_sub 0 in_loop 1 is_sub  cur_sub  type do level 1 lno 61 is_eval 
Main loop, line=until($hell_freezes_over);


 === Line 64 Perl source:until($hell_freezes_over);===

Lexem 0 Current token='c' perl='until' value='while not ' Tokenstr |c| translated: while not 
Lexem 1 Current token='(' perl='(' value='(' Tokenstr |c(| translated: while not  (
Lexem 2 Current token='s' perl='$hell_freezes_over' value='hell_freezes_over' Tokenstr |c(s| translated: while not  ( hell_freezes_over
Lexem 3 Current token=')' perl=')' value=')' Tokenstr |c(s)| translated: while not  ( hell_freezes_over )
Got ; balance=0, tno=4, nesting_last=HASH(0x800629720)

Line:   64 TokenStr: =|c(s)|= @ValPy: while not  ( hell_freezes_over )
control(0) =|c(s)|= until ( $hell_freezes_over )

control-parens removed, begin=0 start=1 =|cs|= until $hell_freezes_over

Generated partial line _do_61 = (not 
expression(1, 1, 0) =|cs|= until $hell_freezes_over

Generated partial line _do_61 = (not hell_freezes_over
expression returns 2
Generated partial line _do_61 = (not hell_freezes_over)
  64 | 2 |   |        _do_61 = (not hell_freezes_over)                                                #PL: until($hell_freezes_over);

Tokens: cs ValPy: 
Main loop, line=}


 === Line 65 Perl source:}===

Got }, tno=0, source=}
exit_block at line 65, prior nesting_level=1

Line:   65 TokenStr: =|}|= @ValPy: }
Use of uninitialized value in join or string at /d/pythonizer/pythonizer/Perlscan.pm line 466, <> line 65.
loop_needs_try_block(1), top=lno 60 is_eval  level 0 type { label looper cur_sub  in_sub 0 is_loop 1 is_sub  in_loop 1
initialize_globals_for_state_vars: 
  65 | 0 |   |
  66 | 0 |   |
Main loop, line=print "$0 - test passed!\n";


 === Line 67 Perl source:print "$0 - test passed!\n";===

Lexem 0 Current token='f' perl='print' value='print' Tokenstr |f| translated: print
Lexem 1 Current token='"' perl='$0 - test passed!\n' value='f"{__file__} - test passed!\n"' Tokenstr |f"| translated: print f"{__file__} - test passed!\n"
Got ; balance=0, tno=2, nesting_last=HASH(0x800513c20)

Line:   67 TokenStr: =|f"|= @ValPy: print f"{__file__} - test passed!\n"
Generated partial line print(
print3(0) start=0, handle=, k=1, end_pos=1

expression(1, 1, 0) =|f"|= print $0 - test passed!\n

Generated partial line print(f"{__file__} - test passed!\n"
expression returns 2
Generated partial line print(f"{__file__} - test passed!")
  67 | 0 |   |print(f"{__file__} - test passed!")                                                     #PL: print "$0 - test passed!\n";

Tokens: f" ValPy: 
initialize_globals_for_state_vars: 
ERROR STATISTICS:  W: 1


 [Softpano-W317]:  Debug flag is set to 5


