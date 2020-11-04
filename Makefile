python_files = $(shell find modules -type f -name "*.py" -printf "%h/*.py\n" | sort -u)

all: tidy diagram.py

tidy:
	terraform fmt -recursive
	isort $(python_files)
	black $(python_files)
	flake8 --ignore=E501 $(python_files)
	@echo
	@echo "OK"

diagram.png: diagram.py
	python diagram.py
