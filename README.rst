Redis: persistent collections as a service (and for fun)
========================================================

A quick introduction to Redis, and why I really like it

This is a talk originally produced for `PyCon UK 2018`_

History
~~~~~~~
* The talk was given at `PyCon UK 2018`_, and there is a video if it at
  https://www.youtube.com/watch?v=39zPLAlKB3U
* A practice version was given at the `September 2018`_ CamPUG_ meeting.
* I gave a preliminary version to my colleagues at work, which produced some
  useful comments.

The files
~~~~~~~~~
All sources are in reStructuredText_, and thus intended to be readable as
plain text.

* The sources for the slides are in `<redis-slides.rst>`_.
* Notes per slide (for the presenter) are separated out into `<notes-per-slide.rst>`_.
* Extended notes (with links) are in `<markup-history-extended-notes.rst>`_.

(Note that github will present the ``.rst`` files in rendered form as HTML,
albeit using their own styling (which makes notes a bit odd). If you want
to see the original reStructuredText source, you have to click on the "Raw"
link at the top of the file's page.)

Since this version of the talk uses PDF slides, which I produce via pandoc_
and TeX_, I'm including the resultant PDF files in the repository. These
will not always be as up-to-date as the source files, so check their
timestamps.

* The 4x3 aspect ratio slides are `<redis-slides-4x3.pdf>`_.
* The 16x9 aspect ratio slides are `<redis-slides-16x9.pdf>`_.
* There is a PDF version of the notes per slide in `<notes-per-slide.pdf>`_.

Making the PDF and HTML files
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
For convenience, you can use the Makefile to create the PDF slides, create the
HTML version of the extended notes, and so on. For instance::

  $ make pdf

will make the PDF files.

For what the Makefile can do, use::

  $ make help

Requirements to build the documents:

* pandoc_ and TeX_ (on mac, BasicTeX should be enough)
* docutils_ (for reStructuredText_)

and an appropriate ``make`` program if you want to use the Makefile.

.. _`PyCon UK 2018`: http://2018.pyconuk.org/
.. _CamPUG: https://www.meetup.com/CamPUG/
.. _`September 2018`: https://www.meetup.com/CamPUG/events/lwlsmpyxmbgb/
.. _pandoc: https://pandoc.org/
.. _docutils: http://docutils.sourceforge.net/
.. _reStructuredText: http://docutils.sourceforge.net/rst.html
.. _TeX: https://www.ctan.org/starter


--------

  |cc-attr-sharealike|

  This slideshow and its related files are released under a `Creative Commons
  Attribution-ShareAlike 4.0 International License`_.

.. |cc-attr-sharealike| image:: images/cc-attribution-sharealike-88x31.png
   :alt: CC-Attribution-ShareAlike image

.. _`Creative Commons Attribution-ShareAlike 4.0 International License`: http://creativecommons.org/licenses/by-sa/4.0/

.. vim: set filetype=rst tabstop=8 softtabstop=2 shiftwidth=2 expandtab:
