.ONESHELL:
SHELL=/bin/bash
ENV_NAME=hloc
UNAME := $(shell uname)
JUPYTER_FILE='~/.jupyter/jupyter_notebook_config.py'
CONDA_ACTIVATE=source $$(conda info --base)/etc/profile.d/conda.sh ; conda activate ; conda activate
.PHONY: cmake

install: update-conda pip install-jupyter

update-conda:
	conda env update -f environment.yml

pip:
	$(CONDA_ACTIVATE) $(ENV_NAME)
	python -m pip install e .

install-jupyter:
	$(CONDA_ACTIVATE) $(ENV_NAME)
	jupyter notebook --generate-config
	echo "c = get_config()" >> ~/.jupyter/jupyter_notebook_config.py
	echo "c.NotebookApp.ip = '*'" >> ~/.jupyter/jupyter_notebook_config.py
	echo "c.NotebookApp.open_browser = False" >> ~/.jupyter/jupyter_notebook_config.py
	echo "c.NotebookApp.port = 5000" >> ~/.jupyter/jupyter_notebook_config.py

jupyter:
	jupyter notebook --no-browser --port 5000

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
