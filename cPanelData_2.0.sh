#!/bin/bash
#Author:Mohamed Najaaf
#Script to fetch a domain's website files, Databases and all available logs from a cPanel server.
clear
m=0;
em=0;
web=0;
red=$(tput setaf 1);
gre=$(tput setaf 2);
yel=$(tput setaf 3);
vio=$(tput setaf 5);
cya=$(tput setaf 6);
res=$(tput sgr 0);
hostname=`hostname -i`

data()
{
clear
echo -e "\n $cya SSH Key based Authentication Successful!!! \n$res"
echo -e "\n$gre Enter the domain name for which the Website data, Databases and emails are required:$res\n";
read dom;
user=`/scripts/whoowns $dom`;
if [ $? -ne  0 ];
then
        echo -e "\n$red This is not an active domain!Please enter the domain name that is hosted on this server.$res\n";
        rm -f ../cPanelData_2.0.sh*
	exit;
else
        home=`grep $dom /etc/userdatadomains | tail -1 | awk '{print $2}' | cut -d'=' -f9 | cut -d '/' -f2`;
	maindom=`grep $dom /etc/trueuserdomains`;
	if [ $? -ne  0 ];then
		path=`grep $dom /etc/userdatadomains | tail -1 | awk '{print $2}' | cut -d'=' -f9`;
	else
		path=`grep $dom /etc/userdatadomains | grep main | awk '{print $2}' | cut -d'=' -f9`;
	fi
        echo -e "\n$cya Calculating size of user's data... $res\n";
        echo -e "\n$vio++++++++++++++++++DATABASE++++++++++++++++++$res\n"
        du -sh /var/lib/mysql/$user* 2>/dev/null
        if [ $? -ne 0 ];
        then
                echo -e "$red Looks like there are no databases available!$res"
                m=1;
        fi
        echo -e "\n$vio+++++++++++++++++++EMAIL++++++++++++++++++++$res\n"
        du -sh /$home/$user/mail/$dom 2>/dev/null
        if [ $? -ne 0 ];
        then
                echo -e "$red Looks like there are no emails available!$res"
                em=1;
        fi
        echo -e "\n$vio+++++++++++++++WEBSITE+CONTENT++++++++++++++$res\n"
        du -sh $path 2>/dev/null 
        if [ $? -ne 0 ];
        then
                echo -e "$red Looks like there are no website data available!$res"
                web=1;
        fi
        echo -e "\n$vio++++++++++++++++++++++++++++++++++++++++++++\n$res"
fi
if [[ $m = 1 ]] && [[ $em = 1 ]] && [[ $web = 1 ]];then
	exit;
fi
echo -e "$gre\nWhich data do you require?\n++++++++++++++++++++\n\n1. Website files.\n2. Email contents.\n3. Databases.\n4. All of the above.\n5. Exit\n\n++++++++++++++++++++\n\nEnter your Choice:  $res" 
read choice;
case "$choice" in 
  1 ) m=1;em=1
      tarr;;
  2 ) m=1;web=1;
      tarr ;;
  3 ) em=1;web=1;
      tarr ;;
  4 ) tarr ;;
  5 ) rm -f cPanelData_2.0.sh* 
      exit ;;
  * ) rm -f cPanelData_2.0.sh* 
      echo -e "\n $red Invalid option selected! $res \n";;
esac

}

tarr()

{
	clear
	if [[ $m = 1 ]] && [[ $em = 1 ]] && [[ $web = 1 ]];then
		echo -e "\n$red Requested data is not available!\n$res"
	        rm -f cPanelData_2.0.sh* 
		exit;
	fi
	mkdir /root/abuse_data_$dom;cd /root/abuse_data_$dom;
	echo -e "\n$red Roger that! $res\n"
	if [[ $m -ne 1 ]];then
		echo -e "\n$cya Taking Database dumps...$res\n";
		mkdir mysql;
		cd /var/lib/mysql/
		for i in `ls   | grep $user`;do mysqldump $i > $i.sql; echo -e "\n Dump taken for $yel$i$res\n"; mv $i.sql /root/abuse_data_$dom/mysql/  ;done 2>/dev/null
	        cd /root/abuse_data_$dom/
	fi
	if [[ $em -ne 1 ]];then
		 echo -e "\n$cya Copying Mails...\n"
		 cp -pr /$home/$user/mail/$dom .
	fi
	if [[ $web -ne 1 ]]; then
	         echo -e "\n Copying Webdata...\n"
	         cp -pr $path .
	fi
	echo -e "\n Tarring all available data...$res\n"
	tar -cvzf ../abuse_data_$dom.tar.gz * &>/dev/null
	cd ..
	rm -rf abuse_data_$dom;
	echo -e "$vio\n Tar File Size:\n"
	du -sh abuse_data_$dom.tar.gz;
	echo -e "$cya\n Transferring to Backup Server...$res\n"
	rsync -avz -e "ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null" --progress abuse_data_$dom.tar.gz root@xxx.x.x.xxx:/usr/local/apache/htdocs/ 2>/dev/null
	echo -e "\n++++++++++++++++++++++++++++++++++++++++++++\n\nDownloadable link:$gre http://xxx.x.x.xxx/abuse_data_$dom.tar.gz$res\n\n++++++++++++++++++++++++++++++++++++++++++++\n";
	rm -f abuse.sh*
	rm -rf abuse_data_$dom.tar.gz
}		
		
logs()
        {
		clear
		echo -e "\n $cya SSH Key based Authentication Successful!!! \n$res"
                echo -e "\n$gre Enter the domain name for which the logs are required:$res"
                read dom1;
                echo -e "\n$gre Enter the main domain name:$res"
                read dom;
                user=`grep $dom /var/cpanel/accounting.log |tail -1 |  rev |cut -d: -f1 | rev`
		if [[ -z $user  ]];then
                    #No record for this domain in the accounting log! Could be because main domain was changed!"
                     user=`/scripts/whoowns $dom`
                     if [[ -z $user  ]];then
                        echo -e "\n$red No records found for the domain in this server.$res\n"
                        rm -f ../abuse.sh* 
                        exit
                     else
			final
                        exit
                     fi
                else
			final
                        exit
                fi

        }
