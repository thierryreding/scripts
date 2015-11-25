prefix ?= ${HOME}
libdir = $(prefix)/lib
bindir = $(prefix)/bin

all:

install-targets = \
	$(libdir)/cross-compile.sh \
	$(bindir)/tegra-kernel \
	$(bindir)/uboot-build \
	$(bindir)/rr-cache

$(libdir) $(bindir):
	mkdir -p $@

$(libdir)/%: lib/% | $(libdir)
	ln -s $(abspath $<) $@

$(bindir)/%: bin/% | $(bindir)
	ln -s $(abspath $<) $@

install: $(install-targets)
