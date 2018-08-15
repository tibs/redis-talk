=====
Story
=====

So what is Redis?

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

Redis is a key-value store, which puts it in the No-SQL "family" (although
that's not particularly interesting to me).

I came across it through work, and became enthusiastic about it because:

* it presents an elegant design - it keeps letting me do what I want!
* it has good documentation
* it has excellent Python tooling
* it fill an interesting niche

My particular interest is in its use as a persistence mechanism for use with
Python.

Like the Tardis (!) this means that it can communicate data across time and
space:

* across time - a program can save data and re-acquire it later on, in a
  separate run of the process (or after a crash)
* across space - data can be shared across coroutines, threads, processes and
  processors

Also, as in the world of the Tardis, there is no problem of language (on Dr
Who everyone always appears to speak english). There are Redis clients for
many different programming languages, and an excellent command line client.

This does come at *some* compromise - there are only a limited number of
actual datastructures supported - but as we'll see the common Python
datastructures are well supported, as are some interesting other cases, and
there's always (for instance) JSON.

.. vim: set filetype=rst tabstop=8 softtabstop=2 shiftwidth=2 expandtab:
