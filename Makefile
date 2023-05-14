SHELL := /usr/bin/env bash
DSP_FILES := $(wildcard *.dsp)
JAQT_TARGETS := $(basename $(DSP_FILES))
LV2_TARGETS := $(addsuffix .lv2, $(basename $(DSP_FILES)))
DESTDIR ?=
PREFIX ?= /usr/local
BINDIR ?= $(DESTDIR)$(PREFIX)/bin
LIBDIR ?= $(DESTDIR)$(PREFIX)/lib
.PHONY: all jaqt lv2 install install-jaqt install-lv2 clean

all: jaqt lv2

jaqt: $(JAQT_TARGETS)

lv2: $(LV2_TARGETS)

%: %.dsp
	faust2jaqt -time -vec -double -t -1 $<

%.lv2: %.dsp
	faust2lv2 -time -vec -double -gui -t -1 $<

install-jaqt: $(JAQT_TARGETS)
	mkdir -p $(BINDIR)
	$(foreach f, $(JAQT_TARGETS), install -m 755 $(f) $(BINDIR)/$(notdir $(f));)

install-lv2: $(LV2_TARGETS)
	install -d $(LIBDIR)/lv2
	$(foreach p,$(LV2_TARGETS),cp -rfd $(p) $(LIBDIR)/lv2;)

install: install-jaqt install-lv2

clean:
	rm -rf $(JAQT_TARGETS) $(LV2_TARGETS)
