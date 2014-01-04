# Copyright 1999-2014 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=5

inherit cmake-utils multilib

DESCRIPTION="Extremely Fast Compression algorithm"
HOMEPAGE="https://code.google.com/p/lz4/"
SRC_URI="https://${PN}.googlecode.com/files/${PN}-r${PV//0_p}.tar.gz"

LICENSE="BSD-2"
SLOT="0"
IUSE=""
KEYWORDS="~amd64 ~x86"

DEPEND=""
RDEPEND="${DEPEND}"

S="${WORKDIR}/${PN}-r${PV//0_p}"
CMAKE_USE_DIR="${S}/cmake"

src_configure() {
	local mycmakeargs=(-DBUILD_SHARED_LIBS=ON)
	cmake-utils_src_configure
}

src_install() {
	dodir /usr
	dodir "/usr/$(get_libdir)"
	ln -s "$(get_libdir)" "${ED}usr/lib" || \
		die "Cannot create temporary symlink from usr/lib to usr/$(get_libdir)"

	cmake-utils_src_install

	rm "${ED}usr/lib"

	if [ -f "${ED}usr/bin/lz4c64" ]
	then
		dosym lz4c64 /usr/bin/lz4c
	else
		dosym lz4c32 /usr/bin/lz4c
	fi
}
