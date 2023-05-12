EXECUTABLE = "bin/cosmo"

install:
	shards build --release
	cp $(EXECUTABLE) /usr/local/bin/
	make test
	echo "Successfully installed Cosmo!"

test:
	crystal spec -v
