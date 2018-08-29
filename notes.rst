=========================
Notes for a talk on Redis
=========================

.. note:: Talk accepted for PyConUK 2018, to be 25 minutes.

These are notes to myself, and I'm leaving them here because, well, why not.

This talk
=========
This is me enthusing about something new I've come across, which seems well
designed and useful for all sorts of purposes. So hopefully it will teach
other people about a new and useful resource. And, if I'm wrong about things I
say, or show gaps in my knowledge, people can hear the talk and then tell me
new things and I'll learn more. So it's win-win.

Why?
===
Persistences. This comes up every so often - I want a way to persist Python
data that is very easy (no encoding/decoding), and perhaps isn't either local
or simple files. This is of course a special case of *sharing data between
instances*, it's just the instances are separated in time.

Sharing data between "instances" - by which I mean different threads, async
processes, processes on the same machine, or even distributed processes. One
very simple mechanism for all of those is useful.

As a bonus, being programming and operating system agnostic seems a good
thing.

But it's also
=============
Yes, I know it's a NOSQL database, but that's not really the point of my
interest - it's how I can use it.

Installing and running Redis
============================

Easy on a Mac::

    $ brew install redis

    $ pipenv install redis
    
If I want "persistent" a Redis server (which restarts when I re-login) then I
can do::

    $ brew services start redis

or, for transient use::

    $ redis-server /usr/local/etc/redis.conf &

and just kill the process when I don't want it anymore.

In another terminal, I can use redis-cli to populate the inList::

    $ redis-cli
    ...
    127.0.0.1:6379> lpush inList 4 5 6 7
    (integer) 4

and observe the program reporting what it does.

CLI
===

Excellent, command completion, etc.


Redis command model
===================
One talks to the Redis server by giving it commands. This seemed weird to me
at first, but makes a lot of sense.

On the whole, the available commands appear to be very well designed.

...my favourite command, BRPOPLPUSH - it's atomic!

It feels a bit like having an assembly language?

Documentation
=============
In general, the Redis documentation is excellent.

...point to particular useful pages, including the command reference

...but note the command reference doesn't always give *all* the commands


How some Redis concepts relate to Python concepts
=================================================

* set
* dictionary (but keys are always strings)
* list

It's very natural to use Redis as a persistent back end for what would
otherwise be local Python values.

Other good things
=================
Ordered sets, where the ordering is via an integer. Which can be a timestamp,
and one can select on the range of the integers, so its easy to discard values
that are "too old"


Some weirdnesses (from the Python view)
=======================================
Pseudo-namespacing the top-level key, e.g., ``"server:key"``, appears to be
sufficiently common that it's in all the documentation.

Everything is a bytestring, but one can ``INC`` a number.

Namespacing
===========
See the above, in "weirdnesses"

Remember that a top-level key can reference a value that is itself a
dictionary, so that can be useful as well. That is, if you know you want a
dictionary, don't just store its keys at the top-level - store them in a
particular top-level key. This isn't as obvious as you'd think.

Python clients
==============
There are multiple Python clients, but the default appears to be ``redis``
(although Pypi also refers to it as ``redis-py``).

Beware that in the Python client, all the entries are byte strings
(``b"..."``). This makes sense, but is easy to forget. It does mean that one
can use ``%`` formatting, but not ``f`` strings.

Speed
=====
I've no idea. It's over HTTP. It's fast enough for what we want.

Lua scriptability
=================
Don't go into it, but mention that the documentation for this is excellent,
and makes it very easy even if you don't know Lua.

Testing
=======

The fakeredis library provides an in-memory "fake" of Redis, suitable for use
in unit testing.

