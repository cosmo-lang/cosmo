EXECUTABLE = "bin/cosmo"

# This only works on Linux (and OSX?)
install:
	echo "Installing Cosmo as $(SUDO_USER)"
	shards build --release
	rm -rf /usr/bin/$(EXECUTABLE)
	cp $(EXECUTABLE) /usr/bin/
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
