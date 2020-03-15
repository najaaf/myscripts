#!/bin/bash
#Author:Mohamed Najaaf
#Logs for abuse team
clear
passwd="xxxxxxxxxx"
logs()
        {
                echo -e "\n$(tput setaf 2)Enter the domain name for which the logs are required:$(tput sgr 0)"
                read dom1;
                echo -e "\n$(tput setaf 2)Enter the main domain name:$(tput sgr 0)"
                read dom;
                user=`grep $dom /var/cpanel/accounting.log | grep CREATE | awk '{print $5}' | rev | cut -d: -f1 | rev | tail -1 `
                if [[ -z $user  ]];then
                    #No record for this domain in the accounting log! Could be because main domain was changed!"
                     user=`/scripts/whoowns $dom`
                     if [[ -z $user  ]];then
                        echo -e "\n$(tput setaf 1)No records found for the domain in this server.$(tput sgr 0)\n"
                        rm -rf ../abuse.sh &> /dev/null
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
                echo -e "\nUsername of the domain is:$(tput sgr 3) $user $(tput sgr 0) \n"
                string=`grep $user /var/cpanel/accounting.log | tail -1`
                if [[ $string == *REMOVE* ]];then
                        date=`grep $user /var/cpanel/accounting.log | tail -1 | awk '{print $2" "$3}'`
                        echo -e "\n$(tput setaf 1)This cPanel account was removed on$(tput setaf 3) $date! $(tput sgr 0)\n"
                else
                        echo -e "\n$(tput setaf 6)This is an active cPanel account! $(tput sgr 0)\n"
                fi
                echo -e "\nFinding FTP Logs..."
                zgrep $user /var/log/messages* >> FTP_logs.txt 2>/dev/null
                echo -e "\nFTP logs saved in$(tput setaf 3) FTP_logs.txt $(tput sgr 0) \n"
                echo -e "\nFinding dom logs..."
                egrep "$user|$dom1" /usr/local/apache/domlogs/$user/* >> dom_logs.txt 2>/dev/null
                zgrep $dom1 /usr/local/apache/logs/archive/access_log* >> dom_logs.txt 2>/dev/null
                echo -e "\nDomain logs saved in$(tput setaf 3) dom_logs.txt $(tput sgr 0) \n"
                echo -e "\nFinding cPanel access log..."
                grep $user /usr/local/cpanel/logs/access_log  >> cPanel_access_log.txt 2>/dev/null
                echo -e "\n$(tput setaf 6)Excavating logs from archives...This may take a while...Hold on!$(tput sgr 0) \n"
                zgrep $user /usr/local/cpanel/logs/archive/access_log* >> cPanel_access_log.txt 2>/dev/null
                echo -e "cPanel logs saved in $(tput setaf 3)cPanel_access_logs.txt $(tput sgr 0) \n"
                echo -e "\nFinding Exim Logs... \n"
                zgrep $dom1 /var/log/exim_mainlog* >> exim_logs.txt 2>/dev/null
                echo -e "\nExim logs saved in $(tput setaf 3)exim_logs.txt $(tput sgr 0) \n"
                echo -e "\nFinding MailBox Logs... \n"
                zgrep $dom1 /var/log/maillog* >> mailbox_logs.txt 2>/dev/null
                echo -e "\nMailbox logs saved in $(tput setaf 3)mailbox_logs.txt $(tput sgr 0) \n"
                echo -e "\n$(tput setaf 2)Log fetching completed! $(tput sgr 0) \n"
                #echo -e "\n$(tput setaf 6)Size of Log files:$(tput sgr 0) \n"
                #du -sch *.txt
                for i in `ls *.txt`; do if [ -s $i ];then
                        echo -e "\n$(tput setaf 3)$i$(tput sgr 0) -->  $(tput setaf 2)Logs found :) $(tput sgr 0)"
                else
                        echo -e "\n$(tput setaf 3)$i$(tput sgr 0) -->  $(tput setaf 1)No logs :( $(tput sgr 0)"
                        rm -fv $i &> /dev/null
                fi;
                done
                echo -e "\n$(tput setaf 6)Compressing and zipping the available logs... $(tput sgr 0) "
                zip $user.zip *.txt &> /dev/null
                echo -e "\n$(tput setaf 6)Logs zipped into $user.zip. $(tput sgr 0) \n"
                du -sch $user.zip
                echo -e "\n$(tput setaf 6)Transferring zip file to demomonkey server... $(tput sgr 0)\n"
                curl --insecure --user root:$passwd -T $user.zip sftp://142.4.4.187/usr/local/apache/htdocs/ &> /dev/null
                echo -e "\n$(tput setaf 6)Transfer is Completed!$(tput sgr 0) \n"
                echo -e "\n$(tput setaf 6)Removing log files created from this server... $(tput sgr 0) \n"
                rm -fv *.txt *.zip &> /dev/null
                echo -e "\n-------------\n"
                echo -e "\n$(tput setaf 5)Downloadable Link:        $(tput sgr 2)http://142.4.4.187/$user.zip $(tput sgr 0)"
                echo -e "\n-------------\n"
                rm -rf ../abuse.sh &> /dev/null
        }
 
if [ -d "abuse-hps" ];then
 
        cd abuse-hps
        logs
 
else
        mkdir abuse-hps
        cd abuse-hps
        logs
 
fi
