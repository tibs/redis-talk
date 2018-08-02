=========================
Notes for a talk on Redis
=========================

I've said I want to mention async support for using Redis at the end, but
should I just say "well, it's easy enough, so I'm just going to be async all
the way through"? I think not, but bear it in mind.

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


Some weirdnesses (from the Python view)
=======================================
Pseudo-namespacing the top-level key, e.g., ``"server:key"``, appears to be
sufficiently common that it's in all the documentation.

Everything is a bytestring, but one can ``INC`` a number.


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

Asynchronous Redis
==================

Library aioredis is an async wrapper round the redis library, and so it is
very simple to convert code.

.. code:: python

  import asyncio
  import aioredis
  import redis
  from datetime import datetime
  
  def add_something_to_set(redis, loop):
      """Add an entry to the demoSet."""
      # ... do stuff, adding `await` as appropriate
      now = datetime.utcnow()
      await redis.zadd('demoSet', now.timestamp(), b'Something')

  def redis_stuff(loop):
      """Do something with Redis."""
      redis = await aioredis.create_redis(REDIS_URL, loop=loop)

      # ... do something
      add_something_to_set(loop, redis)

      # ... and eventually
      redis.close()               # XXX Double check this doesn't need an await
      await redis.wait_closed()
  
  def main():
      loop = asyncio.get_event_loop()
      asyncio.ensure_future(redis_stuff(loop), loop=loop)
      loop.run_forever()

Testing
-------

We already use:

* freezegun
* pytest (of course)
* fakeredis

.. code:: python

  import fakeredis
  import pytest
  from aioredis.util import _NOTSET
  from freezegun import freeze_time
  
  
  class JustEnoughAsyncRedis:
      """A mockery of just enough functionality of an async Redis.

      There doesn't seem to be a "finished" mock library for aioredis.

      The obvious mockaioredis_  claims to be early alpha, only what provides
      what the author needed at the time. Also, it's not in the spam shop and
      needs to be cloned from git, which isn't *necessarily* a problem, but
      doesn't help.

      On the other hand, mockaioredis just wraps an existing mock-redis library
      (mockredis_) in enough asyncio to get the job done, and given the very few
      Redis commands we use, we might as well do that ourselves. That also means
      we can base our mock on fakreredis, which we are already using elsewhere.

      (Of course, aioredis itself just wraps redis-py.)

      .. _mockaioredis: https://github.com/kblin/mockaioredis
      .. _mockredis: https://github.com/locationlabs/mockredis

      Note that we're not *really* being asynchronous, but just enabling the
      calls to work. This should be sufficient for unit testing.
      """

      def __init__(self, fake_redis=None, singleton=False):
          """Set ourselves up.

          If 'fake_redis' is given, then we will use that (assumed to be a
          FakeStrictRedis instance), otherwise we will create our own
          FakeStrictRedis instance.

          If 'fake_redis' is given, 'singleton' is ignored. Otherwise:

          - We create our own FakeStricRedis.
          - If 'singleton' is true, then that FakeStrictRedis will be a singleton
            - i.e., there shall only be one, and thus state shall be shared.
          - If 'singleton' is false, then that FakeStrictRedis will be distinct
            from other instances of that class - i.e., state shall not be shared
            between them.
          """
          if fake_redis:
              self.redis = fake_redis
          else:
              self.redis = fakeredis.FakeStrictRedis(singleton=singleton)

      async def brpoplpush(self, sourcekey, destkey, timeout=0, encoding=_NOTSET):
          """Remove and get the last element in a list, or block until one is available."""
          return self.redis.brpoplpush(sourcekey, destkey, timeout)

      # ... and so on ...


  from demo import add_something_to_set

  @pytest.mark.asyncio
  async def test_adding_an_item(event_loop):
      """A single item gets added to demoSet."""
      redis = fakeredis.FakeStrictRedis(singleton=False)
      aredis = JustEnoughAsyncRedis(redis)

      now = datetime(2018, 4, 23, 0, 0, 0)
      now_timestamp = now.timestamp()

      assert redis.zrange('demoSet', 0, -1) == [b'message1']

      with freeze_time(now):
          await add_something_to_set(event_loop, aredis)

      assert redis.zrange('demoSet', 0, -1, withscores=True) == [(b'Something', now_timestamp)]





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

https://redis.io/topics/faq

  """
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
  """

  """
  Is using Redis together with an on-disk database a good idea?

  Yes, a common design pattern involves taking very write-heavy small data in
  Redis (and data you need the Redis data structures to model your problem in
  an efficient way), and big blobs of data into an SQL or eventually
  consistent on-disk database. Similarly sometimes Redis is used in order to
  take in memory another copy of a subset of the same data stored in the
  on-disk database. This may look similar to caching, but actually is a more
  advanced model since normally the Redis dataset is updated together with the
  on-disk DB dataset, and not refreshed on cache misses.
  """

  """What does Redis actually mean?  It means REmote DIctionary Server."""

* https://redis.io/topics/security - """Redis is designed to be accessed by
  trusted clients inside trusted environments"""

* https://redis.io/topics/ARM - Redis on ARM. Supported generally since 4.0,
  and specifically the RaspberryPI.

.. vim: set filetype=rst tabstop=8 softtabstop=2 shiftwidth=2 expandtab:
