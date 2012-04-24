AC_INIT(sancus-lua, 0.0, amery@geeks.cl)

AC_CONFIG_AUX_DIR([build-aux])
AC_CONFIG_MACRO_DIR([m4])

AM_INIT_AUTOMAKE([foreign dist-bzip2 -Wall -Werror])

# lua.pc
#
PKG_CHECK_EXISTS([lua], lua_pc='lua', lua_pc='lua5.1')
PKG_CHECK_MODULES(LUA, [${lua_pc}])

install_lmod=`pkg-config --variable=INSTALL_LMOD ${lua_pc}`
if test "x${install_lmod}" = x; then
	AC_MSG_ERROR([${lua_pc}:no INSTALL_LMOD detected])
fi
AC_SUBST(INSTALL_LMOD)

AC_CONFIG_FILES([Makefile
		 doc/Makefile
		 src/lua/Makefile
		 src/Makefile])
AC_OUTPUT
