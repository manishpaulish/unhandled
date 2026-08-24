# Fallback build for environments without dune/opam (CI uses dune).
OCAMLC  ?= ocamlc
CL      ?= $(shell $(OCAMLC) -where)/compiler-libs
MODULES := effect_id effect_set effect_syntax schedulers boundaries \
           stdlib_models \
           eff_expr builder solver scheduler_check boundary_check report \
           witness driver
CMOS    := $(addprefix lib/,$(addsuffix .cmo,$(MODULES)))

all: unhandled

unhandled: $(CMOS) bin/unhandled.ml
	$(OCAMLC) -I $(CL) -I lib ocamlcommon.cma $(CMOS) bin/unhandled.ml -o $@

lib/%.cmo: lib/%.ml
	$(OCAMLC) -I $(CL) -I lib -c $<

test: unhandled
	bash test/run_tests.sh

clean:
	rm -f lib/*.cm* bin/*.cm* unhandled test/corpus/*.cm* test/corpus/*.exe

.PHONY: all test clean
