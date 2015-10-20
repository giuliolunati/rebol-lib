function check_install { # to-path file perm
 TO=$1/$2
	FROM=/sdcard/$2
	PERM=$3
	if [ ! -f $TO ]
	then cp $FROM $TO; chmod $PERM $TO
	fi
	[[ -f $TO ]] || echo "Put $2 in /sdcard !!"
}
export HOME=/data/data/com.googlecode.android_scripting/files
### check/install/launch
if [ -z $ENV ]
then 
	# check/create dirs
	cd ~/..
	[[ -d files ]] || mkdir files
	cd files
	[[ -d tmp ]] || mkdir tmp
	export TMPDIR=~/tmp
	[[ -d bin ]] || mkdir bin
	[[ -d lib ]] || mkdir lib
	[[ -d lib/rebol3 ]] || mkdir lib/rebol3
	# check_install rebol3 executable
	check_install ~/bin rebol3 755
	# check_install sl4a module
	check_install ~/lib/rebol3 sl4a.reb 644
	# check_install altjson module
	check_install ~/lib/rebol3 altjson.reb 644
	# check_install rebol.r config file
	if [ ! -f ~/bin/rebol.r ]
	then cat > ~/bin/rebol.r <<EOF
insert system/options/module-paths join to file! get-env 'HOME %/lib/rebol3/
import 'sl4a
EOF
	fi
	# launch environment
	export ENV=/sdcard/sl4a/scripts/rebol3.sh
	exec /system/bin/sh
fi
### init
export PS1=$PWD' $'$'\n'
export PATH=~/bin:$PATH
export TMPDIR=~/tmp
alias rebol3='~/bin/rebol3 '
alias r3='rebol3 '

r3

