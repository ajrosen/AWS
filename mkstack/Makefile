APP=mkstack
VERSION=1.1.1

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
	ri -T -f markdown MkStack > README.md
