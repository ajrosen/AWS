APP=mkstack
VERSION=1.1.3

all: uninstall gem install doc
user-all: uninstall gem user-install

gem:
	gem build $(APP).gemspec -q

install:
	gem install $(APP)-$(VERSION).gem

user-install:
	gem install --user-install $(APP)-$(VERSION).gem

uninstall:
	-gem uninstall $(APP) -ax

doc:
	# Replace U+2010 with ASCII 45
	ri -f markdown -T MkStack | sed 's/‐/-/g' > README.md
