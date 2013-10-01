prefix ?= ${HOME}
bindir = $(prefix)/bin

all:

install-targets = \
	$(bindir)/kernel-build \
	$(bindir)/uboot-build \
	$(bindir)/rr-cache

$(bindir):
	mkdir -p $@

$(bindir)/%: % | $(bindir)
	ln -s $(abspath $<) $@

install: $(install-targets)