Random links
============
* General asyncio stuff

  - https://docs.python.org/3/library/asyncio.html
  - https://docs.python.org/3/library/asyncio-dev.html - Develop with asyncio
  - https://pawelmhm.github.io/asyncio/python/aiohttp/2016/04/22/asyncio-aiohttp.html
    (highlights how easy it is to forget to ``await``)
  - https://snarky.ca/how-the-heck-does-async-await-work-in-python-3-5/ (Brett
    Cannon on the history and background)
  - https://www.blog.pythonlibrary.org/2016/07/26/python-3-an-intro-to-asyncio/
  - https://medium.freecodecamp.org/a-guide-to-asynchronous-programming-in-python-with-asyncio-232e2afa44f6
    which has an example of multiple tasks.
  - https://www.youtube.com/watch?v=M-UcUs7IMIM is a video (Get to grips with
    asyncio in Python 3 - Robert Smallshire) that we highly recommend.

* REDIS

  - https://pypi.org/project/redis/
  - https://redis.io/topics/quickstart
  - https://redis.io/commands
  - https://redis.io/topics/data-types-intro

  https://redis.io/topics/ARM - Redis is supported on Raspberry Pi from 4.0

  - https://github.com/aio-libs/aioredis and http://aioredis.readthedocs.io/en/v1.1.0/
  - http://aioredis.readthedocs.io/en/v1.1.0/
  - https://github.com/andymccurdy/redis-py
  - https://github.com/jonathanslenders/asyncio-redis and
    http://asyncio-redis.readthedocs.io/en/latest/ and
    https://pypi.python.org/pypi/asyncio_redis 

* Testing

  - Maybe https://github.com/pytest-dev/pytest-asyncio

    - https://pypi.python.org/pypi/pytest-asyncio
    - https://stefan.sofa-rockers.org/ has some useful looking articles

        - https://stefan.sofa-rockers.org/2015/04/22/testing-coroutines/
        - https://stefan.sofa-rockers.org/2016/03/10/advanced-asyncio-testing/

    - https://jacobbridges.github.io/post/unit-testing-with-asyncio/ compares
      using unittest and pytest.mark.asyncio

  - There's some discussion of its use at
    https://stackoverflow.com/questions/45410434/pytest-python-testing-with-asyncio
  - See https://stackoverflow.com/questions/23033939/how-to-test-python-3-4-asyncio-code#23642269
    (and other parts of that discussion mention pytest-asyncio)
  - https://blog.miguelgrinberg.com/post/unit-testing-asyncio-code
  - https://pypi.python.org/pypi/asynctest for use with unittest - has mocking
    stuff as well

* Mocking REDIS

  - https://seeknuance.com/2012/02/18/replacing-redis-with-a-python-mock/ (from
    a long time ago, 2012)
  - https://pypi.python.org/pypi/fakeredis seems to be actively
    maintained/developed. See https://github.com/jamesls/fakeredis. Lists what
    REDIS commands aren't implemented. Also, we already use fakeredis in our own
    unit tests.
  - http://malexandre.fr/2017/10/08/mocking-redis--expiration-in-python/ likes
    https://github.com/locationlabs/mockredis (mockredispy), which was last
    modified a year ago. It claims to follow on from the work described at
    https://seeknuance.com/2012/02/18/replacing-redis-with-a-python-mock/
    which I mention above.

"The Redis Lua interpreter loads seven libraries: base, table, string,
math, debug, cjson, and cmsgpack. The first several are standard libraries that
allow you to do the basic operations you’d expect from any language. The last
two let Redis understand JSON and MessagePack.

Random notes
============

https://redis.io/

    """Redis is an open source (BSD licensed), in-memory data structure store,
    used as a database, cache and message broker. It supports data structures
    such as strings, hashes, lists, sets, sorted sets with range queries,
    bitmaps, hyperloglogs and geospatial indexes with radius queries. Redis
    has built-in replication, Lua scripting, LRU eviction, transactions and
    different levels of on-disk persistence, and provides high availability
    via Redis Sentinel and automatic partitioning with Redis Cluster."""

(and take a deep breath!)

https://try.redis.io/ -- interactive tutorial

