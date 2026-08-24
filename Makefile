# Fallback build for environments without dune/opam (CI uses dune).
OCAMLC  ?= ocamlc
CL      ?= $(shell $(OCAMLC) -where)/compiler-libs
MODULES := compat effect_id effect_set effect_syntax schedulers boundaries \
           stdlib_models \
           eff_expr builder solver scheduler_check boundary_check report \
           witness driver
CMOS    := $(addprefix lib/,$(addsuffix .cmo,$(MODULES)))

all: unhandled

# Constructor descriptions moved to Data_types in 5.4; select the shim.
lib/compat.ml: lib/compat_53.ml lib/compat_54.ml
	@V=`$(OCAMLC) -version | cut -d. -f1-2`; \
	case "$$V" in \
	  5.0|5.1|5.2|5.3) cp lib/compat_53.ml lib/compat.ml ;; \
	  *) cp lib/compat_54.ml lib/compat.ml ;; \
	esac

unhandled: $(CMOS) bin/unhandled.ml
	$(OCAMLC) -I $(CL) -I lib ocamlcommon.cma $(CMOS) bin/unhandled.ml -o $@

lib/effect_id.cmo: lib/compat.cmo

lib/%.cmo: lib/%.ml
	$(OCAMLC) -I $(CL) -I lib -c $<

test: unhandled
	bash test/run_tests.sh

clean:
	rm -f lib/*.cm* bin/*.cm* lib/compat.ml unhandled test/corpus/*.cm* test/corpus/*.exe

.PHONY: all test clean
