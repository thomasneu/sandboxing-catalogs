
pyenv install 3.11.13
pyenv virtualenv 3.11.13 pyice-env 
pyenv activate pyice-env
pip install "pyiceberg[rest]" pyarrow pandas
