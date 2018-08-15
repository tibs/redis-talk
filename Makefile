# This version of the Makefile assumes that pandoc and (enough of) TeX are
# available.

.PHONY: default
default: html pdf

# We don't try to provide an HTML version of the slides in this version
# - use the PDF produces by 'slides' instead.
# For various reasons, pandoc won't render markup-history-extended-notes.rst
# as PDF, so we don't bother.
.PHONY: html
html:
	rst2html.py README.rst README.html
	# Temporarily
	rst2html.py notes.rst notes.html
	rst2html.py story.rst story.html
	#rst2html.py notes-per-slide.rst notes-per-slide.html

# The available aspect ratio of slides (for beamer only) are 1610 for 16:10,
# 169 for 16:9, 149 for 14:9, 141 for 1.41:1, 54 for 5:4, 43 for 4:3 which is
# the default, and 32 # for 3:2. It's probably enough to go for the following
# pair of resolutions.
# We also make the notes-per-slide as PDF, because we can and it might be useful.
.PHONY: pdf
pdf:
	# Temporarily
	pandoc notes.rst -o notes.pdf
	pandoc story.rst -o story.pdf
	# pandoc redis-slides.rst -t beamer -o redis-slides-4x3.pdf -V aspectratio:43
	# pandoc redis-slides-wide.rst -t beamer -o redis-slides-16x9.pdf -V aspectratio:169
	# pandoc notes-per-slide.rst -o notes-per-slide.pdf

.PHONY: clean
clean:
	rm -f *.html

.PHONY: help
help:
	@echo 'make         same as: make html slides'
	@echo 'make pdf     create redis-slides-[4x3|16x9].pdf and notes-per-slide.pdf'
	@echo 'make html    create HTML files using rst2html'
	@echo 'make clean   delete HTML files'
