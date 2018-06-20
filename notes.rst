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

.. vim: set filetype=rst tabstop=8 softtabstop=2 shiftwidth=2 expandtab:
