# Copyright 1999-2014 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=5

inherit cmake-utils

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
	cmake-utils_src_install

	# install headers
	insinto /usr/include
	doins lz4hc.h lz4.h
}
