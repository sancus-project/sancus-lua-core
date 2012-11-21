AM_LDFLAGS = $(SANCUS_LIBS) $(LUA_LIBS) -module -avoid-version
AM_CFLAGS = $(SANCUS_CFLAGS) $(LUA_CFLAGS)

INSTALL_CMOD = @INSTALL_CMOD@

nobase_cmod_LTLIBRARIES = sancus.la

sancus_la_SOURCES = core.c

cmoddir = $(INSTALL_CMOD)
