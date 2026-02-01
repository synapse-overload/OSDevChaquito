#!/bin/bash
admin_prefix="sudo"
[ "$(id -u)" == "0" ] && admin_prefix=''

#  Need the following dependencies for build
#  bison           Parser generator for compiler construction)
#  flex            Lexical analyzer generator for tokenization
#  libgmp3-dev     Arbitrary precision integer arithmetic library
#  libmpc-dev      Multiple precision complex number library
#  libmpfr-dev     Multiple precision floating-point arithmetic library
#  texinfo         Documentation system for GCC manuals
#  libisl-dev      Polyhedral loop optimization framework library
#  curl		   Just added this for signature verification
$admin_prefix apt install -y bison flex libgmp3-dev libmpc-dev libmpfr-dev texinfo libisl-dev curl

[ ! -f binutils-2.35.tar.xz ] && wget https://ftp.gnu.org/gnu/binutils/binutils-2.35.tar.xz 
[ ! -f binutils-2.35.tar.xz.sig ] && wget https://ftp.gnu.org/gnu/binutils/binutils-2.35.tar.xz.sig

KEY_ID=$(gpg --list-packets binutils-2.35.tar.xz.sig 2>/dev/null |
	grep -oP 'keyid \K[0-9A-F]+')

# Only if desperate import all GPG keys fron GNU
# wget https://ftp.gnu.org/gnu/gnu-keyring.gpg
# gpg --import gnu-keyring.gpg

curl -fsSL \
	"https://keyserver.ubuntu.com/pks/lookup?op=get&options=mr&search=0x$KEY_ID"\
	| gpg --import -
gpg --verify binutils-2.35.tar.xz.sig binutils-2.35.tar.xz

if [ $? -ne 0 ]; then
	echo "Invalid signature for downloaded binutils file, aborting..."
	exit 1
fi
[ ! -f gcc-10.2.0.tar.gz ] && wget https://fosszone.csd.auth.gr/gnu/gcc/gcc-10.2.0/gcc-10.2.0.tar.gz
[ ! -f gcc-10.2.0.tar.gz.sig ] && wget https://fosszone.csd.auth.gr/gnu/gcc/gcc-10.2.0/gcc-10.2.0.tar.gz.sig

KEY_ID=$(gpg --list-packets gcc-10.2.0.tar.gz.sig \
	2>/dev/null | grep -oP 'keyid \K[0-9A-F]+')

curl -fsSL \
	"https://keyserver.ubuntu.com/pks/lookup?op=get&options=mr&search=0x$KEY_ID"\
	| gpg --import -

gpg --verify gcc-10.2.0.tar.gz.sig gcc-10.2.0.tar.gz

if [ $? -ne 0 ]; then
	echo "Invalid signature for downloaded gcc file, aborting..."
	exit 1
fi

tar zxf gcc-10.2.0.tar.gz -C src
tar Jxf binutils-2.35.tar.xz -C src
