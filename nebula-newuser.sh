#!/bin/sh

# Nebula-newuser.sh, made by Herecore
# This script simplifies the creation of user config files for nebula. You only
# need to provide a template config file, user name and the ID, and this script
# will create an export-ready config file for user in their named directory

################################################################################
################################## License #####################################
################################################################################

# This program is free software: you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free Software
# Foundation, either version 3 of the License, or (at your option) any later
# version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with
# this program. If not, see <https://www.gnu.org/licenses/>.


################################################################################
#################################### Help ######################################
################################################################################

Help()
{
	# Display help message
	echo
	echo "This little script creates new nebula user config file with provided 
	name and ID"
	echo
	echo "Syntax: newclient.sh [-n|i|h]"
	echo "Options:"
	echo "-n	Name of the user"
	echo "-i	ID of the user. It will be used to create an IP "
	echo "	address, i.e. \"192.168.100.*ID*/24\""
	echo "-h	Prints help"
}

################################################################################
################################### Flags ######################################
################################################################################

while getopts "hn:i:" flag; do
	case "${flag}" in
		n) NAME=${OPTARG};;
		i) ID=${OPTARG};;
		h) # Display help
			Help
			exit;;
		?) # Wrong flag
			echo "Wrong flag specified"
			echo
			Help
			exit 1
	esac
done

################################################################################
################################ Main Program ##################################
################################################################################

# Check if variables were entered at all
if [[ -z $NAME || -z $ID ]]; then
	echo "Name and ID flags were not provided. Aborting..."
	exit 1
fi

# Check if ID is in IP range
if [[ $ID -lt 3 || $ID -gt 254 ]]; then
	echo "ID must be in 3 < ID < 254 range. Aborting..."
	exit 1
fi

# Does the user already exist?
if [[  -d "./$NAME"  ]]; then
	echo "Directory $NAME already exists. Aborting..."
	exit 1
fi

# Is the template file provided?
if ! [[  -f "user-config-template.yml"  ]]; then
	echo "user-config-template.yml file should be provided"
fi

IP="192.168.1."$ID"/24"

# Create the keys and certificates
if [[  -f "ca.crt" && "ca.key"  ]]; then
	nebula-cert sign -name $NAME -ip $IP
elif [[  -f "./ca/ca.crt" && "./ca/ca.key" ]]; then
	cd "ca"
	nebula-cert sign -name $NAME -ip $IP
	mv $NAME".crt" ".."
	mv $NAME".key" ".."
	cd ".."
elif [[ -f "./CA/ca.crt" && "./CA/ca.key"  ]]; then
	cd "CA"
	nebula-cert sign -name $NAME -ip $IP
	mv $NAME".crt" ".."
	mv $NAME".key" ".."
	cd ".."
else
	echo "No CA files found. They should be in either "./CA", "./ca" or in
	$(pwd) directories. Aborting..."
	echo "Refer to nebula documentation on how to create them"
	exit 1
fi

# ...And move them to named directory, as well as the config sample file
mkdir $NAME
mv $NAME".crt" ./$NAME/
mv $NAME".key" ./$NAME/
cp user-config-template.yml ./$NAME/config-$NAME.yml
cd $NAME

# Write crt and key to newly created config file
awk 'NR==FNR { a[n++]=$0; next }
/CHANGE_CRT/ { for (i=0;i<n;++i) print "    " a[i]; next }
1' $NAME".crt" config-$NAME.yml > tmp && mv tmp config-$NAME.yml

awk 'NR==FNR { a[n++]=$0; next }
/CHANGE_KEY/ { for (i=0;i<n;++i) print "    " a[i]; next }
1' $NAME".key" config-$NAME.yml > tmp && mv tmp config-$NAME.yml

echo "Config file is ready for export"
