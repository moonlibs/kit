.PHONY := all test

test:
	export LUACOV_ENABLE=true
	prove t/*.lua