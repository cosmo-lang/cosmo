EXECUTABLE = "bin/cosmo"

install:
	shards build --release
	cp $(EXECUTABLE) /usr/local/bin/
	make test
	echo "Successfully installed Cosmo!"

test:
	crystal spec -v

publish:
	shards build --release
	make test
	crystal docs --project-name=Cosmo -o docs
	git push -u
