#
#  IMAGE: cppbase, dev tools and libraries
#
FROM ubuntu:22.04 AS cppbase
LABEL desc="C++ dev container"

#
# Configure timezone so apt install wont query you later
#
ENV TZ=Etc/UTC
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

#
# Update package system & install desired packages
#
RUN apt update && apt upgrade -y && apt install
RUN apt install -y zsh curl wget gcc g++ cmake git \
                   python3 python3-pip clangd clang-format clang-tools \
		               cppcheck doxygen graphviz
                   
RUN wget https://github.com/Kitware/CMake/releases/download/v3.27.6/cmake-3.27.6-linux-x86_64.sh
RUN sh ./cmake-3.27.6-linux-x86_64.sh --skip-license --prefix=/usr/local
RUN rm cmake-3.27.6-linux-x86_64.sh 

RUN cd /usr/local && curl -LO https://github.com/neovim/neovim/releases/download/nightly/nvim-linux64.tar.gz && tar xzf nvim-linux64.tar.gz
RUN ln -s /usr/local/nvim-linux64/bin/nvim /usr/local/bin/nvim
RUN rm /usr/local/nvim-linux64.tar.gz

#
# Install OhMyZsh for fancy prompts, etc.
#
RUN sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

#
# C++ libraries from system packages 
#
RUN apt install -y protobuf-compiler libprotobuf-dev libspdlog-dev \
                   libzmq5-dev libeigen3-dev libboost-all-dev libevent-dev \
		               libdouble-conversion-dev libgoogle-glog-dev \
		               libgflags-dev libiberty-dev liblz4-dev liblzma-dev \
		               libsnappy-dev zlib1g-dev binutils-dev libjemalloc-dev \
		               libssl-dev pkg-config libunwind-dev

#
# Python 
#
RUN python3 -m pip install --upgrade pip
RUN python3 -m pip install numpy scipy sympy protobuf pyzmq

#
# C++ source libraries
# - generally header-only or static libs
# - TODO: checkout specific revisions to provide stability...
#

# Transducer library
RUN git clone https://github.com/arximboldi/zug.git && \
    mkdir zug_build && \
    (cd zug_build && cmake ../zug && make -j8 install) && \
    rm -fr zug zug_build

# C++ Ranges library
RUN git clone https://github.com/ericniebler/range-v3.git && \
    mkdir range-v3_build && \
    (cd range-v3_build && cmake -DRANGE_V3_TESTS=Off -DRANGE_V3_EXAMPLES=Off -DRANGE_V3_PERF=Off ../range-v3 && make -j8 install) && \
    rm -fr range-v3 range-v3_build

# Library for making console progress bars and indicators
RUN git clone https://github.com/p-ranav/indicators.git && \
    mkdir indicators_build && \
    (cd indicators_build && cmake ../indicators && make -j8 install) && \
    rm -fr indicators indicators_build

# Library for making console tables/figures
RUN git clone https://github.com/p-ranav/tabulate.git && \
    mkdir tabulate_build && \
    (cd tabulate_build && cmake ../tabulate && make -j8 install) && \
    rm -fr tabulate tabulate_build

# Pretty printing library
RUN git clone https://github.com/p-ranav/pprint.git && \
    mkdir pprint_build && \
    (cd pprint_build && cmake ../pprint && make -j8 install) && \
    rm -fr pprint pprint_build

# Memory mapped file library
RUN git clone https://github.com/vimpunk/mio.git && \
    mkdir mio_build && \
    (cd mio_build && cmake ../mio && make -j8 install) && \
    rm -fr mio mio_build

# Filename globbing library
RUN git clone https://github.com/p-ranav/glob.git && \
    mkdir glob_build && \
    (cd glob_build && cmake ../glob && make -j8 install) && \
    rm -fr glob glob_install

# C++ bindings for zmq
RUN git clone https://github.com/zeromq/cppzmq.git && \
    mkdir cppzmq_build && \
    (cd cppzmq_build && cmake -DCPPZMQ_BUILD_TESTS=Off ../cppzmq && make -j8 install) && \
    rm -fr cppzmq cppzmq_build

# Facebook's C++ utility library, lots of useful stuff
RUN git clone https://github.com/facebook/folly.git && \
    mkdir folly_build && \
    (cd folly_build && cmake ../folly && make -j8 install) && \
    rm -fr folly folly_build

# Runtime settings
WORKDIR /root
CMD /usr/bin/zsh

#
#  IMAGE: cppedit, adds optional neovim editing capabilities to cppbase
#
FROM cppbase as cppedit

# Other scripts and configuration files
COPY zshrc /root/.zshrc
COPY nvim /root/.config/nvim

RUN apt install -y clangd nodejs npm
RUN python3 -m pip install neovim

RUN sh -c 'curl -fLo /root/.local/share/nvim/site/autoload/plug.vim --create-dirs \
       https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'

RUN nvim +'PlugInstall --sync' +qa



