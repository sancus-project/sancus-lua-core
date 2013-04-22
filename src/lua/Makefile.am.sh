#!/bin/sh

find_lua() {
	find "$@" -name '*.lua' | sort -V | tr '\n' '|' |
		sed -e 's,|$,,' -e 's,|, \\\n\t,g'
}

cd "${0%/*}"
cat <<EOT | tee Makefile.am
INSTALL_LMOD = @INSTALL_LMOD@

luadatadir = \$(INSTALL_LMOD)

nobase_dist_luadata_DATA = \\
	$(find_lua sancus)
EOT
