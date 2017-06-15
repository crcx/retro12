This is a quick and dirty way to find prime numbers in a set.

````
{{
  #2 'last var<n>
  :extract (s-s)
    [ @last dup-pair eq?
      [ drop-pair TRUE ]
      [ mod n:-zero? ] choose ] set:filter ;
---reveal---
  :get-primes (s-s)
    #2 !last
    dup fetch [ extract &last v:inc ] times ;
}}
````

And a test:

````
  [ #2 #500 [ dup n:inc ] times ] set:from-results
  get-primes [ putn sp ] set:for-each
````
