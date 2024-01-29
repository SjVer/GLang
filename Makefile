TARGETS = glangc

SRCDIR = src
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

# ==================== targets ====================

define make-target

.PHONY: $1
$1: $(BINDIR)/$1

.PHONY: $(BINDIR)/$1
$(BINDIR)/$1: makedirs
	@printf "$(Y)[$1]$(N) "
	odin build $1 -out:$$@ $(if $(release),,-debug)

endef

$(foreach p,$(TARGETS),$(eval $(call make-target,$(p))))

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