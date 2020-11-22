#!/bin/bash
#Author: Mohamed Najaaf
echo -ne "\n Input the reseller domain name:"
read dom;
user=`/scripts/whoowns $dom`
OIFS="$IFS"
IFS=$'\n'
mkdir res_hps
cd res_hps
find /var/cpanel/packages/ -iname $user* | cut -d'/' -f5 >> pkg.txt
for i in `find /var/cpanel/packages/ -iname $user*`; do egrep -i 'quota|bwlimit' $i | grep -vi email |xargs echo -e "\n"  >> test.txt 2>/dev/null; done

set -- $( cat pkg.txt )
for i in `tr A-Z a-z <  test.txt`;
        do
                whmapi1 editpkg name="$1" $i &> /dev/null
                echo -e "\n BW and quota set for pkg $1...\n";
                shift
                done
rm -fv test.txt pkg.txt ../editpkg.sh
IFS="$OIFS"
