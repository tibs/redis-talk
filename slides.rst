.. ========================================================
.. Redis: persistent collections as a service (and for fun)
.. ========================================================


Redis: persistent collections as a service (and for fun)
--------------------------------------------------------

A quick introduction to Redis, and why I really like it


By Tibs / Tony Ibbs

Presented at PyCon UK 2018

Written using reStructuredText_.

Converted to PDF slides using pandoc_ and beamer_.

Source and extended notes at https://github.com/tibs/redis-talk

.. _reStructuredText: http://docutils.sourceforge.net/docs/ref/rst/restructuredtext.html
.. _pandoc: https://pandoc.org
.. _beamer: https://github.com/josephwright/beamer

----

So what is Redis?
-----------------

Well `its website`_ says:

    Redis is an open source (BSD licensed), in-memory data structure store,
    used as a database, cache and message broker. It supports data structures
    such as strings, hashes, lists, sets, sorted sets with range queries,
    bitmaps, hyperloglogs and geospatial indexes with radius queries. Redis
    has built-in replication, Lua scripting, LRU eviction, transactions and
    different levels of on-disk persistence, and provides high availability
    via Redis Sentinel and automatic partitioning with Redis Cluster.

    -- https://redis.io/

.. _`its website`: https://redis.io/

... and that's not even everything it does!

-----

Multi-language support
----------------------

.. image:: images/redis_client_by_language.png


------

**Key** : value
---------------
Keys are what Redis refers to as *binary safe strings* - in Python we would
call them byte-strings.

The byte-string is actually the basic datatype in Redis.

Note that Redis does not address encodings - that has to be handled
out-of-band, which is (in context) reasonable enough.

(but note redis-py will try to do sensible things)

Traditionally, examples of Redis keys look like b"<namespace>:<name>"
(although they tend to say <server> instead of <namespace>).

----

Key: **Value**
--------------
* binary safe strings (byte strings again)
* lists
* sets
* sorted sets
* hashes
* bit arrays
* hyperloglogs and geospatial values (and so on?)

----

So, let's make a connection to a Redis server:

.. code:: sh

  tonibb01@spoon ~/sw$ redis-cli
  127.0.0.1:6379>

----

The Redis command line client is rather nice, and can be very useful for
exploring and testing.

.. image:: images/redis_cli_with_completion.png

----

It also has nice help

.. image:: images/redis_cli_help_for_hashes.png

----

However, since we're Python programmers, let's use Python:

.. code:: python

  >>> import redis
  >>> r = redis.StrictRedis(host='localhost')


----

String values
-------------

* binary safe strings, just like keys
* can be (e.g.) JSON
* again, encoding is out-of-band information

.. code:: python

  >>> r.set(b'my:string', b'some text')
  True
  >>> r.get(b'my:string')
  b'some text'

----

But also can treated as integers (so b'10' represents 10)

Atomic incremenent/decrement; Usable as sempahores

.. code:: python

  >>> r.set(b'my:number', 1)  # NB: 1 -> b'1'
  True
  >>> r.get(b'my:number')
  b'1'
  >>> r.incr(b'my:number')
  2
  >>> r.get(b'my:number')
  b'2'

----

String commands
---------------
* ``GET``, ``SET`` - get and set
* ``STRLEN`` - get length
* ``APPEND`` - append
* ``GETRANGE``, ``SETRANGE`` - get/set substring
* ``GETSET`` - set to new value and return old value
* ``SETNX`` - set only if the key does not exist

and:

* ``INCR``, ``DECR`` - increment, decrement
* ``INCRBY``, ``DECRBY`` - ditto by other values
* ``INCRBYFLOAT`` - increment by floating point value

also:

* ``MGET`` - get multiple values (from their keys)
* ``MSET`` - set multiple key/value pairs at same time
* ``MSETNX`` - ditto only if none of the keys exist

----

Argument encoding in redis-py
-----------------------------

Byte string: nothing to do

For a non-string, convert to a string:

* integer: call ``str`` on it, and encode the result as latin-1
* float: call ``repr`` on it, and encode the result as latin-1
* otherwise, call ``str`` on it

String: default to encoding as utf-8, with strict encoder errors.

So, in general, use ``b"..."`` if you can, but otherwise the library should do
something sensible.

----

List values
-----------

Very much like Python lists, but also like deques.


.. code:: python

  >>> r.lpush(b'my:list', 1, 2, 3)
  3
  >>> r.lrange(b'my:list', 0, -1)
  [b'3', b'2', b'1']
  >>> r.rpop(b'my:list')
  b'1'
  >>> r.lrange(b'my:list', 0, -1)
  [b'3', b'2']

