FROM invalid
USER root

# Build command is something like:
# $ buildah bud -f debug-dolfin.Dockerfile --pull-never --from docker.io/ecdee/simudo-whatever:12345678 --arch amd64 --build-arg APT_HTTP_PROXY=http://10.0.2.2:3142 --net=private -t docker.io/ecdee/simudo-debug-dolfin:87654321 --format docker
# where 'docker.io/ecdee/simudo-whatever:12345678' is the original simudo container.

# How to use this:
# 1. Make modifications to /home/user/dolfin/src/
# 2. cd /home/user/dolfin/src/ && make -j4 && make install
# 3. Run whatever Python code uses dolfin
# 4. Repeat steps 1-3

ARG APT_HTTP_PROXY=
RUN configure-apt-proxy.sh

ARG MAKE_J=16

RUN export DEBIAN_FRONTEND=noninteractive && \
    sed -i -e 's/^# deb-src/deb-src/g' /etc/apt/sources.list && \
    apt-get -qq update && \
    mkdir dolfin && \
    cd dolfin && \
    apt-get source dolfin && \
    ln -s dolfin-*/ src && \
    mkdir bld && cd bld && \
    cmake -DCMAKE_BUILD_TYPE=None -DCMAKE_EXPORT_NO_PACKAGE_REGISTRY=ON -DCMAKE_FIND_USE_PACKAGE_REGISTRY=OFF -DCMAKE_FIND_PACKAGE_NO_PACKAGE_REGISTRY=ON -DFETCHCONTENT_FULLY_DISCONNECTED=ON -DCMAKE_INSTALL_RUNSTATEDIR=/run -DCMAKE_SKIP_INSTALL_ALL_DEPENDENCY=ON "-GUnix Makefiles" -DCMAKE_VERBOSE_MAKEFILE=ON -D CMAKE_BUILD_TYPE:STRING=RelWithDebInfo -D BUILD_SHARED_LIBS:BOOL=ON -D DOLFIN_ENABLE_TRILINOS:BOOL=OFF -D DOLFIN_ENABLE_HDF5:BOOL=ON -D HDF5_C_COMPILER_EXECUTABLE:FILEPATH=/usr/bin/h5pcc -D DOLFIN_ENABLE_PARMETIS:BOOL=OFF -D DOLFIN_ENABLE_SCOTCH:BOOL=ON -D DOLFIN_ENABLE_DOCS:BOOL=OFF -D DOLFIN_ENABLE_MPI:BOOL=ON -D MPIEXEC_PARAMS:STRING=--oversubscribe -D CMAKE_CXX_FLAGS:STRING=-fpermissive -D "DOLFIN_EXTRA_CXX_FLAGS:STRING=-g -O2 -fstack-protector-strong -fstack-clash-protection -Wformat -Werror=format-security -fcf-protection -Wdate-time -D_FORTIFY_SOURCE=2" ../src && \
    make -j"$MAKE_J" && \
    cd ../src/python && pip3 install --no-index --break-system-packages --no-build-isolation --no-deps .

# cleanup
RUN apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
