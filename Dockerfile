FROM ubuntu:focal
USER root

# remove mmdebstrap apt proxy configuration if any
RUN rm -f /etc/apt/apt.conf.d/99mmdebstrap

# install apt proxy configuration script
COPY configure-apt-proxy.sh /usr/local/sbin/

# use this snippet with `buildah bud --pull-never --build-arg APT_HTTP_PROXY=http://10.0.2.2:3142 --net=private`
ARG APT_HTTP_PROXY=
RUN configure-apt-proxy.sh

RUN export DEBIAN_FRONTEND=noninteractive && \
    apt-get -qq update && \
    apt-get -y upgrade && \
    bash -c "apt-get install -y --no-install-recommends \
        sudo iproute2 \
        python3-dev python3-pip \
        jupyter jupyter-notebook jupyter-nbconvert python3-ipykernel \
        build-essential zip unzip parallel cython3 \
        python3-{argh,atomicwrites,cached-property,dolfin,future,h5py} \
        python3-{matplotlib,meshio,pandas,petsc4py,pint,pprofile,pytest} \
        python3-{scipy,sortedcontainers,sphinx,sphinx-rtd-theme,tables} \
        python3-{tabulate,tqdm,yaml,yamlordereddictloader} \
        optipng poppler-utils meshio-tools gmsh" && \
    apt-get clean && \
    pip3 install simudo && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# reset apt proxy
RUN env APT_HTTP_PROXY= configure-apt-proxy.sh

# Create user.
# Let user run anything they want as root inside the container.
RUN useradd -m -s /bin/bash user && echo "user:docker" | chpasswd && echo "user ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
WORKDIR /home/user
USER user

RUN echo 'if ! [ -e "$HOME/.updated-simudo" ] && [ y = "$UPDATE_SIMUDO_FROM_PIP" ]; then pip3 install --user --upgrade simudo && touch "$HOME/.updated-simudo"; fi' >> ~/.bashrc
