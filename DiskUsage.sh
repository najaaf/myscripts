#!/bin/bash/
#Author: Mohamed Najaaf
#Script for VPS/DEDI servers detailed disk usage.


red=$(tput setaf 1);
gre=$(tput setaf 2);
yel=$(tput setaf 3);
vio=$(tput setaf 5);
cya=$(tput setaf 6);
res=$(tput sgr 0);


disk()
{
clear
tot=`df -h | egrep 'vda1|sda1' | awk '{print $5}' | cut -d'%' -f1`
echo -e "\nDisk usage of the server is at: $red $tot % $res \n" 
#Clearing some logs initially so that the script runs without any errors in case the disk usage is already at 100%.
> /var/log/btmp
> /var/log/secure
echo -e "\n$cya Top Disk consuming Directories under / :\n ----------------------------------------\n" 
find / -maxdepth 1 -mindepth 1 -type d -exec du -sh {} \; 2>/dev/null | egrep -v 'virtfs|usr|lib|proc|swap|boot|sql'  | sort -rh | head -3

echo -e "\n$gre List of Files consuming high disk space:\n ----------------------------------------\n" 
find / -type f -exec du -Sh {} + 2>/dev/null | egrep -v 'virtfs|usr|lib|swap|boot|sql' | sort -rh | head -n 5 | tee /root/diskusagedata.txt

echo -e "\n$vio List of Directories consuming high disk space:\n ---------------------------------------------\n"
find / -mindepth 2 -type d -exec du -Sh {} + 2>/dev/null | egrep -v 'virtfs|usr|lib|swap|boot|sql' | sort -rh | uniq | head -n 5 | tee /root/diskusage.txt


echo -e "\n\n$yel----------\nSUGGESTIONS:\n----------\n"

if [[ `cat /root/diskusagedata.txt` == *"backup"* || `cat /root/diskusagedata.txt` == *".tar"* || `cat /root/diskusagedata.txt` == *".zip"* ]];then
	echo -e " You can remove the below backup files after confirming with the customer:\n\n----------------------------------------\n`egrep 'tar|zip|gz|backup' /root/diskusagedata.txt | head -5` \n----------------------------------------\n $res"
fi

if [[ `cat /root/diskusagedata.txt` == *"log"*  ]];then
	echo -e "$yel You can clear the below log files:\n\n----------------------------------------\n`grep 'log' /root/diskusagedata.txt | head -3` \n----------------------------------------\n $res "
fi

if [[ `cat /root/diskusage.txt | grep -v cpanel` == *"mail"*  ]];then
        echo -e "$yel You can suggest the customer to either remove the below emails or download them to their local machine:\n\n----------------------------------------\n`grep 'mail' /root/diskusage.txt | head -3` \n----------------------------------------\n$res "

fi
echo -e "$red \n Important Note: \n\n^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ \n\n Please do not delete any log files directly as it may be required for the proper running of services in the server.\n Instead, you can clear/trim/truncate the logs. Please refer: \n\n https://computingforgeeks.com/how-to-empty-truncate-log-files-in-linux/ \n https://www.cyberciti.biz/faq/remove-log-files-in-linux-unix-bsd/ \n\n^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^\n $res"
}

if [ `whoami` == "root" ];then
        disk;
else
        echo -e "$red Run the script as root user!!! $res";
fi

rm -f diskusage.sh*
rm -f /root/diskusagedata.txt
rm -f /root/diskusage.txt
