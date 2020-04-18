#!bin/bash
#Author: Mohamed Najaaf
#This script simplifies the process to find the Email account blocks, extract corresponding logs and to unblock the Email account.
PATH=$PATH:/usr/local/bin:/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/sbin:/home/`whoami`/bin
 
red=$(tput setaf 1)
yellow=$(tput setaf 3)
green=$(tput setaf 2)
cyan=$(tput setaf 6)
magenta=$(tput setaf 5)
reset=$(tput sgr 0)
 
 
#Logging the execution of this script
echo "[`date`] [`whoami`] Execution of Email Block Script" >> /home/mohamed.n/execution.log
 
#Get the required details as Inputs.
echo -e  "$red Enter the server hostname:$reset"
read  a;
echo -e "$yellow Enter the affected email account:$reset"
read b;
 
#Extracting the domain name from the Email Address and storing the username to variable "user".
dom=`echo $b | cut -d'@' -f2 `
user=`ssh -o StrictHostKeyChecking=no $a " sudo /scripts/whoowns $dom" 2>/dev/null`
 
#Extracting Logs to find where exactly the email account is blocked.
logs=`ssh -o StrictHostKeyChecking=no $a "sudo grep $b /var/log/scripts/bklist_activate_mail.log | grep Blacklisted | tail -1" 2>/dev/null`
if [[ $logs == *"bounce-back"* ]];then
        {
                printf "$green \n ----- \n Email Account is blocked due to large number of Bounce-back emails. \n ----- $reset \n\n"
                flag=1;
                solution="The email account will be blacklisted if it has received more than 30 bounce messages in the last hour. Suggest the customer to audit their mailing lists, if any. Also, ask the customer to ensure that they send emails to only valid and existing email addresses."
        }
elif [[ $logs == *"cloudmark"* ]];then
        {
                printf "$green \n ----- \n Email Account is blocked due to CloudMark blocks. \n ----- $reset \n\n"
                flag=2;
                solution="The email account will be blacklisted if it has sent more than 10 spam emails in the last 30 minutes. Check and open a ticket to CloudMark, if the CMAE Anyalysis header is reported as Spam. \n\n Use the link: https://cat.cloudmark.com/index.php/authority-analysis "
        }
elif [[ $logs == *"Ratelimit"* ]];then
        {
                printf "$green \n ----- \n Email Account is blocked due to Exceeded Rate limits. \n ----- $reset \n\n"
                flag=3;
                solution="Suggest the customer to not breach the Rate Limits set in the server:\n\n1.The Rate Limit for mail through scripts per user per hour (Non-SMTP) is 75 recipients/user/hour OR 50 mails/user/hour whichever is reached first.\n2.The Rate Limit for mail through scripts or web client per user per hour (SMTP) is 150 recipients/user/hour OR 100 mails/user/hour whichever is reached first.\n3.The Rate limit for a number of recipients per hour per domain name is 500 mails per hour per domain name. This is for both SMTP and Non-SMTP mails.\n"
        }
elif [[ $logs == *"multiple entries"* ]];then
        {
                printf "$green \n ----- \n User is suspended due to 5 entry block. \n ----- $reset \n\n"
 
        }
elif [[ $logs == *"FBL"* ]];then
        {
                printf "$green \n ----- \n Email Account/User is suspended due to FBL complaints. \n ----- $reset \n\n"
                flag=5;
                solution=" Refer the KB : https://confluence.endurance.com/display/BR/Email+block+due+to+FBL+Complaints "
        }
 
elif [[ $logs == *"Script_Spoofing"* || *"SMTP_Spoofing"*  ]];then
        {
                printf "$green \n ----- \n Email Account is blocked due to Spoofing. \n ----- $reset \n\n"
                flag=4;
                solution="Customer won't be able to use the mail function if the FROM email address is not from the same domain. Ask the Customer to Check the mail script and ensure that the FROM address is from the same domain that is emailaddress@domain.com. The email account should be authenticated using SMTP authentication. Customer can use the SMTP host as 'localhost' if it is  running on our server."
        }
else printf "$green ----- \n Email Account is not blocked. \n ----- $reset \n\n"
 
fi
 
#Function to print the menu in a loop until the user exits.
options()
 
        {       #Prints the Menu
                printf "\r $magenta*****OPTIONS*****\n\n[1]Logs\n[2]Activate Email Account\n[3]Solution\n[4]Exit \n\n *******END******* $reset \n"
                echo -e "\n Enter your Choice:"
                read choice
 
                #Using CASE statement, we execute the different options mentioned in the menu.
                case $choice in         #Option1: Prints Exim Logs for the corresponding block.
                                        1 )
 
 
                                                if [[ $flag = 1  ]];then
                                                        {
                                                                elogs=`ssh -o StrictHostKeyChecking=no -q $a "sudo zgrep "$b" /var/log/exim_mainlog* | grep '<>' | tail -10 " 2>/dev/null`
                                                        }
                                                elif [[ $flag = 2 ]];then
                                                        {
                                                                elogs=`ssh -o StrictHostKeyChecking=no -q $a "sudo find /var/log/ -name 'exim_mainlog*' -exec zgrep -- '$user'  {} + | sort | grep 'detected message as spam' | tail -10 "`
                                                        }
                                                elif [[ $flag = 3 ]];then
                                                        {
                                                                elogs=`ssh -o StrictHostKeyChecking=no -q $a "sudo find /var/log/ -name 'exim_mainlog*' -exec zgrep -- '$b'  {} + | sort | grep 'ratelimit' | tail -10"`
                                                        }
                                                elif [[ $flag = 4 ]];then
                                                        {
                                                                elogs=`ssh -o StrictHostKeyChecking=no $a "sudo zgrep "Message denied for spoofing" /var/log/exim_mainlog* | egrep "$b"| tail -10 " 2>/dev/null`
                                                        }
 
                                                elif [[ $flag = 5  ]];then
                                                        {
                                                                elogs="Refer the KB : https://confluence.endurance.com/display/BR/Email+block+due+to+FBL+Complaints"
                                                        }
                                                else
                                                        {
                                                                elogs=`ssh -o StrictHostKeyChecking=no $a "sudo grep "$b" /var/log/scripts/fbl-blacklist.log | tail -10"  2>/dev/null`
                                                        }
 
                                                fi
 
                                                #If No logs found.
                                                if [ -z "$elogs" ]
                                                then
                                                        echo -e "\n\nLogs:\n==============\n$yellow No Logs Found!!!  \n$reset============="
                                                else
                                                        echo -e "\n\nLogs:\n==============\n$yellow $elogs  \n$reset============="
                                                 fi
                                         ;;
 
                                        2 ) #Option2: To activate the Email Account.
                                                unblocked=`ssh -o StrictHostKeyChecking=no $a "sudo /usr/local/scripts/techsupp_helper_scripts/abuse_handling_scripts/bklist_activate_mail.sh --activate $b"`
                                                echo "$unblocked"
                                        ;;
 
                                        3 ) #Option3: Solution for the Email Block.
                                                echo -e "\n\nSolution:\n===========\n$yellow $solution \n$reset============"
                                         ;;
 
                                        4 ) #Option4: Exit.
                                                break;
                esac
        }
#Prints the Menu in a loop using options function created earlier
while true
        do
                options
        done
