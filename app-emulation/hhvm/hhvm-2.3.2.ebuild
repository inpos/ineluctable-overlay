# Copyright 1999-2014 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=5
inherit user multilib-minimal linux-info cmake-utils git-2

EGIT_REPO_URI="git://github.com/facebook/folly.git"
# FIX: compilation error __builtin_ia32_crc32qi was not declared in this scope
# (see https://github.com/facebook/folly/issues/42)
EGIT_COMMIT="8e8b5e75d573305b7a9c34f4a405be5df0f17738"

DESCRIPTION="HipHop Virtual Machine, Runtime and JIT for PHP"
HOMEPAGE="http://www.hhvm.com"
SRC_URI="https://github.com/facebook/${PN}/archive/HHVM-${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="PHP-3"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="+jemalloc +inotify debug doc test xen kernel_linux"

COMMON_DEPEND="dev-cpp/glog
	amd64? ( dev-cpp/glog[unwind] )
	dev-libs/boost
	virtual/mysql
	dev-libs/libpcre
	media-libs/gd[zlib,png,jpeg]
	dev-libs/libxml2
	dev-libs/expat
	>=dev-libs/icu-52.1
	dev-cpp/tbb
	dev-libs/libmcrypt
	dev-libs/openssl
	app-arch/bzip2
	>=dev-libs/oniguruma-5.9.5
	net-nds/openldap
	sys-libs/readline
	dev-libs/libedit
	=dev-libs/libdwarf-20120410
	>=dev-libs/libmemcached-0.39
	=dev-libs/hhvm-libevent-1.4.14b
	x11-libs/libnotify
	dev-libs/jemalloc[stats]
	virtual/libiconv
	sys-libs/libcap
	net-libs/c-client[kerberos]
	>=app-arch/lz4-0_p110"
#	>=dev-python/timelib-0.2.4-r100
DEPEND="${COMMON_DEPEND}
	|| (
		dev-libs/elfutils
		dev-libs/libelf
		sys-freebsd/freebsd
	)
	app-admin/chrpath
	>=sys-devel/gcc-4.8.1:4.8[cxx]
	test? (
		=dev-lang/php-5*[simplexml,tokenizer,cli]
		dev-php/ZendFramework
	)"
RDEPEND="${COMMON_DEPEND}"

S="${WORKDIR}/${PN}-HHVM-${PV}"
EGIT_SOURCEDIR="${S}/hphp/submodules/folly"

CMAKE_IN_SOURCE_BUILD="true"

pkg_pretend() {
	# checks for kernel options
	if use kernel_linux && use inotify; then
		CONFIG_CHECK="~INOTIFY_USER"
		check_extra_config
	fi

	# checks for Xen environments
	if [[ ${RC_SYS} == XENU ]]; then
		eerror "Under XenU, 'xen' USE flag is required."
		die
	fi
}

pkg_setup() {
	ebegin "Creating hhvm user and group"
		enewgroup hhvm
		enewuser hhvm -1 -1 "/usr/lib/hhvm" hhvm
	eend $?
}

src_prepare() {
	rm -r hphp/third_party/libsqlite3 || die
#	rm -r hphp/third_party/timelib || die
	rm -r hphp/third_party/lz4 || die
	rm -r hphp/third_party/libzip || die
	epatch "${FILESDIR}/remove.bundled-libs.patch"
	# FIX: avoid symbols collision with dev-libs/icu
	epatch "${FILESDIR}/cmake.patch"
}
src_configure() {
	CMAKE_BUILD_TYPE="Release"
	HPHP_NOTEST=1

	use debug && CMAKE_BUILD_TYPE="Debug"
	use test && HPHP_NOTEST=0

	# FIX: avoid linking to the system-wide dev-libs/libevent
	# FIX: search x11-libs/libnotify headers in the proper directory
	# FIX: Xen requires special defs (see https://github.com/facebook/hhvm/issues/981)
	local mycmakeargs=(
#		"-DLIBEVENT_LIB=/opt/hhvm/$(get_libdir)/libevent.so"
#		"-DLIBEVENT_INCLUDE_DIR=/opt/hhvm/include/"
#		"-DZLIB_LIBRARIES=/$(get_libdir)/libz.so.1"
#		"-DLIBINOTIFY_INCLUDE_DIR=/usr/include/libnotify"
		"-DCMAKE_PREFIX_PATH=${EPREFIX}${PREFIX}"
		$(cmake-utils_use_no xen HARDWARE_COUNTER)
	)

	export HPHP_HOME="${S}"
	export HPHP_NOTEST
	cmake-utils_src_configure
}

src_install() {
	cmake-utils_src_install

	newinitd "${FILESDIR}"/${PN}.initd ${PN}
	newconfd "${FILESDIR}"/${PN}.confd ${PN}

	insinto /etc/hhvm
	newins "${FILESDIR}"/config.hdf.dist config.hdf.dist
	newins "${FILESDIR}"/php.ini php.ini
}

src_test() {
	einfo ">>> Test phase [test]: ${CATEGORY}/${PF}"

	# Run all closure tests in JIT mode
	pushd "${S}"/hphp
		test/run -v all || die "tests failed"
	popd

	# Run CTest
	cmake-utils_src_test
	[[ $? -eq 0 ]] || die "tests failed"

	einfo "Tests successfully completed"
}
