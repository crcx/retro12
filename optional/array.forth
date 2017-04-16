:array:new  (n-a)
  dup , here swap allot ;
:array:max-length  (a-n)
  n:dec fetch ;
:array:in-range? (an-anf)
  dup-pair
  swap array:max-length #0 swap
  n:between? ;
:array:nth  (an-a)
  array:in-range?
  [ + ]
  [ 'ERROR:_Out_of_range:_array:nth
    nl puts nl
  ] choose ;
