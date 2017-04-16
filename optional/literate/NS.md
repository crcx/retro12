# ns: namespace

Depends: array.forth

This implements a more flexible (but slower) replacement for the
basic scoping construct:

    {{
    ---reveal---
    }}

With this we get a new `ns:` namespace and the ability to define
arbitrary items as public.

    ns{
        ... definition ... public
        ... definition ...
        ... definition ...
        ... definition ... public
    }ns

Some top level data elements.

| Word        | Description          |
| ----------- | -------------------- |
| ns:Previous | Pointer to old dict  |
| ns:PUBLIC   | Array of public defs |
| ns:Latest   | Latest in array      |

````
'ns:Previous var
#64 array:new 'ns:PUBLIC const
'ns:Latest var
````

The `public` word adds the latest header to the `ns:PUBLIC` array.

````
:public  (-)
  &Dictionary fetch
  ns:PUBLIC &ns:Latest fetch array:nth 
  store 
  &ns:Latest v:inc ;
````

`ns:relink` builds a new dictionary chain from the public headers.

````
:ns:relink
  @ns:Latest
  [ &ns:Latest v:dec
    @ns:Previous
    ns:PUBLIC @ns:Latest array:nth
    fetch [ store ] sip
    !ns:Previous
  ] times ;
````

Begin a name space.

````
:ns{  (-)
  #0 !ns:Latest
  @Dictionary !ns:Previous ;
````

End the name space, hiding all non-public headers.

````
:}ns  (-)
  ns:relink
  @ns:Previous !Dictionary ;
````