final()
        {
		clear
                echo -e "\nUsername of the domain is:$(tput sgr 3) $user $res \n"
                string=`grep $user /var/cpanel/accounting.log | tail -1`
                home=`grep $dom /etc/userdatadomains | tail -1 | awk '{print $2}' | cut -d'=' -f9 | cut -d '/' -f2`;
                if [[ $string == *REMOVE* ]];then
                        date=`grep $user /var/cpanel/accounting.log | tail -1 | awk '{print $2" "$3" "$5}' | cut -d: -f1`
                        echo -e "\n$red This cPanel account was removed on$yel $date! $res\n"
                else
                        echo -e "\n$cya This is an active cPanel account! $res\n"
                fi
                echo -e "\nFinding SSH logs...\n"
                touch SSH_logs.txt
                if [ -f /$home/$user/.bash_history ];
                then
                        cat /$home/$user/.bash_history >> SSH_logs.txt 2>/dev/null
                fi
                echo -e "\nSSH logs saved in$yel SSH_logs.txt $res \n"
                echo -e "\nFinding FTP Logs..."
                zgrep $user /var/log/messages* | egrep -v '<Office-IP>' >> FTP_logs.txt 2>/dev/null
                echo -e "\nFTP logs saved in$yel FTP_logs.txt $res \n"
                echo -e "\nFinding dom logs..."
                egrep "$user|$dom1" /usr/local/apache/domlogs/$user/* | egrep -v '<Office-IP>'  >> dom_logs.txt 2>/dev/null
                zgrep $dom1 /usr/local/apache/logs/archive/access_log* 2> /dev/null | egrep -v '<Office-IP>'  >> dom_logs.txt 2>/dev/null
                echo -e "\nDomain logs saved in$yel dom_logs.txt $res \n"
                echo -e "\nFinding cPanel access log..."
                grep $user /usr/local/cpanel/logs/access_log | egrep -v '<Office-IP>'  >> cPanel_access_log.txt 2>/dev/null
                echo -e "\n$cya Excavating logs from archives...This may take a while...Hold on!$res \n"
                zgrep $user /usr/local/cpanel/logs/archive/access_log* | egrep -v '<Office-IP>'  >> cPanel_access_log.txt 2>/dev/null
                echo -e "cPanel logs saved in$yel cPanel_access_logs.txt $res \n"
                echo -e "\nFinding Exim Logs... \n"
                zgrep $dom1 /var/log/exim_mainlog* >> exim_logs.txt 2>/dev/null
                echo -e "\nExim logs saved in $yel exim_logs.txt $res \n"
                echo -e "\nFinding MailBox Logs... \n"
                zgrep $dom1 /var/log/maillog* | egrep -v '<Office-IP>'  >> mailbox_logs.txt 2>/dev/null
                echo -e "\nMailbox logs saved in $yel mailbox_logs.txt $res \n"
                echo -e "\n$gre Log fetching completed! $res \n"
                for i in `ls *.txt`; do if [ -s $i ];then
                        echo -e "\n$yel$i$res -->  $gre Logs found :) $res"
                else
                        echo -e "\n$yel$i$res -->  $red No logs :( $res"
                        rm -f $i 
                fi;
                done
                echo -e "\n$cya Compressing and zipping the available logs...$res "
                zip $dom1.zip *.txt &> /dev/null
                echo -e "\n$cya Logs zipped into $dom1.zip. $res \n"
                du -sh $dom1.zip
	        echo -e "\n$cya Removing log files created from this server... $res \n"
                rm -f *.txt 
		echo -e "$cya\n Transferring to Backup Server...$res\n"
		rsync -avz -e "ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null" --progress $dom1.zip root@xxx.x.x.xxx:/usr/local/apache/htdocs/ 2>/dev/null
		echo -e "\n++++++++++++++++++++++++++++++++++++++++++++\n\nDownloadable link:$gre http://xxx.x.x.xxx/$dom1.zip\n\n$res++++++++++++++++++++++++++++++++++++++++++++\n";
		rm -f ../cPanelData_2.0.sh*
		rm -rf $dom1.zip
        }

keytrans()
 {
echo -e "\n\n $red Copying Public Key to Backup Server...if prompted, please enter the Backup server root password.\n$res"
if [ -f /root/.ssh/id_rsa.pub ]
then
	ssh-copy-id -i /root/.ssh/id_rsa.pub root@xxx.x.x.xxx &>/dev/null
else
	echo | ssh-keygen -P '' &>/dev/null
	ssh-copy-id -i /root/.ssh/id_rsa.pub root@xxx.x.x.xxx &>/dev/null
fi


}

if [ -d "abuse-hps" ];then

       cd abuse-hps
else
       mkdir abuse-hps 
       cd abuse-hps
fi
echo -e "\n$gre******************Script-for-Abuse-Team******************\n\n1. Logs.\n2. Domain Data (Website files, Databases, Email content).\n3. Exit.\n\n*********************************************************$res\n"
        read -p "$red Enter your choice:$res" choice
        case "$choice" in 
                1 ) keytrans
			logs ;;
                2 ) keytrans
			data ;;
                3 ) rm -f abuse.sh*
		    exit ;;
                * ) rm -f abuse.sh*
		    echo -e "$red\nInvalid Option!\n$res";; 
        esac

rm -f ../cPanelData_2.0.sh* &>/dev/null
