#!/bin/bash
red=$(tput setaf 1);
gre=$(tput setaf 2);
yel=$(tput setaf 3);
res=$(tput sgr 0);
echo -e "\nEnter the username:";
read user;
home=`grep $user /etc/userdatadomains  | tail -1 | awk '{print $2}' | cut -d'=' -f9 | cut -d '/' -f2`
echo -e "\n $red Finding Files greater than 1 GB...\n";
find /$home/$user/ f -size +1G -exec du -sh {} \; 2>/dev/null
#if [ $? -ne  0 ];
#then
#	echo -e "\nCould not find any files greater than 1GB:(";
#fi
echo -e "\n $gre Searching for zip files...\n";
find /$home/$user/ -iname *.zip -exec du -sh {} \; 2>/dev/null
echo -e "\n $yel Searching for Tar files...\n";
find /$home/$user/ -iname *.gz -exec du -sh {} \; 2>/dev/null
echo "$res";
rm -fv diskaudit.sh
