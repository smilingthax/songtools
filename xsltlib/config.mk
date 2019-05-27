#CXX=/home/thobi/dls/gstlfilt/gfilt
#CFLAGS+=-O3 -funroll-all-loops -finline-functions -Wall -g
FLAGS+=-Wall -g
CXXFLAGS+=
LDFLAGS+=-g
CPPFLAGS=$(CFLAGS) $(FLAGS)

PKG_CONFIG:=pkg-config

-include ../local.mk

ifneq "$(PACKAGES)" ""
  # these must be last in link ordering
  CPPFLAGS+=$(shell $(PKG_CONFIG) --cflags $(PACKAGES))
  LDFLAGS+=$(shell $(PKG_CONFIG) --libs $(PACKAGES))
endif

