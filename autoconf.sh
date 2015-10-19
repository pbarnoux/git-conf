
# This script should conform to POSIX
# It runs in the current shell

# Matches the given string against a pattern built from the given base.
# The base pattern is surrounded with '*' to expand matches to any characters.
# $1: the base pattern
# $2: the value to match
# returns 0 if the value matches, 1 otherwise
match_glob() { case "$2" in *$1*) return 0;; *) return 1;; esac ; }

# Matches the given string against a pattern built from the given base while
# discarding case checks.
# The base pattern is surrounded with '*' to expand matches to any characters.
# $1: the base pattern, there is no check that it is lower case
# $2: the value to match
# returns 0 if the value matches, 1 otherwise
imatch_glob()
{
	lower=$(printf "%s\n" "$2" | tr '[:upper:]' '[:lower:]')
	match_glob $1 "$lower"
}

# Ask the user if overwritting the existing value is desired or not
# $1: the setting key
# $2: the current value
# $3: the new value
# returns 0 if overwrite is desired, 125 if it is meaningless, 1 otherwise
overwrite()
{
	retval=1
	if [ -f "$2" -a -f "$3" ]; then
		if diff "$2" "$3" >/dev/null; then
			# Do not call git config to set an existing value; skip this item.
			retval=125
		else
			printf "Overwrite '%s' current file '%s' with '%s'\n" "$1" "$2" "$3"
			printf "y / n / d (diff)? "
			while IFS= read -r answer; do
				if imatch_glob '[yn]' "$answer"; then
					imatch_glob 'y' "$answer" && retval=0
					imatch_glob 'n' "$answer" && retval=1
					break
				elif imatch_glob 'd' "$answer"; then
					diff "$2" "$3" | less
					printf "y / n / d (diff)? "
				else
					printf "y / n / d (diff)? "
				fi
			done
		fi
	elif [ "$2" == "$3" ]; then
		# Do not call git config to set an existing value; skip this item.
		retval=125
	else
		printf "Overwrite '%s' current value '%s' with '%s'?\n" "$1" "$2" "$3"
		printf "y / n? "
		while IFS= read -r answer; do
			if imatch_glob '[yn]' "$answer"; then
				imatch_glob 'y' "$answer" && retval=0
				imatch_glob 'n' "$answer" && retval=1
				break
			else
				printf "y / n? "
			fi
		done
	fi
	return $retval
}

# Configure git settings
# $1: the setting to set
# $2: the current value
# $3: the new value
configure()
{
	config=1
	output="[ SKIPPED: keeping existing value ]"
	old_value=$(git config --global --get "$1")

	if [ "$old_value" = "" ]; then
		config=0
	else
		overwrite "$1" "$old_value" "$2"
		config=$?
	fi

	if [ $config -eq 0 ]; then
		git config --global "$1" "$2" && output="[ OK ]"
	elif [ $config -eq 125 ]; then
		output="[ SKIPPED: already set ]"
	fi
	printf "%-40s%10s\n" "$1" "$output"
}

# Request the user personal data if necessary to set them
# $1: the identity key to set (user.name or user.email)
# $2: the prompt to display if necessary
set_identity()
{
	personal_data=$(git config --get --global "$1")

	if [ -z "$personal_data" ]; then
		printf "Enter your %s: " "$2"
		IFS= read -r personal_data
		configure "$1" "$personal_data"
	else
		printf "%-40s%10s\n" "$1" "[ SKIPPED: already set ]"
	fi
}

# Get the full path to this directory
dest_dir=$(pwd)
if [ "$0" != "./autoconf.sh" ]; then
	current_dir=$(pwd)
	dest_dir=$(printf "%s" "$0" | sed -e 's@autoconf.sh@@')
	cd "$dest_dir"
	dest_dir=$(pwd)
	cd "$current_dir"
fi

# Backup existing gitconfig file if necessary
global_file="$HOME"/.gitconfig
if [ -f "$global_file" ]; then
	backup="$global_file"_$(date "+%y%m%d_%H%M%S")
	mv "$global_file" "$backup"
	cp "$backup" "$global_file"
fi

# Set identity if necessary
set_identity "user.name" "name (e.g: John Doe)"
set_identity "user.email" "email (e.g: john.doe@example.com)"

# Configure (or reconfigure) some git global settings
# Aliases for git log (condensed log and two kinds of graph)
configure "alias.lg" "log --format=format:'%C(bold blue)%h%C(reset) - %C(bold green)%ai%C(reset) %C(white)%s%C(reset) - %C(magenta)%an%C(reset)'"
configure "alias.graph-simple" "log --graph --abbrev-commit --decorate --date=relative --format=format:'%C(bold blue)%h%C(reset) - %C(bold green)(%ar)%C(reset) %C(white)%s%C(reset) - %C(magenta)%an%C(reset)%C(bold yellow)%d%C(reset)' --all"
configure "alias.graph" "log --graph --abbrev-commit --decorate --format=format:'%C(bold blue)%h%C(reset) - %C(bold green)%ai (%ar)%C(reset)%C(bold magenta)%d%C(reset)%n''          %C(white)%s%C(reset) - %C(white)%an%C(reset)' --all"
# Enforce default colors in terminal
configure "color.branch" "auto"
configure "color.diff" "auto"
configure "color.interactive" "auto"
configure "color.status" "auto"
# EOL policy on commit
if imatch_glob 'linux' "$OSTYPE"; then
	configure "core.autocrlf" "input"
elif imatch_glob 'win' "$OS"; then
	configure "core.autocrlf" "true"
else
	printf "%-40s%10s\n" "core.autocrlf" "[ SKIPPED: Unable to determine OS ]"
fi
# global ignore file
configure "core.excludesfile" "$dest_dir"/.gitignore_global
# Declare this repository as a template to enable hooks
configure "init.templatedir" "$dest_dir"
# Conflict resolution
configure "merge.conflictstyle" "diff3"
if which gvim >/dev/null; then
	configure "merge.tool" "diffconflicts"
	configure "mergetool.diffconflicts.cmd" "$dest_dir"'/diffconflicts vim $BASE $LOCAL $REMOTE $MERGED'
	configure "mergetool.diffconflicts.trustExitCode" "true"
	configure "mergetool.diffconflicts.keepBackup" "false"
fi
# Enable the Reuse Recorded Resolution option
configure "rerere.enabled" "true"

