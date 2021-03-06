#!/usr/bin/env bash
apt-get update
apt-get install -y --no-install-recommends ca-certificates netbase

savedAptMark="$(apt-mark showmanual)"

apt-get install -y --no-install-recommends \
    dpkg-dev \
    gcc \
    libbz2-dev \
    libc6-dev \
    libexpat1-dev \
    libffi-dev \
    libgdbm-dev \
    liblzma-dev \
    libncursesw5-dev \
    libreadline-dev \
    libsqlite3-dev \
    libssl-dev \
    make \
    tk-dev \
    uuid-dev \
    wget \
    xz-utils \
    zlib1g-dev \
    $(command -v gpg > /dev/null || echo 'gnupg dirmngr')

wget -O python.tar.xz "$PYURL/${PYVER%%[a-z]*}/Python-$PYVER.tar.xz"
wget -O python.tar.xz.asc "$PYURL/${PYVER%%[a-z]*}/Python-$PYVER.tar.xz.asc"

export GNUPGHOME="$(mktemp -d)"

gpg --batch --keyserver ha.pool.sks-keyservers.net --recv-keys "$GPG_KEY"
gpg --batch --verify python.tar.xz.asc python.tar.xz

{ command -v gpgconf > /dev/null && gpgconf --kill all || :; }

rm -Rf "$GNUPGHOME" python.tar.xz.asc

mkdir -p /usr/src/python
tar -xJC /usr/src/python --strip-components=1 -f python.tar.xz
rm python.tar.xz

cd /usr/src/python

gnuArch="$(dpkg-architecture --query DEB_BUILD_GNU_TYPE)"

./configure \
    --build="$gnuArch" \
    --enable-loadable-sqlite-extensions \
    --enable-shared \
    --with-system-expat \
    --with-system-ffi \
    --without-ensurepip

make -j "$(nproc)"
make install
ldconfig

apt-mark auto '.*' > /dev/null
apt-mark manual $savedAptMark

find /usr/local -type f -executable -not \( -name '*tkinter*' \) -exec ldd '{}' ';' \
    | awk '/=>/ { print $(NF-1) }' \
    | sort -u \
    | xargs -r dpkg-query --search \
    | cut -d: -f1 \
    | sort -u \
    | xargs -r apt-mark manual

apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false

rm -Rf /usr/src/python

python3 --version

cd /usr/local/bin

ln -s idle3 idle
ln -s pydoc3 pydoc
ln -s python3 python
ln -s python3-config python-config

savedAptMark="$(apt-mark showmanual)"
apt-get update
apt-get install -y --no-install-recommends wget

wget -O get-pip.py 'https://bootstrap.pypa.io/get-pip.py'

apt-mark auto '.*' > /dev/null
[ -z "$savedAptMark" ] || apt-mark manual $savedAptMark
apt-get purge -y --autoremove -o APT::AutoRemove::RecommendsImportant=false
rm -Rf /var/lib/apt/lists/*

python get-pip.py --disable-pip-version-check --no-cache-dir "pip==$PIPVER"

pip --version

find /usr/local -depth \
    \( \
        \( -type d -a \( -name test -o -name tests \) \) \
        -o \
        \( -type f -a \( -name '*.pyc' -o -name '*pyo' \) \) \
    \) -exec rm -rf '{}' +

rm -f get-pip.py
