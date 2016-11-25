# postmodernity

Postmodernity is a utility library for the Common Lisp Postmodern
library.

Postmodernity provides the DEFPGSTRUCT function to define a Common
Lisp structure and corresponding Postmodern row reader. DEFPGSTRUCT is
not intended to provide a structure-based alternative to Postmodern's
data access objects but, rather, an alternative to list and alist row
readers.

Based on the structure name, DEFPGSTRUCT also creates keyword symbols
and adds them to POSTMODERN::*RESULT-STYLES* so that they can be used
as result format arguments to POSTMODERN:QUERY, POSTMODERN:PREPARE,
POSTMODERN:DEFPREPARED, and POSTMODERN:DEFPREPARED-WITH-NAMES. Note
that in doing so, DEFPGSTRUCT accesses unexported symbols from the
POSTMODERN package.

Postmodernity depends
on [Postmodern][http://marijnhaverbeke.nl/postmodern/]
and
[Alexandria][https://common-lisp.net/project/alexandria/]. Postmodernity
is being developed
with [SBCL](http://sbcl.org/), [CCL](http://ccl.clozure.com/),
and [LispWorks](http://www.lispworks.com/) on OS X.  Hunchentools is
being deployed with SBCL on Linux/AMD64.


### Installation

```lisp
(ql:quickload "postmodernity")
```


### Example

```lisp

(postmodernity:defpgstruct site
  s-no
  s-name
  m-name
  s-address
  st-name
  (s-url #'(lambda (string) (ignore-errors (puri:parse-uri string))))
  s-published-p
  s-lat
  s-lng)

(postmodern:defprepared-with-names select-site (s-no)
  ((:select 's-no 's-name 'm-name 's-address 'st-name 's-url 's-published-p 's-lat 's-lng
    :from 'site
    :where (:= 's-no '$1))
   s-no)
  :site)

(postmodern:defprepared-with-names select-site! (s-no)
  ((:select 's-no 's-name 'm-name 's-address 'st-name 's-url 's-published-p 's-lat 's-lng
    :from 'site
    :where (:= 's-no '$1))
   s-no)
  :site!)

(postmodern:defprepared select-all-sites
  (:select 's-no 's-name 'm-name 's-address 'st-name 's-url 's-published-p 's-lat 's-lng
   :from 'site)
  :sites)

```

### License

Postmodernity is distributed under the MIT license. See LICENSE.
