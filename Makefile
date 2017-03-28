setup:
	@rm -rf vendor
	@mkdir -p vendor
	git clone --depth 1 git://github.com/sstephenson/bats.git     vendor/bats
	git clone --depth 1 git://github.com/ztombol/bats-assert.git  vendor/bats-assert
	git clone --depth 1 -b 7-fix-arguments-with-asterisks git://github.com/tommarshall/bats-mock.git vendor/bats-mock
	git clone --depth 1 git://github.com/ztombol/bats-support.git vendor/bats-support

test:
	vendor/bats/bin/bats test

.PHONY: setup test
