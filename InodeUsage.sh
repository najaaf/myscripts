#!/bin/bash/
#Author: Mohamed Najaf
#Script for VPS/DEDI servers detailed inode usage.

red=$(tput setaf 1);
gre=$(tput setaf 2);
yel=$(tput setaf 3);
vio=$(tput setaf 5);
cya=$(tput setaf 6);
res=$(tput sgr 0);

inode()
{
clear
tot=`df -i | egrep 'vda1|sda1' | awk '{print $5}' | cut -d'%' -f1`
echo -e "\nInode usage of the server is at: $red $tot % $res \n" 

echo -e "\n$cya Top Inode consuming Directories under / :\n ----------------------------------------\n" 
find / -xdev -printf '%h\n' | egrep -v 'virtfs|lib|kernels|bin|usr|openssl' | sort | uniq -c | sort -k 1 -n | tail -10 | sort -rn | tee /root/inodeusage.txt


echo -e "\n\n$gre----------\nSUGGESTIONS:\n----------\n"

if [[ `cat /root/inodeusage.txt` == *"session"* || `cat /root/inodeusage.txt` == *"cache"*  ]];then
        echo -e "You can clear the below session/cache files:\n\n----------------------------------------\n`egrep 'session|cache' /root/inodeusage.txt` \n----------------------------------------\n"

fi

if [[ `cat /root/inodeusage.txt | grep -v cpanel` == *"mail"*  ]];then
        echo -e "You can suggest the customer to either remove the below emails or download them to their local machine:\n\n----------------------------------------\n`grep 'mail' /root/inodeusage.txt` \n----------------------------------------\n"

fi

if [[ `cat /root/inodeusage.txt` == *"trash"*  ]];then
        echo -e "You can clear the below trash files:\n\n----------------------------------------\n`grep trash /root/inodeusage.txt` \n----------------------------------------\n"

fi

echo -e "$red IMP Note: Before removing any files under a user, always confirm with the customer first.\n\n$res "
}

if [ `whoami` == "root" ];then
        inode;
else
        echo -e "$red Run the script as root user!!! $res";
fi

rm -f inodeusage.sh*
rm -f /root/inodeusage.txt