https://redis.io/commands -- nicely laid out documentation of the available
commands

https://redis.io/clients -- clients in many languages (I count 6*8 + 2 = 50),
and 14 individual links for Python

https://redis.io/documentation -- links to other documentation

https://redis.io/modules -- (some) modules that extend what you can do with
Redis

Publish/subscribe messaging https://redis.io/topics/pubsub - nb: independent
of the key space and the database number. It looks quite nice, and very easy
to use.

  .. code:: python

    >>> r = redis.StrictRedis(...)
    >>> p = r.pubsub()

    >>> r.publish('my-first-channel', 'some data')
    2
    >>> p.get_message()
    {'channel': 'my-first-channel', 'data': 'some data',
     'pattern': None, 'type': 'message'}

Lua scripting. Which is nicely explained for non-lua programmers.

Time-to-live can be set per key.

https://redis.io/topics/lru-cache -- use as a least-recently used (LRU) cache,
like memcached

Transactions

Redis (wire) protocol is simple, so (for instance)
https://redis.io/topics/mass-insert explains how to mass-insert data by
generating it directly and then piping that into redis-cli, which does
"special stuff".

Various sorts of partitioning between multiple Redis instances.

https://redis.io/topics/indexes -- recommendations on secondary indexes.

https://redis.io/topics/data-types-intro

* https://redis.io/topics/data-types is shorter and less complete

* """Redis is not a *plain* key-value store, it is actually a *data structures
  server*, supporting different kinds of values."""

  * binary-safe strings
  * lists (linked lists, so sorted by insertion order)
  * sets (unique, unsorted string elements)
  * sorted sets (every string is associated with a floating number value, its
    score. Score ranges can be used for retrieval of elements)
  * Hashes (dictionaries of fields -> values, both of which are strings)
  * Bit arrays (bitmaps) - stored as strings
  * Hyperloglogs (a probabalistic data structure, used in order to estimate a
    cardinality(!))

  NB: Whenever Redis says "string", a Python programmer should hear "bytes" -
  i.e., ``b"string"``.

* Keys may be any binary sequence.
 
  * The empty string is valid.
  * Very long (e.g., 1024 bytes) probably not a good idea. The maximum size is
    512MB.
  * But don't try to shorten artificially - still use well-named keys.
  * Try to name in a predictable manner. They use ``:`` as a "scoping"
    delimiter in key names.

* String values:

  * Maximum size 512MB
  * SET can be asked to fail if key already exists, or fail if key does not
    already exist
  * String values can be atomically incremented and decremented - i.e.,
    treated as integers

    * *atomic* - multiple clients won't be able to see "inside" the operation
      of the command - they'll see before and after, and can't interfere with
      it.

* EXISTS and DEL (does key exist, delete key (and say if it existed or not))

* TYPE to tell datatype of the value stored at a given key

* All keys can be given a timeout

* Lists: LPUSH and RPUSH, either can take more than one item

  - This is a nice example of how commands can have a prefix to indicate how
    they differ in their details, or what datastype they apply to

  and of course RPOP and LPOP

* LTRIM to "trim" a list to the given range

* "-1" in a range means "the last element" - familiar to Python programmers.

* Blocking list operations, BRPOP and BLPOP, which will block until there is
  something the list to be popped. A timeout can be specified, and can wait on
  more than one list (so it returns a pair of "key, value" so you can tell
  which list satisfied the request).

* And thus the wonderful RPOPLPUSH and BRPOPLPUSH

* Setting a key will create the key if necessary. Similarly, if a key has (no
  more) value, it will be deleted. Asking for the length of a key which has no
  value will act as if the key had an aggregate value of length 0, or whatever
  other type is appropriate.

* Lots of useful commands for operating on sets.

* Sorted sets are nice - can retrieve via range of scores. And can use
  ``-inf`` or ``+inf`` as a range limit.

