.ONESHELL:
SHELL=/bin/bash
ENV_NAME=hloc
UNAME := $(shell uname)
CONDA_ACTIVATE=source $$(conda info --base)/etc/profile.d/conda.sh ; conda activate ; conda activate
.PHONY: cmake

install: update-conda pip

update-conda:
	conda env update -f environment.yml

pip:
	$(CONDA_ACTIVATE) $(ENV_NAME)
	python -m pip install e .
cmake:
	sudo apt remove --purge --auto-remove cmake
	sudo apt update && \
	  sudo apt install -y software-properties-common lsb-release && \
	  sudo apt clean all
	wget -O - https://apt.kitware.com/keys/kitware-archive-latest.asc 2>/dev/null | gpg --dearmor - | \
	  sudo tee /etc/apt/trusted.gpg.d/kitware.gpg >/dev/null
	sudo apt-add-repository "deb https://apt.kitware.com/ubuntu/ $$(lsb_release -cs) main"
	sudo apt update
	sudo apt install kitware-archive-keyring
	sudo rm /etc/apt/trusted.gpg.d/kitware.gpg
	sudo apt update
	sudo apt install cmake