----

List commands
-------------
* ``LPUSH``, ``RPUSH`` - push new element on either end,
* ``LPUSHX``, ``RPUSHX`` - same but only if the list exists
* ``LPOP``, ``RPOP`` - pop element from either end,
* ``BLPOP``, ``BRPOP`` - blocking versions of same,
* ``LINDEX`` - get element by index,
* ``LSET`` - set element by index,
* ``LLEN`` - get length of list,
* ``LINSERT`` - insert element before or after a particular value,
* ``LREM`` - remove N elements with a given value,
* ``LTRIM`` - trim list to specific range of indices,
* ``RPOPLPUSH`` - rotate element
* ``BRPOPLPUSH`` - blocking version of same

----

My favourite Redis instruction
------------------------------

::

  brpoplpush(src, dst, timeout=0)
      Pop a value off the tail of ``src``, push it on the
      head of ``dst`` and then return it.

      This command blocks until a value is in ``src`` or
      until ``timeout`` seconds elapse, whichever is first.
      A ``timeout`` value of 0 blocks forever.

----

.. code:: python

  >>> r.lpush('my:deque', 1, 2, 3, 4, 5)
  5
  >>> r.lrange(b'my:deque', 0, -1)
  [b'5', b'4', b'3', b'2', b'1']
  >>> r.brpoplpush(b'my:deque', b'my:deque')
  b'1'

Note how it returns the value that was rotated.

.. code:: python

  >>> r.lrange(b'my:deque', 0, -1)
  [b'1', b'5', b'4', b'3', b'2']

And of course I can use it to move the value from one list to another.

----

Set values
----------

Again, very like Python sets

.. code:: python

  >>> r.sadd(b'my:set', 'a', 'b', 'c')
  3
  >>> r.smembers(b'my:set')
  {b'a', b'c', b'b'}

----

Set commands
------------
* ``SADD`` - add an element
* ``SCARD`` - get the size of the set
* ``SDIFF`` - subtract sets
* ``SDIFFSTORE`` - same and store the result
* ``SINTER`` - intersect sets
* ``SINTERSTORE`` - same and store the result
* ``SISMEMBER`` - is a value a member?

----

Sorted set values
-----------------

::

  <key> : <value> and <score>

Done by adding a *score* (a floating point number) to each element.

Set is ordered by that score.

Altough scores do not *need* to be unique.

Can extract by value, by score, by range of scores (including positive and
negative infinity).

----

.. code:: python

  >>> r.zadd(b'my:zset', 0, 'a')
  1
  >>> r.zadd(b'my:zset', 1, 'b')
  1
  >>> r.zrange(b'my:zset', 0, -1)
  [b'a', b'b']
  >>> r.zrange(b'my:zset', 1, -1, withscores=True)
  [(b'b', 1.0)]

----

Sorted set commands
-------------------

* ``ZADD`` and so on - equivalent to set commands, but with a score
 
* ``ZADD`` - add a score and value

  * and other equivalents to set commands, but with a score

* ``ZCOUNT`` - count members with a given score
* ``ZINCBY`` - increment the score of a member
* ``ZPOPMIN``, ``ZPOPMAX`` - pop the members with lowest/highest scores
* ``ZRANGE`` - return a range (subset) of members by index
* ``ZRANGEBYSCORE`` - return a range (subset) of members by score
* all sorts of other operations...

----

Hash values
-----------

Hashes - just like Python dictionaries, although the hash keys (fields) and
values have to be binary strings.

::

  <key> : <field> : <value>

----

.. code:: python

  >>> r.hset(b'my:dict', b'k1', b'val1')
  1
  >>> r.hset(b'my:dict', b'k2', b'val2')
  1
  >>> r.hget(b'my:dict', b'k2')
  b'val2'
  >>> r.hget(b'my:dict', b'k3')     # i.e., result is None
  >>>
  >>> r.hkeys(b'my:dict')
  [b'k1', b'k2']
  >>> r.hgetall(b'my:dict')
  {b'k1': b'val1', b'k2': b'val2'}

----

Hash value commands
-------------------
* ``HSET`` - set a hash field's value
* ``HSETNX`` - set a hash field's value iff it does not exist
* ``HGET`` - get a hash field's value
* ``HDEL`` - delete one or more hash fields
* ``HEXISTS`` - does a given hash field exist?
* ``HGETALL`` - get all the hash fields and their values
* ``HKEYS`` - get all the hash fields
* ``HVALS`` - get all the values
* ``HLEN`` - get the number of fields in a hash
* ``HMGET``, ``HMSET`` - get or set multiple hash fields at the same time
* ``HSTRLEN`` - get the length of a hash field's value
* ``HSCAN`` - iterate over hash fields and their values
* ``HINCRBY`` - increment a hash field

