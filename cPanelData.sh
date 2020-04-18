#/bin/bash
#Script to Tar mail,DB and website contents of a cPanel account.
passwd="xxxx"
m=0;
em=0;
web=0;
tarr()
{
mkdir /root/abuse_data_$user;cd /root/abuse_data_$user;
if [[ $m -ne 1 ]];then
	echo -e "\n Taking Database dumps...\n";
	mkdir mysql;
	cd /var/lib/mysql/
	for i in `ls   | grep $user`;do mysqldump $i > $i.sql; echo -e "\n Dump taken for $i\n"; mv $i.sql /root/abuse_data_$user/mysql/  ;done 2>/dev/null
	cd /root/abuse_data_$user/
fi
if [[ $em -ne 1 ]];then
	echo -e "\n Copying Mails...\n"
	cp -pr /$home/$user/mail .
fi
if [[ $web -ne 1 ]]; then
	echo -e "\n Copying Webdata...\n"
	cp -pr $path .
fi
echo -e "\nTarring all available data...\n"
tar -cvzf ../abuse_data_$user.tar.gz * &>/dev/null
cd ..
rm -rf abuse_data_$user;
echo -e "Size of Tar File:\n-----------------"
du -sh abuse_data_$user.tar.gz;
echo -e "\n-----------------\n"
expect - << EOF
spawn rsync -ae "ssh -q" abuse_data_$user.tar.gz root@xxx.x.x.xxx:/usr/local/apache/htdocs/
expect "Password:"
send "xxxx"
send_user "\n\nTransferring to demomonkey...This may take a while...Hold on!\n"
if [catch wait] {
	    puts "rsync failed"
	        exit 1
}
EOF
echo -e "\nTransfer completed! \n";
rm -rf abuse_data_$user.tar.gz
echo -e "\n++++++++++++++++++++++++++++++++++++++++++++\nDownloadable link: http://xxx.x.x.xxx/abuse_data_$user.tar.gz\n++++++++++++++++++++++++++++++++++++++++++++\n";
}
echo -e "\nEnter the domain name for which the Website data, Databases and emails are required:\n";
read dom;
user=`/scripts/whoowns $dom`;
if [ $? -ne  0 ];
then
	echo -e "\nThis is not an active domain!Please enter the domain name that is hosted on this server.\n";
	exit;
else
	path=`grep $dom /etc/userdatadomains | tail -1 | awk '{print $2}' | cut -d'=' -f9`;
	home=`grep $dom /etc/userdatadomains | tail -1 | awk '{print $2}' | cut -d'=' -f9 | cut -d '/' -f2`;
	echo -e "\nCalculating size of user's data... \n";
	echo -e "\n++++++++++++++++++DATABASE++++++++++++++++++\n"
	du -sh /var/lib/mysql/$user* 2>/dev/null
	if [ $? -ne 0 ];
	then
		echo -e "Looks like there are no databases available!"
		m=1;
	fi
	echo -e "\n+++++++++++++++++++EMAIL++++++++++++++++++++\n"
	du -sh /$home/$user/mail 2>/dev/null
	if [ $? -ne 0 ];
	then
		echo -e "Looks like there are no emails available!"
		em=1;
	fi
	echo -e "\n+++++++++++++++WEBSITE+CONTENT++++++++++++++\n"
	du -sh $path 2>/dev/null
	if [ $? -ne 0 ];
	then
		echo -e "Looks like there are no website data available!"
		web=1;
	fi
	echo -e "\n++++++++++++++++++++++++++++++++++++++++++++\n"
fi

read -p "Continue to proceed further(y/n)?" choice
case "$choice" in 
  y|Y ) tarr ;;
  n|N ) exit ;;
  * ) echo "invalid";;
esac
