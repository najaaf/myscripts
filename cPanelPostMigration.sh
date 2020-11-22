#!/bin/bash
#Mohamed Najaaf
#Script for Post Migration changes for a cPanel account.

#Color codes
red=$(tput setaf 1);
gre=$(tput setaf 2);
yel=$(tput setaf 3);
vio=$(tput setaf 5);
cya=$(tput setaf 6);
res=$(tput sgr 0);

clear

#Taking inputs
echo -e "\n$gre Enter the domain:$res"
read dom;
echo -e "\n$gre Enter the username of domain in the old server:$res"
read olduser;
echo -e "\n$gre Enter old server home:$res"
read oldhome;
echo -e "\n$gre Enter the Case ID:$res"
read caseid;


user=`/scripts/whoowns $dom`;
rockplan=`grep PLAN /var/cpanel/users/$user | cut -d"=" -f2`;
echo -e "\n$cya New Rock Platform Plan Name is:$red $rockplan $res"
bhome=`grep $dom /etc/userdatadomains | tail -1 | awk '{print $2}' | cut -d'=' -f9 | cut -d '/' -f2`;

echo -e "\n\n$yel Searching for migrated cpmove package...$res"
if [ -f /$bhome/cpmove-$olduser.tar.gz ];then
        echo -e "\n\n$cya cpmove package is present under:$red /$bhome/cpmove-$olduser.tar.gz $res\n"
else
        echo -e "\n\n$red cpmove package not found!!!. Please ensure it is present under /$bhome/ $res\n"
        exit;
fi

if [ -d /home1/migration/$caseid/ ];then
	cp -pr /var/cpanel/users/$user /home1/migration/$caseid/$user.txt
elif [ -d /home1/migration/ ];then
	mkdir /home1/migration/$caseid/
	cp -pr /var/cpanel/users/$user /home1/migration/$caseid/$user.txt
elif [ -d /home1/  ];then
	mkdir -p /home1/migration/$caseid/
	cp -pr /var/cpanel/users/$user /home1/migration/$caseid/$user.txt

else
	mkdir -p /home1/migration/$caseid/
        cp -pr /var/cpanel/users/$user /home1/migration/$caseid/$user.txt
fi

echo -e "\n$cya Copied the users account info to $red /home1/migration/$caseid/$user.txt \n"


cd /home1/migration/$caseid/
echo -e "\n\n$yel Removing existing cPanel account...$red\n"
yes "y" | /scripts/removeacct $user >> accnt_remove_log 2>/dev/null

echo -e "\n$cya Account Removal log available at $red /home1/migration/$caseid/accnt_remove_log \n"

echo -e "\n\n$yel Restoring migrated cpmove package...This may take a while! $res \n\n"
/scripts/restorepkg /$bhome/cpmove-$olduser.tar.gz >> migration_log

if [[ `cat migration_log` == *"Account Restore Failed"* ]]; then
	echo -e "\n $red Account Restore Failed. Check the migration_log...\n";
	echo -e "\n Migration log available at: /home1/migration/$caseid/migration_log $res\n"
	exit;
else 
	echo -e "\n$yel Restoration completed.\n";
	echo -e "\n$cya Migration log available at $red /home1/migration/$caseid/migration_log \n"
fi

ahome=`grep $dom /etc/userdatadomains | tail -1 | awk '{print $2}' | cut -d'=' -f9 | cut -d '/' -f2`;
if [ $oldhome == $ahome  ];then
	flag=1
else
	flag=0
fi


echo -e "\n$yel Updating the Username to the BlueRock one...! \n"
whmapi1 modifyacct user=$olduser newuser=$user &>/dev/null

echo -e "\n Unsuspending the account...\n"
/scripts/unsuspendacct $user &>/dev/null

echo -e "\n Rebuilding httpd...\n"
/scripts/rebuildhttpdconf &>/dev/null

echo -e "\n$yel Updating PLAN, RS, FEATURELIST and other limits! $res \n"
sed -i "/FEATURELIST=/c\FEATURELIST=test"  /var/cpanel/users/$user
sed -i "/RS=/c\RS=test"  /var/cpanel/users/$user
sed -i "/PLAN=/c\PLAN=$rockplan" /var/cpanel/users/$user
if [ $rockplan == plan1 ]
then
        sed -i "/MAXADDON=/c\MAXADDON=0"  /var/cpanel/users/$user
        sed -i "/MAXPARK=/c\MAXPARK=5" /var/cpanel/users/$user
        sed -i "/MAXPOP=/c\MAXPOP=5" /var/cpanel/users/$user
        sed -i "/MAXSQL=/c\MAXSQL=20" /var/cpanel/users/$user
        sed -i "/MAXSUB=/c\MAXSUB=25" /var/cpanel/users/$user
	sed -i "/MAXFTP=/c\MAXFTP=unlimited" /var/cpanel/users/$user
	sed -i "/MAX_EMAIL_PER_HOUR=/c\MAX_EMAIL_PER_HOUR=500" /var/cpanel/users/$user
