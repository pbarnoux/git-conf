Git Configuration
=================
Git configuration helper. Contains hooks, useful configuration options set by
a script and default files.

Usage
-----
    git clone https://github.com/pbarnoux/git-conf
	git-conf/autoconf.sh

The script should conform to POSIX standards. It modifies the global
configuration file only after performing a backup if there is an existing file.

The script should not overwrite existing values without asking the user first.

Ensure git commits files with LF EOL
------------------------------------
Dealing with line endings with Git is a subject covered by many blogs and such.
If there was one page to read, it is the [synthesis available on github](https://help.github.com/articles/dealing-with-line-endings/).

This repository provides a default .gitattributes file to use, but you have to
put it in your repositories yourself with the following command:

	cp .gitattributes your-git-project-dir/.

In addition to this file, the script attempts to guess the correct value for
the setting core.autocrlf based on your operating system. This is a safety net
should a git client would not honor the .gitattributes file.

Pre-push hook
-------------
If you do not enjoy seeing your CI job failing after pushing your
contributions, you can rely on the provided pre-push hook.

Provide the command to run your project tests, e.g.:

	git config hooks.prepush.command 'mvn clean install && mvn verify -f it-module/pom.xml -Prun-its -DskipITs=false'

The command runs in the top directory. When unset, the command depends on the
project nature.

#### Maven projects
If a pom.xml is found in the top directory, Maven tests are launched as:

	mvn clean verify

The following options may override the default behavior:

	# Run other goals
	git config hooks.prepush.maven.goals 'package site:site site:stage'
	# Run maven in offline mode
	git config hooks.prepush.maven.offline true

#### Ruby on Rails projects
If a gemfile and a spec directory are found, RoR tests are launched as:

	bundle exec rspec spec/

About diffconflicts
-------------------
Credits for the diffconflicts shell script go to whiteinge and other
contributors. The source material can be found on [his dotfile
repository](https://github.com/whiteinge/dotfiles).
