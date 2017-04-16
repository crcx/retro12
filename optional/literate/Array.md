Arrays are fixed size, declared when an array is created.

In memory an array is setup as:

    <size>
    ... data ...

The starting pointer is a pointer to the data. The size is at
one cell prior to the data.

So to create an array:

    #100 array:new 'ARRAY const

````
:array:new  (n-a)
  dup , here swap allot ;
````

A word for checking the max length:

````
:array:max-length  (a-n)
  n:dec fetch ;
````

Next is a utility word to determine if a given index is valid
for the array length.

````
:array:in-range? (an-anf)
  dup-pair
  swap array:max-length #0 swap
  n:between? ;
````

And the final word, `array:nth` returns a pointer to a specific
item in an array:

    $H ARRAY #0 array:nth store
    $I ARRAY #1 array:nth store

    ARRAY #0 array:nth fetch

````
:array:nth  (an-a)
  array:in-range?
  [ + ]
  [ 'ERROR:_Out_of_range:_array:nth
    nl puts nl
  ] choose ;
````
