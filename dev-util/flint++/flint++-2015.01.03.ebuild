# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=5
AUTOTOOLS_IN_SOURCE_BUILD=1
inherit autotools-utils

EGIT_PN="FlintPlusPlus"
EGIT_COMMIT="49b523e0cb116b2a585d86bafda5e95dcaa7195f"

DESCRIPTION="Flint++ is cross-platform, zero-dependency port of Facebook's flint"
HOMEPAGE="https://github.com/L2Program/FlintPlusPlus"
SRC_URI="https://github.com/L2Program/${EGIT_PN}/archive/${EGIT_COMMIT}.tar.gz -> ${PN}-${EGIT_COMMIT}.tar.gz"

LICENSE="Boost-1.0"
SLOT="0"
KEYWORDS="~amd64 ~arm ~x86"
IUSE=""

S="${WORKDIR}/${EGIT_PN}-${EGIT_COMMIT}/${PN//++}"

RESTRICT="mirror"

src_configure(){
	:;
}

src_install(){
	dobin "${S}/${PN}"
}