----

Note: In general, it is possible to delete things whether they exist or not:

.. code:: python

  >>> r.delete(b'my:dict')
  1                               # It existed
  >>> r.exists(b'my:dict')
  False                           # It no longer exists
  >>> r.delete(b'no:such:thing')
  0                               # We deleted a non-existant thing
  >>> r.exists(b'no:such:thing')
  False                           # Which still doesn't exist

----

Other sorts of value
--------------------

Bit arrays: a nice specialisation of strings to give bitmaps, with useful
operations on them. Counted as string operations (in the same way that
incrementing/decrementing is counted as working on strings).

Geo-spatial items: items on a sphere representing the earth.

Hyperloglogs: if you know what they are, you probably like having them.

----

Commands on keys
----------------

* ``DEL`` delete one or more keys
* ``RENAME``, ``RENAMENX`` - rename a key, and rename only if the new name doesn't exist
* ``DUMP``, ``RESTORE`` - dump its value, serialised, and restore from same
* ``EXISTS`` - check if one or more keys exist
* ``KEYS`` - find all keys matching a particular (glob-style) pattern
* ``TYPE`` - report what type is stored at a key
* ``PEXPIRE``, etc. - set or get its TTL
* ``MIGRATE`` - migrate from one Redis instance to another
* ``MOVE`` - move to a different database
* ``SORT`` - sort (the elements of a list, set or sorted set) and return or store the
  result
* ``SCAN`` iterate over keys
* ``RANDOMKEY`` - return a random key
* ``TOUCH`` - change the last access time of a key

----

My one grumble about redis-py
-----------------------------

Redis says ``PING``:

  Returns PONG if no argument is provided, otherwise return a copy of the
  argument as a bulk.

.. code:: sh

  redis> PING
  "PONG"
  redis> PING "hello world"
  "hello world"

but redis-py doesn't work that way:

.. code:: python

  >>> r.ping()
  True
  >>> r.ping('Hello world')
  Traceback (most recent call last):
    File "<stdin>", line 1, in <module>
  TypeError: ping() takes 1 positional argument but 2 were given

----

...and the online documentation?

Is generally excellent.

It's mostly organised as articles introducing useful parts of Redis, and
specific pages for each of the individual commands.

The introductory tutorial `Introduction to Redis data types`_ is rather good.

.. _`Introduction to Redis data types`: https://redis.io/topics/data-types-intro

----

Commands overview

.. image:: images/redis_webpage_commands_smaller.png

This is laid out rather nicely, and you can select to show just the commands
for a particular type of value or other topic ("Filter by group").

-----

Individual command documentation
--------------------------------

.. image:: images/redis_webpage_command_append_smaller.png


----

Unit Testing
------------

.. code:: python

  from fakeredis import FakeRedis

  def test_my_understanding_of_zadd():
      r = FakeStrictRedis(singleton=False)

      now_timestamp = datetime(2018, 4, 23, 0, 0, 0).now()

      r.zadd(b'timeout', now_timestamp, b'text')

      assert r.zrange(b'timeout', 0, -1, withscores=True) \
          == [(b'text', now_timestamp)]

----

For asyncio, I've been experimenting with aioredis_

.. _aioredis: https://github.com/aio-libs/aioredis

which provides an API very like redis-py, but asyncio

----

Async unit testing
------------------

.. code:: python

    from fakeredis import FakeRedis

    class JustEnoughAsyncRedis:

        def __init__(self, fake_redis=None, singleton=False):
            self.redis = FakeStrictRedis(singleton=False)

        async def brpoplpush(self, sourcekey, destkey,
                             timeout=0, encoding=_NOTSET):
            return self.redis.brpoplpush(sourcekey, destkey,
                                         timeout)

        # and so on (only *with* docstrings!)

----

The asyncio version of our earlier test is very similar

.. code:: python

  @pytest.mark.asyncio
  def test_my_understanding_of_zadd(event_loop):
      ar = JustEnoughAsyncRedis()

      now_timestamp = datetime(2018, 4, 23, 0, 0, 0).now()

      await ar.zadd(b'timeout', now_timestamp, b'text')

      assert await ar.zrange(b'timeout',
                             0, -1, withscores=True) \
          == [(b'text', now_timestamp)]

----

Fin
---

Written using reStructuredText_.

Converted to PDF slides using pandoc_ and beamer_.

Source and extended notes at https://github.com/tibs/redis-talk

.. vim: set filetype=rst tabstop=8 softtabstop=2 shiftwidth=2 expandtab:
