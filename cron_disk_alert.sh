#!/bin/bash/
#Author: Mohamed Najaf
#Disk Usage Alert - VPS/DEDI

disk_alert()
{
	echo -e "\nHostname: `hostname`\nServer IP: `hostname -i`\n" > /root/diskusagedata.txt	

	echo -e "\nDisk usage of the server is at: $tot % \n" >> /root/diskusagedata.txt

	echo -e "\nTop Disk consuming Directories under / :\n----------------------------------------\n" >> /root/diskusagedata.txt
	du -sh /* |  egrep -v 'virtfs|usr|lib|proc|swap|boot|sql' | sort -rh  | head -3 >> /root/diskusagedata.txt

	echo -e "\nList of Files consuming high disk space:\n----------------------------------------\n" >> /root/diskusagedata.txt
	find / -type f -exec du -Sh {} + | egrep -v 'virtfs|usr|lib|swap|boot|sql' | sort -rh | head -n 5 >> /root/diskusagedata.txt

	echo -e "\nList of Directories consuming high disk space:\n---------------------------------------------\n" >> /root/diskusagedata.txt
	find / -mindepth 2 -type d -exec du -Sh {} + | egrep -v 'virtfs|usr|lib|swap|boot|sql' | sort -rh | uniq | head -n 5 >> /root/diskusagedata.txt

	mail -s "Disk_Usage_Warning-`hostname`-`hostname -i`" apac-retail-hps@endurance.com < /root/diskusagedata.txt
	rm -f /root/diskusagedata.txt
	rm -f cron_disk_alert.sh*
}

tot=`df -h | egrep 'vda1|sda1' | awk '{print $5}' | cut -d'%' -f1`
if [[ $tot -ge "95"  ]];then
	disk_alert;
else
	exit;
fi
