#!/bin/bash
#Author: Mohamed Najaaf
PATH=$PATH:/usr/local/bin:/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/sbin:/home/`whoami`/bin
#This Script simplifies the process of finding the Mod Security triggerings, logs and Disabling/Enabling a particular Mod Security rule ID for cPanel servers.
 
red=$(tput setaf 1)
y=$(tput setaf 3)
g=$(tput setaf 2)
cyan=$(tput setaf 6)
blue=$(tput setaf 4)
res=$(tput sgr 0)
 
#Logging the execution of this script
echo "[`date`] [`whoami`] Execution of ModSecurity Script" >> /home/mohamed.n/execution.log
 
echo  "$red Enter the server hostname:$res"
read  a;
echo "$red Enter the domain name:$res"
read b;
echo "$red Enter the Customer's Public IP address:$res"
read ip;
 
user=`ssh -o StrictHostKeyChecking=no -q $a " sudo /scripts/whoowns $b"`
logs=`ssh -o StrictHostKeyChecking=no -q $a " sudo egrep '$b|$user' /usr/local/apache/logs/error_log | grep $ip | tail -20"`
 
if [ -z "$logs" ];
               then {
                     echo -e "\n\n $cyan Logs:\n==============\n $res $y No Logs Found!!!  \n$res$cyan=============$res"
                     flag=1;
                   }
                 else
                       echo -e "\n\n $cyan   Logs:\n==============\n $res $y $logs  \n$res$cyan==============$res"
                fi
options()
{
echo -e "\n \n $g*****OPTIONS*****\n\n[1]Disable ModSec ID\n[2]Enable ModSec ID\n[3]ModSec/Error Logs\n[4]Exit \n\n *******END******* $res \n"
echo -e "\n$red Enter your Choice:$res"
read choice;
 
case $choice in
        1 )
                echo -e "\n$red Enter the Mod Sec ID that needs to be disabled: $res "
                read id;
                idlogs=`ssh -o StrictHostKeyChecking=no -q $a " sudo grep $id /usr/local/apache/logs/error_log | tail -1"`
                if [ $id == "900407" ] || [[ $idlogs == *"/etc/httpd/modsecurity.d/10_asl_rules.conf"* ]] || [[ $idlogs == *"/opt/mod_security/hg_rules.conf"* ]] || [[ $idlogs == *"/etc/httpd/modsecurity.d/00_asl_0_global.conf"* ]] || [[ $idlogs == *"/etc/httpd/modsecurity.d/00_asl_z_antievasion.conf"* ]]|| [[ $idlogs == *"/etc/httpd/modsecurity.d/00_asl_zz_strict.conf"* ]] || [[ $idlogs == *"/etc/httpd/modsecurity.d/01_asl_content.conf"* ]] || [[ $idlogs == *"/etc/httpd/modsecurity.d/03_asl_dos.conf"* ]] || [[ $idlogs == *"/etc/httpd/modsecurity.d/09_asl_rules.conf"* ]] || [[ $idlogs == *"/etc/httpd/modsecurity.d/10_asl_rules.conf"* ]];then
                        {
                                echo -e "\n$red************* $res \n $cyan For Security reasons, we cannot whitelist this particular Mod Security ID. Kindly ask the customer to make changes in the Application/code with the help of a developer!$res\n$red************* $res \n"
                        }
                else
                        {
                                echo -e "$cyan \n In Progress.... $res \n "
                                ssh -o StrictHostKeyChecking=no -q $a " sudo /usr/local/scripts/techsupp_helper_scripts/modsec_manage.rb -d $b -u $user -r $id "  2>/dev/null
                                echo -e "$g \n Almost Finished...! $res \n"
                                ssh -o StrictHostKeyChecking=no -q $a " sudo /etc/init.d/httpd graceful " 2>/dev/null
                                echo -e "$y  \n \n********** \n  Mod Security Trigger ID : $red $id $res $y is now Disabled for the domain $res $red $b $res $y !!! \n*********** \n \n  $res"
                        }
                fi
                ;;
        2 )
                echo -e "\n $red Enter the Mod Sec ID that needs to be enabled: $res "
                read id;
                echo -e "$cyan \n In Progress.... $res \n "
                ssh -o StrictHostKeyChecking=no -q $a " sudo /usr/local/scripts/techsupp_helper_scripts/modsec_manage.rb -d $b -u $user -r $id -e " 2>/dev/null
                echo -e "$g \n Almost Finished...! $res \n"
                ssh -o StrictHostKeyChecking=no -q $a " sudo /etc/init.d/httpd graceful " 2>/dev/null
                echo -e "$y  \n \n********** \n Mod Security Trigger ID : $red $id $res $y is now Enabled for the domain $res $red $b $res $y !!! \n*********** \n \n $res"
                ;;
        3 )
                if [ flag == 1 ]
                then
                        echo -e "\n\nLogs:\n==============\n$y No Logs Found!!!  \n$res============="
                else
                        echo -e "\n\nLogs:\n==============\n$y $logs  \n$res============="
                fi
                ;;
        4 )
                break;
        esac
}
while true
do
options
done
