AC_INIT(sancus-lua-core, 0.0, amery@geeks.cl)

AC_CONFIG_AUX_DIR([build-aux])
AC_CONFIG_MACRO_DIR([m4])

AM_INIT_AUTOMAKE([foreign dist-bzip2 -Wall -Werror])

LT_INIT

# lua.pc
#
PKG_CHECK_EXISTS([lua], lua_pc='lua', lua_pc='lua5.1')
PKG_CHECK_MODULES(LUA, [${lua_pc}])

# --with-install-lmod
#
AC_MSG_CHECKING([where to install lua modules])
AC_ARG_WITH([install-lmod],
	    [AS_HELP_STRING([--with-install-lmod], [where to install lua modules])],
	    [install_lmod="$withval"],
	    [install_lmod=""])

if test "x${install_lmod}" = x; then
	install_lmod=`pkg-config --variable=INSTALL_LMOD ${lua_pc}`
	if test "x${install_lmod}" = x; then
		# INSTALL_LMOD undefined, compose one
		lua_prefix=`pkg-config --variable=prefix ${lua_pc}`
		lua_ver=`pkg-config --variable=V ${lua_pc}`
		if test "x${lua_ver}" = x; then
			lua_ver=`pkg-config --variable=major_version ${lua_pc}`
			if test "x{lua_ver}" = x; then
				AC_MSG_ERROR([${lua_pc}.pc:no INSTALL_LMOD/V/major_version found])
			fi
		fi
		install_lmod=${lua_prefix}/share/lua/${lua_ver}
	fi
fi
AC_MSG_RESULT([$install_lmod])
AC_SUBST(INSTALL_LMOD, ${install_lmod})

# --with-install-cmod
#
AC_MSG_CHECKING([where to install lua C modules])
AC_ARG_WITH([install-cmod],
	    [AS_HELP_STRING([--with-install-cmod], [where to install lua C modules])],
	    [install_cmod="$withval"],
	    [install_cmod=""])

if test "x${install_cmod}" = x; then
	install_cmod=`pkg-config --variable=INSTALL_CMOD ${lua_pc}`
	if test "x${install_cmod}" = x; then
		# INSTALL_CMOD undefined, compose one
		lua_prefix=`pkg-config --variable=prefix ${lua_pc}`
		lua_ver=`pkg-config --variable=V ${lua_pc}`
		if test "x${lua_ver}" = x; then
			lua_ver=`pkg-config --variable=major_version ${lua_pc}`
			if test "x{lua_ver}" = x; then
				AC_MSG_ERROR([${lua_pc}.pc:no INSTALL_CMOD/V/major_version found])
			fi
		fi
		install_cmod=${lua_prefix}/lib/lua/${lua_ver}
	fi
fi
AC_MSG_RESULT([$install_cmod])
AC_SUBST(INSTALL_CMOD, ${install_cmod})

AC_CONFIG_FILES([sancus-lua.pc])
AC_CONFIG_FILES([Makefile
		 doc/Makefile
		 src/cmod/Makefile
		 src/lua/Makefile
		 src/Makefile])
AC_OUTPUT
