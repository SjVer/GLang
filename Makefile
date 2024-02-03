EXE = glangc

SRCDIR = glangc
BINDIR = bin

RM = rm
MKDIR = mkdir
TC = touch

# =================== variables ===================

Y = \033[0;33m
P = \033[1;35m
G = \033[1;30m
N = \033[0m

COMMA := ,
EMPTY :=
SPACE := $(EMPTY) $(EMPTY)

SOURCES := $(shell find $(SRCDIR) -name "*.odin")
PROFILE := $(if $(release),release,debug)

# ==================== targets ====================

$(EXE): $(BINDIR)/$(EXE)

ifneq "$(shell cat $(BINDIR)/profile)" "$(PROFILE)"
.PHONY: $(BINDIR)/$(EXE)
endif

$(BINDIR)/$(EXE): $(SOURCES) | makedirs
	@printf "$(Y)[$(EXE)]$(N) "
	odin build $(SRCDIR) -out:$@ $(if $(release),,-debug)
	@echo $(PROFILE) > $(BINDIR)/profile

# ===================== tools =====================

test: glangc
	$(eval _args=$(subst $(COMMA),$(SPACE),$(args)))
	$(eval _cmd=$(BINDIR)/glangc -verbose test/test.gl -out:bin/test.txt $(_args))
	@printf "$(G)# $(_cmd)$(N)\n"
	@$(_cmd)

makedirs:
	@$(MKDIR) -p $(BINDIR)

clean:
	@$(RM) -rf $(BINDIR)