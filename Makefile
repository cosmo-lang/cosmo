EXECUTABLE = "bin/cosmo"

insufficient_perms:
	echo "Error: You must run 'make install' with elevated privileges to install Cosmo." \

install_action:
	echo "Installing Cosmo as $(SUDO_USER)"
	shards build --release
	cp $(EXECUTABLE) /usr/local/bin/
	make test
	echo "Successfully installed Cosmo!"

install:
	ifeq '$(findstring ;,$(PATH))' ';'
		make install_action
	else
		@if [ $$(id -u) -eq 0 ]; then \
			make install_action;
		else ( \
			make insufficient_perms \
			echo "You are on Linux. Run 'sudo make install'." \
		) fi
	endif


test:
	crystal spec -v --fail-fast

publish:
	crystal spec --fail-fast
	crystal docs --project-name=Cosmo -o docs
	git add .
	git commit -m "docs: generate (auto)"
	git push -u
