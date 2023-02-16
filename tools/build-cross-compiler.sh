export PREFIX="$(pwd)/cross"
export TARGET=i686-elf
export PATH="$PREFIX/bin:$PATH"

mkdir /tmp/src
cd /tmp/src

# curl -O https://ftp.gnu.org/gnu/binutils/binutils-2.40.tar.xz
# curl -O https://ftp.gnu.org/gnu/gdb/gdb-12.1.tar.xz
# curl -O https://ftp.gnu.org/gnu/gcc/gcc-12.2.0/gcc-12.2.0.tar.xz
# 
# for f in *.tar.xz; do tar xf $f; done

mkdir build-binutils
cd build-binutils

../binutils-2.40/configure --target=$TARGET --prefix="$PREFIX" --with-sysroot --disable-nls --disable-werror
make
make install

../gdb-12.1/configure --target=$TARGET --prefix="$PREFIX" --disable-werror
make all-gdb
make install-gdb

cd ..

which -- $TARGET-as || echo $TARGET-as is not in the PATH

mkdir build-gcc
cd build-gcc
../gcc-12.2.0/configure --target=$TARGET --prefix="$PREFIX" --disable-nls --enable-languages=c,c++ --without-headers
make all-gcc
make all-target-libgcc
make install-gcc
make install-target-libgcc