* And if they all have the same score, then the values will be ordered
  lexicographically, and we can use ZRANGEBYLEX to select ranges.

* Bitmaps just leverage strings. Since strings can be up to 512MB long, the
  maximum number of bits represented is 2**32.

* Hyperhyperlogs count things with an error of less than 1% without using all
  the memory you'd need to do it accurately.

* https://redis.io/topics/streams-intro --- Redis 5.0 introduces Streams,
  which look *very* interesting.

  Abstracting heavily from that page:

    ...models a log data structure in a more abstract way, however the essence
    of the log is still intact: like a log file, often implemented as a file
    open in append only mode, Redis streams are primarily an append only data
    structure. ...

    What makes Redis streams the most complex type of Redis, despite the data
    structure itself being quite simple, is the fact that it implements
    additional, non mandatory features: a set of blocking operations allowing
    consumers to wait for new data added to a stream by producers, and in
    addition to that a concept called Consumer Groups.

    Consumer groups were initially introduced by the popular messaging system
    called Kafka (TM). Redis reimplements a similar idea in completely different
    terms, but the goal is the same: to allow a group of clients to cooperate
    consuming a different portion of the same stream of messages.

Quoting from https://redis.io/topics/faq

  Why is Redis different compared to other key-value stores?

  There are two main reasons.

  * Redis is a different evolution path in the key-value DBs where values can
    contain more complex data types, with atomic operations defined on those
    data types. Redis data types are closely related to fundamental data
    structures and are exposed to the programmer as such, without additional
    abstraction layers.
  * Redis is an in-memory but persistent on disk database, so it represents a
    different trade off where very high write and read speed is achieved with
    the limitation of data sets that can't be larger than memory. Another
    advantage of in memory databases is that the memory representation of
    complex data structures is much simpler to manipulate compared to the same
    data structures on disk, so Redis can do a lot, with little internal
    complexity. At the same time the two on-disk storage formats (RDB and AOF)
    don't need to be suitable for random access, so they are compact and
    always generated in an append-only fashion (Even the AOF log rotation is
    an append-only operation, since the new version is generated from the copy
    of data in memory). However this design also involves different challenges
    compared to traditional on-disk stores. Being the main data representation
    on memory, Redis operations must be carefully handled to make sure there
    is always an updated version of the data set on disk.

  Is using Redis together with an on-disk database a good idea?

  Yes, a common design pattern involves taking very write-heavy small data in
  Redis (and data you need the Redis data structures to model your problem in
  an efficient way), and big blobs of data into an SQL or eventually
  consistent on-disk database. Similarly sometimes Redis is used in order to
  take in memory another copy of a subset of the same data stored in the
  on-disk database. This may look similar to caching, but actually is a more
  advanced model since normally the Redis dataset is updated together with the
  on-disk DB dataset, and not refreshed on cache misses.

  What does Redis actually mean?  It means REmote DIctionary Server.

* https://redis.io/topics/security - """Redis is designed to be accessed by
  trusted clients inside trusted environments"""

* https://redis.io/topics/ARM - Redis on ARM. Supported generally since 4.0,
  and specifically the RaspberryPI.


Some (random) comparisons
=========================
* https://www.infoworld.com/article/3063161/nosql/why-redis-beats-memcached-for-caching.html
* https://www.educba.com/cassandra-vs-redis/
* https://shuaiw.github.io/2017/08/18/choosing-a-nosql-db.html

Tardis
======
Data communication through time and space - time is the persistence thing,
space is the between threads/coroutines/images/processes/processors thing.

Also, note how people on Dr Who never have a problem with languages - well,
Redis supports lots of (programming) languages in its clients (yes, a strained
analogy!).

Libraries used
==============

* aio-pika
* aioredis
* mypy
* redis
* pytest
* fakeredis
* pytest-asyncio
* freezegun

.. vim: set filetype=rst tabstop=8 softtabstop=2 shiftwidth=2 expandtab:
