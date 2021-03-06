# Copyright (c) Jupyter Development Team.
# Distributed under the terms of the Modified BSD License.

FROM debian:jessie 

MAINTAINER Mark McCahill "mark.mccahill@duke.edu"

USER root

# Install all OS dependencies for notebook server that starts but lacks all
# features (e.g., download as all possible file formats)
ENV DEBIAN_FRONTEND noninteractive
RUN REPO=http://cdn-fastly.deb.debian.org \
 && echo "deb $REPO/debian jessie main\ndeb $REPO/debian-security jessie/updates main" > /etc/apt/sources.list \
 && apt-get update && apt-get -yq dist-upgrade \
 && apt-get install -yq --no-install-recommends \
    wget \
    bzip2 \
    ca-certificates \
    sudo \
    locales \
    git \
    vim \
    jed \
    emacs \
    build-essential \
    python-dev \
    unzip \
    libsm6 \
    pandoc \
    texlive-latex-base \
    texlive-latex-extra \
    texlive-fonts-extra \
    texlive-fonts-recommended \
    texlive-generic-recommended \
    libxrender1 \
    inkscape \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

RUN echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && \
    locale-gen

# Install Tini
RUN wget --quiet https://github.com/krallin/tini/releases/download/v0.10.0/tini && \
    echo "1361527f39190a7338a0b434bd8c88ff7233ce7b9a4876f3315c22fce7eca1b0 *tini" | sha256sum -c - && \
    mv tini /usr/local/bin/tini && \
    chmod +x /usr/local/bin/tini

# Configure environment
ENV CONDA_DIR /opt/conda
ENV PATH $CONDA_DIR/bin:$PATH
ENV SHELL /bin/bash
ENV NB_USER jovyan
ENV NB_UID 1000
ENV HOME /home/$NB_USER
ENV LC_ALL en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US.UTF-8

# Create jovyan user with UID=1000 and in the 'users' group
RUN useradd -m -s /bin/bash -N -u $NB_UID $NB_USER && \
    mkdir -p $CONDA_DIR && \
    chown $NB_USER $CONDA_DIR

USER $NB_USER

# Setup jovyan home directory
RUN mkdir /home/$NB_USER/work && \
    mkdir /home/$NB_USER/.jupyter && \
    echo "cacert=/etc/ssl/certs/ca-certificates.crt" > /home/$NB_USER/.curlrc

# Install conda as jovyan
RUN cd /tmp && \
    mkdir -p $CONDA_DIR && \
    wget --quiet https://repo.continuum.io/miniconda/Miniconda3-4.3.30-Linux-x86_64.sh && \
    # echo "bd1655b4b313f7b2a1f2e15b7b925d03 *Miniconda3-4.3.30-Linux-x86_64.sh" | sha256sum -c - && \
    /bin/bash Miniconda3-4.3.30-Linux-x86_64.sh -f -b -p $CONDA_DIR && \
    rm Miniconda3-4.3.30-Linux-x86_64.sh && \
    $CONDA_DIR/bin/conda install --quiet --yes conda==4.3.30 && \
    $CONDA_DIR/bin/conda config --system --add channels conda-forge && \
    $CONDA_DIR/bin/conda config --system --set auto_update_conda false # && \
    # conda clean -tipsy

# Temporary workaround for https://github.com/jupyter/docker-stacks/issues/210
# Stick with jpeg 8 to avoid problems with R packages
RUN echo "jpeg 8*" >> /opt/conda/conda-meta/pinned

# Install Jupyter notebook as jovyan
RUN conda install --quiet --yes \
    'jupyter' 
    # 'notebook' \
    # 'jupyterhub' \
    # 'jupyterlab' # \
    # && conda clean -tipsy
    

#----------- scipy
USER root

# libav-tools for matplotlib anim
RUN apt-get update && \
    apt-get install -y --no-install-recommends \ 
      libav-tools && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

USER $NB_USER

# Install Python 3 packages
# Remove pyqt and qt pulled in for matplotlib since we're only ever going to
# use notebook-friendly backends in these images
RUN conda install  --yes \
    'nomkl' \
    'ipywidgets' \
    'pandas' \
    'numexpr' \
    'matplotlib' \
    'scipy' \
    'seaborn' \
    'scikit-learn' \
    'scikit-image' \
    'sympy' \
    'cython' \
    'patsy' \
    'statsmodels' \
    'cloudpickle' \
    'dill' \
    'numba' \
    'bokeh' \
    'sqlalchemy' \
    'hdf5' \
    'h5py' \
    'vincent' \
    'beautifulsoup4' \
    'openpyxl' \
    'pandas-datareader' \
    'ipython-sql' \
    'pandasql' \
    'memory_profiler'\
    'psutil' \
    'cythongsl' \
    'joblib' \
    'ipyparallel' \
    'pybind11' \
    'pytables' \
    #    'cppimport' \
    'xlrd'  \ 
	# moved up from below to install  earlier
	'numpy' \
	'pillow' \
	'requests' \
	'nose' \
	'pystan' && \
    conda remove --quiet --yes --force qt pyqt # && \
    # conda clean -tipsy

# Activate ipywidgets extension in the environment that runs the notebook server
RUN jupyter nbextension enable --py widgetsnbextension --sys-prefix
RUN ipcluster nbextension  enable --user

# # No Python 2 needed

# # Install Python 2 packages
# # Remove pyqt and qt pulled in for matplotlib since we're only ever going to
# # use notebook-friendly backends in these images
# RUN conda create --quiet --yes -p $CONDA_DIR/envs/python2 python=2.7 \
#     'nomkl' \
#     'ipython' \
#     'ipywidget' \
#     'pandas' \
#     'numexpr' \
#     'matplotlib' \
#     'scipy' \
#     'seaborn' \
#     'scikit-learn' \
#     'scikit-image' \
#     'sympy' \
#     'cython' \
#     'patsy' \
#     'statsmodels' \
#     'cloudpickle' \
#     'dill' \
#     'numba' \
#     'bokeh' \
#     'hdf5' \
#     'h5py' \
#     'sqlalchemy' \
#     'pyzmq' \
#     'vincent' \
#     'beautifulsoup4' \
#     'pytables' \
#     'xlrd' && \
#     conda remove -n python2 --quiet --yes --force qt pyqt # && \
#     # conda clean -tipsy
# # Add shortcuts to distinguish pip for python2 and python3 envs

# # RUN ln -s $CONDA_DIR/envs/python2/bin/pip $CONDA_DIR/bin/pip2 && \
# #     ln -s $CONDA_DIR/bin/pip $CONDA_DIR/bin/pip3

# # Import matplotlib the first time to build the font cache.
# ENV XDG_CACHE_HOME /home/$NB_USER/.cache/
# RUN MPLBACKEND=Agg $CONDA_DIR/envs/python2/bin/python -c "import matplotlib.pyplot"

# # Configure ipython kernel to use matplotlib inline backend by default
# RUN mkdir -p $HOME/.ipython/profile_default/startup
# COPY mplimporthook.py $HOME/.ipython/profile_default/startup/

# USER root

# # Install Python 2 kernel spec globally to avoid permission problems when NB_UID
# # switching at runtime.
# RUN $CONDA_DIR/envs/python2/bin/python -m ipykernel install

USER $NB_USER

#----------- end scipy

#----------- datascience
USER root

# R pre-requisites
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    fonts-dejavu \
    gfortran \
    gcc && apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Julia dependencies