else
        sed -i "/MAXADDON=/c\MAXADDON=unlimited"  /var/cpanel/users/$user
        sed -i "/MAXPARK=/c\MAXPARK=unlimited" /var/cpanel/users/$user
        sed -i "/MAXPOP=/c\MAXPOP=unlimited" /var/cpanel/users/$user
        sed -i "/MAXSQL=/c\MAXSQL=unlimited" /var/cpanel/users/$user
        sed -i "/MAXSUB=/c\MAXSUB=unlimited" /var/cpanel/users/$user
	sed -i "/MAXFTP=/c\MAXFTP=unlimited" /var/cpanel/users/$user
	sed -i "/MAX_EMAIL_PER_HOUR=/c\MAX_EMAIL_PER_HOUR=500" /var/cpanel/users/$user
fi

echo -e "\n Verifying if all the details have been updated correctly... $res \n";
echo -e "$gre Username:$res $red`/scripts/whoowns $dom`\n"
egrep 'PLAN|FEATURELIST|RS' /var/cpanel/users/$user

echo -e "\n $yel Updating userdomains... $res \n"
/scripts/updateuserdomains

echo -e "\n$yel Checking for old username entries in the sitefiles...\n"
#for i in `grep $user /etc/userdatadomains | grep -v public_html | grep addon | awk '{print $2}' | cut -d= -f9`; do grep -irl "$olduser" $i | grep -v error >> old_username.txt; done
grep -irl "$olduser"  /$ahome/$user/public_html/ | grep -v log >> old_username.txt
if [ -s old_username.txt ];then
        echo -e "\n$cya List of Files with Old username entries saved to $red /home1/migration/$caseid/old_username.txt \n"
	echo -e "\n$yel Updating old username entries to new ones..\n"
        for i in `cat old_username.txt`; do sed -i "s/$olduser/$user/g" $i;done
#	for i in `cat old_username.txt`; do sed -i "s/$olduser_/$user_/g" $i;done
else
        echo -e "\n$red No Old Username entries found!"
fi

echo -e "\n$yel Checking for old username entries in the user's crontab...\n"
grep "$olduser" /var/spool/cron/$user &>/dev/null
if [ $? -ne 0  ];then
        echo -e "\n$red No old username records found in crontab! \n"
else
        echo -e "\n$yel Updating crontab...\n"
        sed -i "s/\b$olduser\b/$user/g" /var/spool/cron/$user
fi

if [ $flag == 0  ];then
	echo -e "\n$yel Checking for old server home entries in the site files...\n"
#	for i in `grep $user /etc/userdatadomains | grep -v public_html | grep addon | awk '{print $2}' | cut -d= -f9`; do grep -irl "/$oldhome/$user" $i | grep -v error >> oldhome.txt; done
	grep -irl "/$oldhome/$user" /$ahome/$user/public_html/ | grep -v log >> oldhome.txt
	if [ -s oldhome.txt ];then
        	echo -e "\n$cya List of Files with Old home entries saved to $red /home1/migration/$caseid/oldhome.txt \n"
		echo -e "\n$yel Updating old server home entries to new ones..\n"
        	for i in `cat oldhome.txt`; do sed -i "s/\/$oldhome\/$user/\/$ahome\/$user/g" $i;done
	else
        	echo -e "\n$red No old server home entries found!"
	fi
	echo -e "\n$yel Checking for old server home entries in user's crontab...\n"
	grep -irl "/$oldhome/$user" /var/spool/cron/$user
	if [ $? -ne 0  ];then
        	echo -e "\n$red No old server home records found in crontab! $res \n"
	else	
        	echo -e "\n$yel Updating crontab...\n"
        	sed -i "s/\/$oldhome\/$user/\/$ahome\/$user/g" /var/spool/cron/$user
	fi
else
	break;
fi

rm -f /$bhome/cpmove-$olduser.tar.gz
rm -f /$bhome/rock.sh
echo -e "\n$cya Searching if there are any addon domains that needs to be assigned...$res\n"
addons=`grep $user /etc/userdatadomains |  grep addon`
if [ $? -ne 0 ];
then 
	echo -e "$red No Addon Domains found! \n $res";
else
	echo -e "$vio Please assign the below addon domains in the new server: \n";
	grep $user /etc/userdatadomains | grep addon | awk -F[:=] '{print $1 " --> " $10}'
fi

echo -e "\n$gre Post migration changes completed successfully! \n\n Try accessing the site now from the new server!\n\n $res ";
