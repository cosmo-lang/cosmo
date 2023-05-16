EXECUTABLE = "bin/cosmo"

install:
	shards build --release
	cp $(EXECUTABLE) /usr/local/bin/
	make test
	echo "Successfully installed Cosmo!"

test:
	crystal spec -v --fail-fast

publish:
	crystal spec --fail-fast
	crystal docs --project-name=Cosmo -o docs
	git add .
	git commit -m "docs: generate (auto)"
	git push -u
