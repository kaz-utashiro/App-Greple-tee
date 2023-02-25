LIB    := ../lib/App/Greple
MODS   := $(wildcard $(LIB)/*.pm)
PM     := $(notdir $(MODS))
SRC    := $(patsubst %,src/%,$(PM))
LANG   := DE EL ET FR ID JA KO NL RO RU TR UK ZH
IGNORE := AUTHOR LICENSE
PMS    := $(foreach lang,$(LANG),$(patsubst %.pm,%.$(lang).pm,$(PM)))
MDS    := $(patsubst %.pm,%.md,$(PMS))
ALL    := $(PMS) $(MDS) README.md

all: $(ALL)

src: ; mkdir -p src

$(foreach mod,$(MODS),$(eval src/$(notdir $(mod)): $(mod) src; cp $$< src/ ))

XLATE := greple -Mxlate::deepl --match-podtext --xlate-format=none --xlate --xlate-cache=yes --all

ifdef IGNORE
$(foreach ignore,$(IGNORE),$(eval \
  XLATE += --exclude '^=head\d[ ]+$(ignore)\b(?s:.*?)(?=^=|\z)'\
))
endif

JA_FILTER := greple \
	-Mperl -Msubst::desumasu \
	--pod --subst --all --no-color --need=0 \
	--desumasu 

define LANG_PM
  %.$1.pm: src/%.pm Makefile
  ifdef $1_FILTER
	$$(XLATE) --xlate-to $1 $$< | $($1_FILTER) > $$@
  else
	$$(XLATE) --xlate-to $1 $$< > $$@
  endif
endef

$(foreach lang,$(LANG),$(eval $(call LANG_PM,$(lang))))

%.md: %.pm
	pod2markdown $< > $@

README.md: Makefile
	exec > $@ && \
	printf '## Languages\n\n' && \
	for lang in $(LANG) ; \
	do \
	    echo "- [tee.$$lang.md](tee.$$lang.md)" ; \
	done

clean:
	rm -f $(SRC) $(ALL)
