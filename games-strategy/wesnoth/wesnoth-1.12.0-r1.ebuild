# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=5
inherit cmake-utils eutils multilib toolchain-funcs flag-o-matic games

DESCRIPTION="Battle for Wesnoth - A fantasy turn-based strategy game"
HOMEPAGE="http://www.wesnoth.org/"
SRC_URI="https://github.com/wesnoth/wesnoth/archive/${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="amd64 ppc ppc64 x86 ~x86-fbsd"
IUSE="dbus debug dedicated doc nls openmp server tools"

RDEPEND=">=media-libs/libsdl-1.2.7:0[joystick,video,X]
	media-libs/sdl-net
	!dedicated? (
		>=media-libs/sdl-ttf-2.0.8
		>=media-libs/sdl-mixer-1.2[vorbis]
		>=media-libs/sdl-image-1.2[jpeg,png]
		dbus? ( sys-apps/dbus )
		sys-libs/zlib
		x11-libs/pango
		dev-lang/lua
		media-libs/fontconfig
	)
	>=dev-libs/boost-1.36[nls?]
	virtual/libintl"
DEPEND="${RDEPEND}
	virtual/pkgconfig
	sys-devel/gettext"

pkg_pretend() {
	if use openmp && ! tc-has-openmp; then
		eerror "You are using gcc built without 'openmp' USE."
		eerror "Switch CXX to an OpenMP capable compiler."
		die "Need openmp"
	fi
}
src_prepare() {
	# FIX: Wesnoth reinforces a strict check on NDEBUG, but NDEBUG isn't used
	#      internally by Wesnoth, thus breaking the compilation process.
	sed -i \
		-e "s:NDEBUG:_NDEBUG:" \
		src/global.hpp || die

	if use dedicated || use server ; then
		sed \
			-e "s:GAMES_BINDIR:${GAMES_BINDIR}:" \
			-e "s:GAMES_STATEDIR:${GAMES_STATEDIR}:" \
			-e "s/GAMES_USER_DED/${GAMES_USER_DED}/" \
			-e "s/GAMES_GROUP/${GAMES_GROUP}/" "${FILESDIR}"/wesnothd.rc \
			> "${T}"/wesnothd || die
	fi
	if ! use doc ; then
		sed -i \
			-e '/manual/d' \
			doc/CMakeLists.txt || die
	fi

	# bug #472994
	mv icons/wesnoth-icon-Mac.png icons/wesnoth-icon.png || die
	mv icons/map-editor-icon-Mac.png icons/wesnoth_editor-icon.png || die

	# respect LINGUAS (bug #483316)
	if [[ ${LINGUAS+set} ]] ; then
		local langs
		for lang in $(cat po/LINGUAS)
		do
			has $lang $LINGUAS && langs+="$lang "
		done
		echo "$langs" > po/LINGUAS || die
	fi
}

src_configure() {
	filter-flags -ftracer -fomit-frame-pointer
	if [[ $(gcc-major-version) -eq 3 ]] ; then
		filter-flags -fstack-protector
		append-flags -fno-stack-protector
	fi
	if use dedicated || use server ; then
		mycmakeargs=(
			"-DENABLE_CAMPAIGN_SERVER=TRUE"
			"-DENABLE_SERVER=TRUE"
			"-DSERVER_UID=${GAMES_USER_DED}"
			"-DSERVER_GID=${GAMES_GROUP}"
			"-DFIFO_DIR=${GAMES_STATEDIR}/run/wesnothd"
			)
	else
		mycmakeargs=(
			"-DENABLE_CAMPAIGN_SERVER=FALSE"
			"-DENABLE_SERVER=FALSE"
			)
	fi
	mycmakeargs+=(
		$(cmake-utils_use_enable !dedicated GAME)
		$(cmake-utils_use_enable !dedicated DESKTOP_ENTRY)
		$(cmake-utils_use_enable nls NLS)
		$(cmake-utils_use_enable nls BOOST_FILESYSTEM)
		$(cmake-utils_use_enable dbus NOTIFICATIONS)
		$(cmake-utils_use_enable debug STRICT_COMPILATION)
		$(cmake-utils_use_enable debug PEDANTIC_COMPILATION)
		$(cmake-utils_use_enable debug DEBUG_WINDOW_LAYOUT)
		$(cmake-utils_use_enable tools TOOLS)
		$(cmake-utils_use_enable openmp OMP)
		"-DCMAKE_VERBOSE_MAKEFILE=TRUE"
		"-DENABLE_FRIBIDI=FALSE"
		"-DENABLE_STRICT_COMPILATION=FALSE"
		"-DCMAKE_INSTALL_PREFIX=${GAMES_PREFIX}"
		"-DDATAROOTDIR=${GAMES_DATADIR}"
		"-DBINDIR=${GAMES_BINDIR}"
		"-DICONDIR=/usr/share/pixmaps"
		"-DDESKTOPDIR=/usr/share/applications"
		"-DLOCALEDIR=/usr/share/locale"
		"-DMANDIR=/usr/share/man"
		"-DDOCDIR=/usr/share/doc/${PF}"
		)
	cmake-utils_src_configure
}

src_compile() {
	cmake-utils_src_compile
}

src_install() {
	DOCS="README changelog players_changelog" cmake-utils_src_install
	if use dedicated || use server; then
		keepdir "${GAMES_STATEDIR}/run/wesnothd"
		doinitd "${T}"/wesnothd || die
	fi
	prepgamesdirs
}