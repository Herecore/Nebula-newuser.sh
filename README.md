# Nebula-newuser.sh
This script simplifies the creation of user config files for nebula. You only need to provide a template config file, user name and the ID, and this script will create an export-ready config file for user in their named directory

Syntax: 
`newclient.sh [-n|i|h]`
- `-n - Name of the user`
- `-i - ID of the user. It will be used to pick an IP address that will be used for this client. For example, if your ID is 50, the IP will be 192.168.100.**50**/24`
- `-h - Displays help message`