# RUN echo "deb http://ppa.launchpad.net/staticfloat/juliareleases/ubuntu trusty main" > /etc/apt/sources.list.d/julia.list && \
#     apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 3D3D3ACC && \
#     apt-get update && \
#     apt-get install -y --no-install-recommends \
#     julia \
#     libnettle4 && apt-get clean && \
#     rm -rf /var/lib/apt/lists/*
    
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    graphviz \
    libgraphviz-dev \
    pkg-config && apt-get clean && \
    rm -rf /var/lib/apt/lists/*

USER $NB_USER

# R packages including IRKernel which gets installed globally.
# Pin r-base to a specific build number for https://github.com/jupyter/docker-stacks/issues/210#issuecomment-246081809
RUN conda config --add channels r && \
    conda install --yes \
    'rpy2=2.8*' \
    'r-base=3.3.1 1' \
    'r-irkernel=0.7*' \
    'r-plyr=1.8*' \
    'r-devtools=1.11*' \
    'r-dplyr=0.4*' \
    'r-ggplot2=2.1*' \
    'r-tidyr=0.5*' \
    'r-shiny=0.13*' \
    'r-rmarkdown=0.9*' \
    'r-forecast=7.1*' \
    'r-stringr=1.0*' \
    'r-rsqlite=1.0*' \
    'r-reshape2=1.4*' \
    'r-nycflights13=0.2*' \
    'r-caret=6.0*' \
    'r-rcurl=1.95*' \
    'r-randomforest=4.6*' # && conda clean -tipsy

# ******** no Julia for now ********
##	
##  # Install IJulia packages as jovyan and then move the kernelspec out
##  # to the system share location. Avoids problems with runtime UID change not
##  # taking effect properly on the .local folder in the jovyan home dir.
##  RUN julia -e 'Pkg.add("IJulia")' && \
##      mv $HOME/.local/share/jupyter/kernels/julia* $CONDA_DIR/share/jupyter/kernels/ && \
##      chmod -R go+rx $CONDA_DIR/share/jupyter && \
##      rm -rf $HOME/.local
##  
##  # Show Julia where conda libraries are
##  # Add essential packages
##  RUN echo "push!(Libdl.DL_LOAD_PATH, \"$CONDA_DIR/lib\")" > /home/$NB_USER/.juliarc.jl && \
##      julia -e 'Pkg.add("Gadfly")' && julia -e 'Pkg.add("RDatasets")' && julia -F -e 'Pkg.add("HDF5")'
##  
##  # Precompile Julia pakcages
##  RUN julia -e 'using IJulia' && julia -e 'using Gadfly' && julia -e 'using RDatasets'&& julia -e 'using HDF5'
##  
# ******** no Julia for now ********

#----------- end datascience

USER root

EXPOSE 8888
WORKDIR /home/$NB_USER/work

# Configure container startup
ENTRYPOINT ["tini", "--"]
CMD ["start-notebook.sh"]

# Add local files as late as possible to avoid cache busting
COPY start.sh /usr/local/bin/
COPY start-notebook.sh /usr/local/bin/
COPY start-singleuser.sh /usr/local/bin/
COPY jupyter_notebook_config.py /home/$NB_USER/.jupyter/
RUN chown -R $NB_USER:users /home/$NB_USER/.jupyter

#--------- Duke-specific additions ---
# add bash kernel for the user jovyan
USER jovyan
RUN pip install  bash_kernel
RUN python -m bash_kernel.install
USER root

# move this up to install with the other CONDA stuff since 
# installing it here seems to cause a timeout on hub.docker.com automated build
#RUN conda install --yes \
#    'numpy' \
#    'pillow' \
#    'requests' \
#    'nose' \
#    'pystan' \
#   && conda clean -yt

USER root

# we need dvipng so that matplotlib can do LaTeX
# we want OpenBLAS for faster linear algebra as described here: http://brettklamer.com/diversions/statistical/faster-blas-in-r/
# Armadillo C++ linear algebra library - see http://arma.sourceforge.net
RUN apt-get update \
 && apt-get install -yq --no-install-recommends \
    dvipng \
    libopenblas-base \
    libarmadillo4 \
    libarmadillo-dev \
    liblapack3 \
    libblas-dev \
    liblapack-dev \
    libeigen3-dev \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

# ggplot
#
RUN pip install ggplot
RUN pip install cppimport

# pgmpy is not available in anaconda, so we use pip to install it
RUN pip install pgmpy
RUN pip install pygraphviz

# Probabilistic programmming
RUN pip install tensorflow
RUN pip  install edward
RUN pip install daft
RUN pip install pymc3
RUN pip install pystan

# Python packages for data science
RUN pip install toolz
RUN pip install funcy
RUN pip install dash
RUN pip install dash-html-components
RUN pip install dash-core-components
RUN pip install plotly
RUN pip install gensim
RUN pip install scrapy
RUN pip install spacy
RUN pip install sh
RUN pip install Faker
RUN pip install pandas_datareader
RUN pip install feather-format
# RUN pip install h5py
RUN pip install arrow
RUN pip install ipython-sql
# RUN pip install sqlalchemy
RUN pip install biopython
# RUN pip install pytest
# RUN pip install feather
# RUN pip instal cppimport
RUN pip install imageio
RUN pip install pandas_datareader
RUN pip install multiprocess
RUN pip install sparsesvd

# man pages
RUN apt-get update && \
    apt-get install -y \
    manpages \
    manpages-dev \
    man

# Unix utilites
RUN apt-get update && \
    apt-get install -y \
    less \
    bc 

#--- start spark support
RUN apt-get update && \
    apt-get install -y  \
    krb5-multidev \
    pkg-config && apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# install the dev version of the spark magic 
#USER root
#RUN cd / ; \
#   git clone https://github.com/jupyter-incubator/sparkmagic.git
#RUN cd /sparkmagic ; \
#   pip install -e hdijupyterutils; \ 
#   pip install -e autovizwidget ; \
#   pip install -e sparkmagic
#
#RUN jupyter nbextension enable --py --sys-prefix widgetsnbextension 
#RUN cd /sparkmagic/sparkmagic ; \
#    jupyter-kernelspec install sparkmagic/kernels/pysparkkernel \

# skip the Spark and SparkR kernel's for now - pyspark is enough for this course
#RUN cd /sparkmagic/sparkmagic ; \
#    jupyter-kernelspec install sparkmagic/kernels/sparkkernel 
#RUN cd /sparkmagic/sparkmagic ; \
#    jupyter-kernelspec install sparkmagic/kernels/sparkrkernel

##### conda version of the spark magic is not that good, but in case someone cares:
####RUN pip install  sparkmagic
####RUN cd /opt/conda/lib/python3.5/site-packages ; \
####    jupyter-kernelspec install sparkmagic/kernels/sparkkernel \
####     jupyter-kernelspec install sparkmagic/kernels/pysparkkernel \
####     jupyter-kernelspec install sparkmagic/kernels/pyspark3kernel \
####     jupyter-kernelspec install sparkmagic/kernels/sparkrkernel

#--- end spark support


#------end Duke-specific additions ---

# Switch back to jovyan to avoid accidental container runs as root
USER jovyan

