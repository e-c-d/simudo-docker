FROM ubuntu:mantic
USER root

SHELL ["/bin/bash", "-c"]

# remove mmdebstrap apt proxy configuration if any
RUN rm -f /etc/apt/apt.conf.d/99mmdebstrap

# install apt proxy configuration script
COPY configure-apt-proxy.sh /usr/local/sbin/

# setup apt proxy
# $ buildah bud --pull-never --build-arg APT_HTTP_PROXY=http://10.0.2.2:3142 --net=private -t docker.io/ecdee/simudo:20211217 --format docker
ARG APT_HTTP_PROXY=
RUN configure-apt-proxy.sh

RUN export DEBIAN_FRONTEND=noninteractive && \
    apt-get -qq update && \
    apt-get -y upgrade && \
    apt-get install -y --no-install-recommends \
        sudo iproute2 fossil nano less hashdeep wget \
        python3-dev python3-pip \
        jupyter jupyter-notebook jupyter-nbconvert python3-ipykernel \
        build-essential zip unzip parallel cython3 ipython3 \
        python3-{argh,atomicwrites,cached-property,dolfin,future,h5py} \
        python3-{matplotlib,meshio,pandas,petsc4py,pint,pprofile,pygmsh,pytest} \
        python3-{scipy,sortedcontainers,sphinx,sphinx-rtd-theme,tables} \
        python3-{tabulate,tqdm,yaml,yamlordereddictloader} \
        optipng poppler-utils meshio-tools gmsh

# downloads hashes
COPY pip.hashdeep /tmp

# but why not use `pip download`? because IT RUNS UNAUTHENTICATED CODE FROM THE INTERNET
# hashdeep -rlc sha256,tiger . | grep -v -E '^##' | grep -v -E ',\./\.fslckout$'
RUN cd /tmp && mkdir download && cd download && \
    function dl_pypi() { wget -c https://files.pythonhosted.org/packages/$1/${2:0:1}/${2}/${2}-${3}; } && \
    dl_pypi source generic_escape 1.1.3.tar.gz && \
    dl_pypi source mpl_render 0.2.3.tar.gz && \
    dl_pypi source suffix-trees 0.3.0.tar.gz && \
    dl_pypi py2.py3 ipympl 0.9.3-py2.py3-none-any.whl && \
    dl_pypi source simudo 0.6.5.0.tar.gz && \
    hashdeep -alrvvk /tmp/pip.hashdeep . && \
    pip3 install --no-index --no-build-isolation --break-system-packages --no-deps ./*

# cleanup
RUN apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# reset apt proxy
RUN env APT_HTTP_PROXY= configure-apt-proxy.sh

# Create user.
# Let user run anything they want as root inside the container.
RUN useradd -m -s /bin/bash user && echo "user:docker" | chpasswd && echo "user ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
WORKDIR /home/user
USER user

RUN echo 'if ! [ -e "$HOME/.updated-simudo" ] && [ y = "$UPDATE_SIMUDO_FROM_PIP" ]; then pip3 install --no-build-isolation --break-system-packages --user --upgrade simudo && touch "$HOME/.updated-simudo"; fi' >> ~/.bashrc
