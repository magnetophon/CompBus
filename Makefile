##
# CompBus
#
# @file
# @version 0.1

SHELL := /usr/bin/env bash
DSP_FILES := $(wildcard *.dsp)
JAQT_TARGETS := $(addsuffix .jaqt, $(basename $(DSP_FILES)))
LV2_TARGETS := $(addsuffix .lv2, $(basename $(DSP_FILES)))
PREFIX :=
BINDIR := $(PREFIX)bin
LIBDIR := $(PREFIX)lib

.PHONY: all jaqt lv2 install install-jaqt install-lv2 clean

all: jaqt lv2

jaqt: $(JAQT_TARGETS)

lv2: $(LV2_TARGETS)

%.jaqt: %.dsp
	faust2jaqt -time -vec -double -t 99999 $<

%.lv2: %.dsp
	faust2lv2 -time -vec -double -gui -t 99999 $<

install-jaqt:
	mkdir -p $(DESTDIR)$(BINDIR)
	for f in $$(find . -executable -type f); do \
	cp $$f $(DESTDIR)$(BINDIR)/ ; \
	done

install-lv2:
	mkdir -p $(DESTDIR)$(LIBDIR)/lv2
	mv *.lv2/ $(DESTDIR)$(LIBDIR)/lv2

install: install-jaqt install-lv2

clean:
	rm -rf $(JAQT_TARGETS) $(LV2_TARGETS)

# end
