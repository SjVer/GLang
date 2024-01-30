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

# ==================== targets ====================

$(EXE): $(BINDIR)/$(EXE)

$(BINDIR)/$(EXE): $(SOURCES) | makedirs
	@printf "$(Y)[$(EXE)]$(N) "
	odin build $(SRCDIR) -out:$@ $(if $(release),,-debug)

# ===================== tools =====================

test: glangc
	$(eval _args=$(subst $(COMMA),$(SPACE),$(args)))
	$(eval _cmd=$(BINDIR)/glangc -verbose test/test.gl $(_args))
	@printf "$(G)# $(_cmd)$(N)\n"
	@$(_cmd)

makedirs:
	@$(MKDIR) -p $(BINDIR)

clean:
	@$(RM) -rf $(BINDIR)