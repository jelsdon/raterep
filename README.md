# raterep

## Description
Sometimes all you have to go in is the live logs.

raterep improves the accuracy when eyeing over live output to guestimate event occurance rate, all in
an easy-to-install low-dependency bash script, portable across many unix-like disctributions.

##Example usage

###MySQL client connection rate

Count the client connection rate per second into a MySQL service

~~~
$ sudo tail -s0.1 -n0 -f /var/lib/mysql/queries.log |grep --line-buffered Connect | ./raterep.sh
 [Mon Jul 22 12:37:28 EST 2013] 18
 [Mon Jul 22 12:37:29 EST 2013] 13
 [Mon Jul 22 12:37:30 EST 2013] 40
~~~
