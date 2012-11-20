#!/bin/sh

list() {
	if [ $# -eq 0 ]; then
		cat
	else
		echo "$@"
	fi | tr -s ' ' | tr ' ' '\n' | sort -V | tr '\n' '|' |
	sed -e 's,|$,,' -e 's,|, \\\n\t,g'
}

cd "${0%/*}"
cat <<EOT | tee Makefile.am
AM_LDFLAGS = \$(SANCUS_LIBS) \$(LUA_LIBS) -module -avoid-version
AM_CFLAGS = \$(SANCUS_CFLAGS) \$(LUA_CFLAGS)

nobase_cmod_LTLIBRARIES = sancus.la

sancus_la_SOURCES = $(list *.c)

cmoddir = @libdir@/lua/5.1
EOT
