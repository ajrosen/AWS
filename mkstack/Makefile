APP=mkstack
VERSION=1.3.1

user-all: uninstall gem user-install
system-all: uninstall gem install doc

gem:
	gem build $(APP).gemspec -q

install:
	gem install $(APP)-$(VERSION).gem

user-install:
	gem install --user-install $(APP)-$(VERSION).gem

uninstall:
	-gem uninstall $(APP) -ax

push:
	gem push $(APP)-$(VERSION).gem
	fury push $(APP)-$(VERSION).gem

doc:
	# Replace U+2010 with ASCII 45
	ri -f markdown -T MkStack | sed 's/‐/-/g' > README.md
