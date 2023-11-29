#!/bin/bash
############################################GlobalVariables######################################
#Description: This script is for Pre RTPA of Linux servers for Unix Run team
#This script is calibrated for the purpose of speeding up the checking process of validating a server/s
#that are being transitioned.
#
#Revision Descriptions: 
# v1.0		initial script that contains the standard UNIX team server transition checks
# v1.1		fixed clocking error check if there are multiple user entries with regex capture
# v2.0		added RHEL 7.5 and removed HPOM 11.14, added server uptime
# v2.1		fixes kdump check for bare-metal servers
# v2.2		fixed random swap checking issue
# v2.3		teaming ports easy detect to be added a request from Brian Dim
# v3.0		crash test check is added; run logging fixed
# v3.1		for rhel7.7 & marks NTP as non standard
# v3.1.1	fixed HPOM versioning
# v3.2		error on new storage fixed, TO2017000096; Added: systool, FC adapter Check and Active Fiber Channel check; Fixed: Dual HBA Card on Different I/O Chassis and Multipath Information for SAN Disks 
#			fixed required kernel to 7.9
# v4.0		added server subscription checking, adjusted HPOM version, modified HPOM versioning, added SAR check, CheckCoreFS, updated CheckCore, added corefile hostname checker, added BMtools
#			fixed vmcore checking, added iDRAC Hostname checking
# v4.1          modified kernel checks, subscription checks, /var/crash checks, vmcore checks
# v5.0          added MTU check for Oracle DB Linux servers
# v6.0          added LDAP/VDS check and updated kernel version checks
# v7.0          added hostname alias checking and corrected script versioning
#Editor:			Version:			Date:
#Paolo Bonafe		v1.0					Dec. 01, 2018
#Paolo Bonafe		v1.1					Jan. 09, 2019
#Paolo Bonafe		v2.0					Mar. 06, 2019
#Paolo Bonafe		v2.1					Aug. 14, 2019
#Paolo Bonafe		v2.2					Aug. 26, 2019
#Paolo Bonafe		v2.3					Oct. 24, 2019
#Paolo Bonafe		v3.0					Dec. 12, 2019
#Paolo Bonafe		v3.1					May  15, 2020
#Paolo Bonafe		v3.1.1					May  28, 2020
#Paolo Bonafe		v3.2					Jul. 09, 2020 / May 03, 2022
#Paolo Bonafe		v4.0					Jun. 16, 2022 / July 6, 2022
#Rodel Bianan           v4.1                                    May  08, 2023
#Rodel Bianan           v5.0                                    Jul  06, 2023
#Rodel Bianan           v6.0                                    Nov  19, 2023
#Rodel Bianan           v7.0                                    Nov  20, 2023
############################################GlobalVariables######################################
HBA_CARD=emlxs
#
OPSWRPM="/opt/opsware/agent"
#ISMSECOSC=ISMsecosc
#
TIMEOUT="TMOUT=900"
R_SHELL=/usr/sbin/bash
UMASK=027
ssh_clientalive=900
ssh_clientCount=0
#

#----------------------------------------------------------------------------------------------
#Storing file output on /root under the path /root/QA_<hostname>/QA_<hostname>-<date>.log

mkdir /root/RTPA-QA_`uname -n`
LOG=/root/RTPA-QA_`uname -n`/QA_`uname -n`-`date '+%Y-%m-%d-%H:%M'`.log

if [ -f "$LOG" ]
then
#rm -f $LOG
#cat /dev/null >$LOG
#else
cat /dev/null >$LOG
fi

#++++++++++++++++QA START+++++++++++++++++++++++++++++++++++++++

function QA_Start {
echo " ------------------------------------------" | /usr/bin/tee -a ${LOG}
echo "PRE RTPA QA Version: v5.1" 		####	ALWAYS EDIT THIS LINE FOR REVISION VERSIONS 
echo " ------------------------------------------" | /usr/bin/tee -a ${LOG}
echo " ------------------------------------------" | /usr/bin/tee -a ${LOG}
echo " "    | /usr/bin/tee -a ${LOG}
echo  "         QA for  "`uname -n` | /usr/bin/tee -a ${LOG}
echo  "  =============================  " | /usr/bin/tee -a ${LOG}
echo " "   | /usr/bin/tee -a ${LOG}
envi=$(cat /etc/CIBC/setenv.done)
case $envi in
	d) echo "         server environment: DEV " | /usr/bin/tee -a ${LOG} ;;
	u) echo "         server environment: UAT " | /usr/bin/tee -a ${LOG} ;;
	b) echo "         server environment: DR " | /usr/bin/tee -a ${LOG} ;;
	p) echo "         server environment: PROD " | /usr/bin/tee -a ${LOG} ;;
esac
echo " "   | /usr/bin/tee -a ${LOG}
echo  "  =============================  " | /usr/bin/tee -a ${LOG}
echo " "   | /usr/bin/tee -a ${LOG}
echo "            Machine Type is:" | /usr/bin/tee -a ${LOG}
echo " `dmidecode -t system|grep 'Manufacturer\|Product'`" | /usr/bin/tee -a ${LOG}

/usr/sbin/dmidecode -t system|grep 'Manufacturer\|Product' | /usr/bin/tee -a ${LOG}

if [ `echo $?` == 0 ]
then
echo "            Machine is: Virtual" | /usr/bin/tee -a ${LOG}
else
echo "            Machine is: Physical" | /usr/bin/tee -a ${LOG}
fi

echo "      `date '+  DATE: %m/%d/%y            TIME: %H:%M:%S'`"   | /usr/bin/tee -a ${LOG}
echo " ------------------------------------------" | /usr/bin/tee -a ${LOG}
echo " ------------------------------------------" | /usr/bin/tee -a ${LOG}
echo " "    | /usr/bin/tee -a ${LOG}

switch=$(/usr/sbin/dmidecode -t system|grep 'Manufacturer'| awk '{print $2}' | cut -d "," -f1)

uname -a;date;uptime;

case $switch in
 VMware) Checkkernel; CheckDNS; CheckSub; CheckClock; CheckHPOM; CheckACFVersion; CheckOPSWare; CheckFSLimit; CheckROOTlogin; CheckProfileTimeOut; CheckSSHClientInterval; CheckSSHClientCount; CheckSWAP; CheckDMSETUPSTATUS; CheckVolumeMirroring; CheckSOSREPRT; CheckKDUMP; CheckCoreFS; CheckCore; CheckNetgroup; CheckSeLinux; CheckClus;CheckLoopbackMTU;checkLDAP;checkHOSTNAME;;
 *) Checkkernel; CheckDNS; CheckSub; CheckClock; CheckHPOM; CheckACFVersion; CheckOPSWare; CheckFSLimit; CheckROOTlogin; CheckProfileTimeOut; CheckSSHClientInterval; CheckSSHClientCount; CheckSWAP; CheckDMSETUPSTATUS; CheckVolumeMirroring; CheckSOSREPRT; CheckKDUMP_BM; CheckCoreFS; CheckCore; CheckNetgroup; CheckSeLinux; CheckBoot; CheckNET; Check_Tools; Check_FC; Check_HBA_MPATH; CheckClus; CheckTeaming; CheckBonding; BMTools; CheckLoopbackMTU;checkLDAP;checkHOSTNAME;;
esac

}

function Checkkernel {
kernel=$(uname -r)
echo "" | /usr/bin/tee -a ${LOG}
echo " Kernel Check  " | /usr/bin/tee -a ${LOG}
echo " ------------------" | /usr/bin/tee -a ${LOG}
echo "" | /usr/bin/tee -a ${LOG}
case $kernel in
	4.18.0-477.27.1.el8_8.x86_64) echo ".... kernel is "$kernel", Pass ...." | /usr/bin/tee -a ${LOG}
	release=$(cat /etc/redhat-release |cut -d'(' -f1|awk '{print $NF}')
	echo ".... Server is running "$release" Pass ...." | /usr/bin/tee -a ${LOG}	;; 
	3.10.0-1160.102.1.el7.x86_64) echo ".... kernel is "$kernel", Pass ...." | /usr/bin/tee -a ${LOG}
	release=$(cat /etc/redhat-release |cut -d'(' -f1|awk '{print $NF}')
	echo ".... Server is running "$release" Pass ...." | /usr/bin/tee -a ${LOG}	;; 
	*) echo ".... current kernel "$kernel", kernel should be 3.10.0-1160.102.1.el7.x86_64 or 4.18.0-477.27.1.el8_8.x86_64  Fail ...." | /usr/bin/tee -a ${LOG}
	release=$(cat /etc/redhat-release |cut -d'(' -f1|awk '{print $NF}')
	echo ".... Server is running "$release" but  should be running RHEL 7.9 or 8.8 Fail ...." | /usr/bin/tee -a ${LOG}	;; 
esac
echo " ------------------" | /usr/bin/tee -a ${LOG}
echo "" | /usr/bin/tee -a ${LOG}
}

function CheckDNS {	
ns=$(nslookup `hostname` | grep Name | awk '{print $2}')
echo "" | /usr/bin/tee -a ${LOG}
echo " DNS Check  " | /usr/bin/tee -a ${LOG}
echo " ------------------" | /usr/bin/tee -a ${LOG}
echo "" | /usr/bin/tee -a ${LOG}
if [ -z "$ns" ] 
then
	echo ".... DNS name Fail ..." | /usr/bin/tee -a ${LOG}
else 
	echo ".... DNS name is "$ns"    Pass ...." | /usr/bin/tee -a ${LOG}
fi
echo " ------------------" | /usr/bin/tee -a ${LOG}
echo "" | /usr/bin/tee -a ${LOG}
}

function CheckClock {
echo "" | /usr/bin/tee -a ${LOG}
echo " Clock Check  " | /usr/bin/tee -a ${LOG}
echo " ------------------" | /usr/bin/tee -a ${LOG}
echo "" | /usr/bin/tee -a ${LOG}

clock=$(ps -ef|egrep 'ntp|chrony'|grep -v grep|awk '{print $1}'|egrep 'ntp|chrony')

case $clock in
	ntp) echo "			.... NTP is not standard for RHEL 7.9 and RHEL 8 release    Fail...."  | /usr/bin/tee -a ${LOG}
	echo " ------------------" | /usr/bin/tee -a ${LOG}
	ntpq -pn | /usr/bin/tee -a ${LOG}
	echo " ------------------" | /usr/bin/tee -a ${LOG}
	echo " ------------------" | /usr/bin/tee -a ${LOG}
	synchronised="synchronised"
	synced=$(ntpstat |head -1 | cut -d " " -f1)
	if [[ "$synced" == "$synchronised" ]]  
		then 
			echo "				.... NTP is not standard for RHEL 7.9 and RHEL 8 release    Fail...." | /usr/bin/tee -a ${LOG}
		else 
			echo "				.... NTP is not standard for RHEL 7.9 and RHEL 8 release    Fail...." | /usr/bin/tee -a ${LOG}
	fi;;
	chrony) echo ".... chrony is configured    Pass...." 
	echo " ------------------" | /usr/bin/tee -a ${LOG}
	chronyc sources | /usr/bin/tee -a ${LOG}
	echo " ------------------" | /usr/bin/tee -a ${LOG}
	echo " ------------------" | /usr/bin/tee -a ${LOG}
	synced=$(chronyc tracking|grep Leap | awk '{print $4}')
	if [[ "$synced" = "Not" ]] 
	then	
			echo "				.... chronyc "$synced" synchronised      Fail ...." | /usr/bin/tee -a ${LOG}
	else
			echo "				.... chronyc "$synced"      Pass ...." | /usr/bin/tee -a ${LOG}
	fi;;
	*) echo ".... time source not running/configured      Fail...." | /usr/bin/tee -a ${LOG} ;;
esac
echo " ------------------" | /usr/bin/tee -a ${LOG}
echo "" | /usr/bin/tee -a ${LOG}
}

function CheckHPOM {
echo "" | /usr/bin/tee -a ${LOG}
echo " HPOM Check  " | /usr/bin/tee -a ${LOG}
echo " ------------------" | /usr/bin/tee -a ${LOG}
echo "" | /usr/bin/tee -a ${LOG}

echo "HPOM status check" | /usr/bin/tee -a ${LOG}
/opt/OV/bin/opcagt -status | /usr/bin/tee -a ${LOG}
check=$(/opt/OV/bin/opcagt -status | egrep 'Aborted|Stopped' |wc -l)

if [ "$check" -ge "1" ];
then 
echo " ------------------" | /usr/bin/tee -a ${LOG}
echo "							....there are aborted/stopped objects      Fail...." | /usr/bin/tee -a ${LOG}
echo "perform cleanstart and try running script again, if it fails again reach ovo team" | /usr/bin/tee -a ${LOG}
else 
echo " ------------------" | /usr/bin/tee -a ${LOG}
echo "							....HPOM objects status     Pass...." | /usr/bin/tee -a ${LOG}

fi
echo " ------------------" | /usr/bin/tee -a ${LOG}
echo " ------------------" | /usr/bin/tee -a ${LOG}
echo " HPOM version Check  " | /usr/bin/tee -a ${LOG}
version="1214006"
hversion=$(/opt/OV/bin/opcagt -version|tr -d '.')
oversion=$(/opt/OV/bin/opcagt -version)

/opt/OV/bin/opcagt -version | /usr/bin/tee -a ${LOG}
if [[ ${hversion%%.%%} -ge ${version%%.%%} ]]
then
        echo "                                          ....HPOM version Pass...."  | /usr/bin/tee -a ${LOG}
else
        echo "                                          ....curent HPOM is "${oversion%%.%%}" below required version Fail...." | /usr/bin/tee -a ${LOG}
fi
echo " ------------------" | /usr/bin/tee -a ${LOG}
echo " ------------------" | /usr/bin/tee -a ${LOG}
echo " ------------------" | /usr/bin/tee -a ${LOG}
echo " HPOM Cert Check  " | /usr/bin/tee -a ${LOG}
echo " ------------------" | /usr/bin/tee -a ${LOG}
/opt/OV/bin/ovcert -check | /usr/bin/tee -a ${LOG}
cert_check=$(/opt/OV/bin/ovcert -check |grep Check|awk '{print $2}'); 
if [ "$cert_check" == "succeeded." ]
then
	echo "						.... OVO Cert $cert_check  Pass...."  | /usr/bin/tee -a ${LOG}
else 
	echo "						.... OVO cert Fail ...." | /usr/bin/tee -a ${LOG}
fi
echo " ------------------" | /usr/bin/tee -a ${LOG}
echo "" | /usr/bin/tee -a ${LOG}
}

function CheckACFVersion {

echo "" | /usr/bin/tee -a ${LOG}
echo " Check ACF Version " | /usr/bin/tee -a ${LOG}
echo " -----------------------" | /usr/bin/tee -a ${LOG}
echo "" | /usr/bin/tee -a ${LOG}

if cat /var/opt/osit/acf/log/acf.log | grep expired
	then	
		echo ".... OSIT ACF Version Expired.  Fail --- INSTALL THE Software Policy	OSIT toolset UX AutoUpdate VIA HPSA ---" | /usr/bin/tee -a ${LOG}
	else 
		echo ".... OSIT ACF Version Pass ---" | /usr/bin/tee -a ${LOG}
fi   
echo "" | /usr/bin/tee -a ${LOG}
}

function CheckOPSWare {

echo "" | /usr/bin/tee -a ${LOG}
echo " Check OPSWARE Installed " | /usr/bin/tee -a ${LOG}
echo " -----------------------" | /usr/bin/tee -a ${LOG}
echo "" | /usr/bin/tee -a ${LOG}

ops=`grep coglib.platform.lc_path: /etc/opt/opsware/agent/agent.args | awk '{print $2}'`

        if [ "$ops" = "$OPSWRPM" ]; then
                echo ".... Opsware Agent Installed.    Pass ...." | /usr/bin/tee -a ${LOG}
        else
                echo ".... Opsware Agent Not Installed.    Fail ...." | /usr/bin/tee -a ${LOG}
        fi

echo "" | /usr/bin/tee -a ${LOG}

}

function  CheckFSLimit {

TMP_LIMIT=1

echo "" | /usr/bin/tee -a ${LOG}
echo " Root owned file system usage limit   " | /usr/bin/tee -a ${LOG}
echo " ---------------------------------" | /usr/bin/tee -a ${LOG}
echo "" | /usr/bin/tee -a ${LOG}

for i in / /var/crash /home /tmp
do

limit=`df -Pk | awk 'BEGIN { OFS = " " } { $1 = $1; print }' |grep -w $i |awk '{print int($4/1000/1000)}'`

        if [ "$limit" -ge "$TMP_LIMIT" ]; then

                echo ".... $i available space is "$limit"GB.    Pass ...." | /usr/bin/tee -a ${LOG}
        else
                echo ".... $i available space is "$limit"GB.    Fail ...." | /usr/bin/tee -a ${LOG}
        fi
done

echo "" | /usr/bin/tee -a ${LOG}

}

function CheckROOTlogin {

echo "" | /usr/bin/tee -a ${LOG}
echo " Check ROOT Remote Login " | /usr/bin/tee -a ${LOG}
echo " -----------------------" | /usr/bin/tee -a ${LOG}
echo "" | /usr/bin/tee -a ${LOG}

cat /etc/ssh/sshd_config | grep -v "^#" | egrep "ClientAliveInterval|ClientAliveCountMax|PermitRootLogin"  >/tmp/.ssh_info
w_RootLogin_num=`cat /tmp/.ssh_info | grep PermitRootLogin | awk '{print $2}'|wc -l` >/dev/null
if [ $w_RootLogin_num = 1 ]; then

	ROOT=`cat /tmp/.ssh_info | grep PermitRootLogin | awk '{print $2}' | egrep "no|yes"`
       
	if [ X$ROOT = Xno ]; then
       		echo ".... Remote ROOT Login Disabled.    Pass ...." | /usr/bin/tee -a ${LOG}
        else
        	echo ".... Remote ROOT Login Not Disabled.    Fail .... -- /etc/ssh/sshd_config = line 130 set to ClientAliveInterval 900 --- " | /usr/bin/tee -a ${LOG}
        fi
else 
	echo ".... Remote ROOT Login Not Disabled.    Fail ...." | /usr/bin/tee -a ${LOG}
fi

echo "" | /usr/bin/tee -a ${LOG}

}

function CheckProfileTimeOut {

echo "" | /usr/bin/tee -a ${LOG}
echo " TIMEOUT in Profile  " | /usr/bin/tee -a ${LOG}
echo " -------------------" | /usr/bin/tee -a ${LOG}
echo "" | /usr/bin/tee -a ${LOG}

TM=`cat /etc/profile | grep TMOUT | uniq | awk -F";" '!/^#/{print $1}'` >/dev/null

        if [ ${TM}X = ${TIMEOUT}X ]; then
                echo ".... TIMEOUT Value $TM  Found.    Pass ...." | /usr/bin/tee -a ${LOG}
        else
                echo ".... TIMEOUT Value Not Found.    Fail ....  --- /etc/profile = line 78 or 79 set TMOUT=900 --- " | /usr/bin/tee -a ${LOG}
        fi

echo "" | /usr/bin/tee -a ${LOG}

}

function CheckSSHClientInterval {

echo "" | /usr/bin/tee -a ${LOG}
echo " SSH Client Alive Interval  " | /usr/bin/tee -a ${LOG}
echo " --------------------------" | /usr/bin/tee -a ${LOG}
echo "" | /usr/bin/tee -a ${LOG}

cat /etc/ssh/sshd_config | grep -v "^#" | egrep "ClientAliveInterval|ClientAliveCountMax|PermitRootLogin" >/tmp/.ssh_info
w_ClientAlive_Int=`cat /tmp/.ssh_info | grep ClientAliveInterval | awk '{print $2}' | wc -l` >/dev/null

if [ $w_ClientAlive_Int = 1 ]; then 
	w_ClientAlive=`cat /tmp/.ssh_info | grep ClientAliveInterval | awk '{print $2}'` >/dev/null

        if [ ${w_ClientAlive}X = ${ssh_clientalive}X ]; then
                echo ".... ClientAliveInterval Value $w_ClientAlive is set.    Pass ...."| /usr/bin/tee -a ${LOG}
        else
                echo ".... ClientAliveInterval Value $ssh_clientalive is not set.    Fail .... --- /etc/ssh/sshd_config = line 130 set ClientAliveInterval 900 ---"| /usr/bin/tee -a ${LOG}
        fi
else
	echo ".... ClientAliveInterval Value $ssh_clientalive is not set.    Fail .... "| /usr/bin/tee -a ${LOG}
fi

echo "" | /usr/bin/tee -a ${LOG}

}

function CheckSSHClientCount {

echo "" | /usr/bin/tee -a ${LOG}
echo " SSH Client Alive Count   " | /usr/bin/tee -a ${LOG}
echo " -----------------------" | /usr/bin/tee -a ${LOG}
echo "" | /usr/bin/tee -a ${LOG}

cat /etc/ssh/sshd_config | grep -v "^#" | egrep "ClientAliveInterval|ClientAliveCountMax|PermitRootLogin" >/tmp/.ssh_info
w_ClientAliveC_num=`cat /tmp/.ssh_info | grep ClientAliveCountMax | awk '{print $2}'|wc -l` >/dev/null

if [ $w_ClientAliveC_num = 1 ]; then
	w_ClientAliveC=`cat /tmp/.ssh_info | grep ClientAliveCountMax | awk '{print $2}'` >/dev/null

        if [ ${w_ClientAliveC}X = ${ssh_clientCount}X ]; then
                echo ".... ClientAliveCountMax Value $w_ClientAliveC is set.    Pass ...." | /usr/bin/tee -a ${LOG}
        else
                echo ".... ClientAliveCountMax Value $ssh_clientCount is not set.    Fail ...." | /usr/bin/tee -a ${LOG}
        fi
else
        echo ".... ClientAliveCountMax Value $ssh_clientCount is not set.    Fail .... --- /etc/ssh/sshd_config = line 131 set ClientAliveCountMax 0 ---" | /usr/bin/tee -a ${LOG}
fi

echo "" | /usr/bin/tee -a ${LOG}

}

function CheckSWAP {

echo "" | /usr/bin/tee -a ${LOG}
echo " Check SWAP Space " | /usr/bin/tee -a ${LOG}
echo " ----------------" | /usr/bin/tee -a ${LOG}
echo "" | /usr/bin/tee -a ${LOG}

SWAPDISKS=($(cat /proc/swaps | awk 'NR > 1 {print $1}'))
sSize=$(swapon -s | grep -v Filename | awk '{print $3/1024/1024}'| awk '{sum += $1} END {print sum}'|head -c 3)

echo ".... Swap device listing "${SWAPDISKS[*]}"   Info ...." | /usr/bin/tee -a ${LOG}

for i in SWAPDISKS
do
        swapon -s ${SWAPDISKS[*]} | grep -v Size | awk '{print $3/1024/1024}' |
         awk -v footprint=$sSize 'NR == 1 {large=$1; small=$1}
         $1 >= large {large = $1}
         $1 <= small {small = $1}
        END { print "Maximum swap slice found is = " large, "; Minumum swap slice found is = " small, "; Actual Swap found " footprint, (footprint>=small) ? "     .... Pass ...." : "     ... Fail ..." }' | /usr/bin/tee -a ${LOG}
done

echo "" | /usr/bin/tee -a

}

function CheckDMSETUPSTATUS {

echo "" | /usr/bin/tee -a ${LOG}
echo " Check DMSETUP Parameters " | /usr/bin/tee -a ${LOG}
echo " -----------------------" | /usr/bin/tee -a ${LOG}
echo "" | /usr/bin/tee -a ${LOG}

STATE="ACTIVE"

        for i in `dmsetup info | grep Name | awk '{print $2}'`
        do
                STATESTATUS=`dmsetup info $i | egrep State | awk '{print $2}'`

		#NAME=`dmsetup info $i | egrep Name | awk '{print $2}'`

                if [ "$STATESTATUS" = "$STATE" ]; then
                   echo ".... "$i" $STATESTATUS Check.    Pass ...." | /usr/bin/tee -a ${LOG}
                else
                   echo ".... "$i" $STATESTATUS Check.    Fail ...." | /usr/bin/tee -a ${LOG}
                fi

        done

echo "" | /usr/bin/tee -a ${LOG}

}

function CheckLVStatus {

echo "" | /usr/bin/tee -a ${LOG}
echo " Check Logical Volume  LVM Status " | /usr/bin/tee -a ${LOG}
echo " -----------------------" | /usr/bin/tee -a ${LOG}
echo "" | /usr/bin/tee -a ${LOG}

STATE="ACTIVE"

   for i in `lvscan 2> /dev/null | grep -i ACTIVE | awk '{print  $1 $2}'`
        do
                
                if [ "${i%%\'*}" = "$STATE" ]; then
                  echo ".... LV "${i/\'/ \'}" Status Check.    Pass ...." | /usr/bin/tee -a ${LOG}
                else
                  echo ".... LV "${i/\'/ \'}" Status Check.    Fail ...." | /usr/bin/tee -a ${LOG}
                fi
        done

echo "" | /usr/bin/tee -a ${LOG}

}

function CheckVolumeMirroring {

STATUS_MIRROR="m"

echo "" | /usr/bin/tee -a ${LOG}
echo " Check LVM Mirror Status " | /usr/bin/tee -a ${LOG}
echo " -----------------------" | /usr/bin/tee -a ${LOG}
echo "" | /usr/bin/tee -a ${LOG}

CHASSIE=`/usr/sbin/dmidecode -t system | awk ' /Product Name: / { print ($3 == "VMware") ? "virtual" : "physical" }'`

if [ "$CHASSIE" = "virtual" ]; then
        echo ".... System is virtual no mirror required.    Pass ...." | /usr/bin/tee -a ${LOG}

elif [ "$CHASSIE" = "physical" ]; then

        CHECK_MIRROR=`lvs -a -o +devices --noheadings 2> /dev/null | awk '{print $3}' | grep "m"`

        if [ "$CHECK_MIRROR" = "$STATUS_MIRROR" ]; then
                echo ".... Volume Mirrored.    Pass ...." | /usr/bin/tee -a ${LOG}
        else
                echo ".... Volume Not Mirrored.    Warning ...." | /usr/bin/tee -a ${LOG}
                echo ""
                echo ".... Check Raid 1 logicaldrive "#" status ...." | /usr/bin/tee -a ${LOG}
                echo ".... Install ssacli-2.60-19.0.x86_64.rpm ...." | /usr/bin/tee -a ${LOG}
                echo ".... # ssacli ctrl all show config | grep logicaldrive ...." | /usr/bin/tee -a ${LOG}
        fi
fi

echo "" | /usr/bin/tee -a ${LOG}

}

function CheckSOSREPRT {

SOSREPORT="sos"

echo "" | /usr/bin/tee -a ${LOG}
echo " Check SOSREPORT Utility Status " | /usr/bin/tee -a ${LOG}
echo " -----------------------" | /usr/bin/tee -a ${LOG}
echo "" | /usr/bin/tee -a ${LOG}

sosrpt=`rpm -qa | grep -i sos |awk -F"-" '{print $1}'`  >/dev/null
                                                            
        if [ "$sosrpt" = "$SOSREPORT" ]; then
                echo ".... SOSReport Installed.    Pass ...."| /usr/bin/tee -a ${LOG}                                          
        else                                                                                                                        
                echo ".... SOSReport Not Installed.    Fail ...."| /usr/bin/tee -a ${LOG}                                               
        fi                      

echo "" | /usr/bin/tee -a ${LOG}

}

function CheckNetgroup {

netgroup_chk=( ES-UX-MG-SEC-CR-L2 ES-UX-MG-SEC-CA-L4 ES-UX-MG-UX-PH-L1 ES-UX-MG-UX-PH-L2 ES-UX-MG-UX-PH-L3 ES-UX-MG-UX-CA-L4 ES-UX-MG-BK-IN-L1 ES-UX-MG-BK-IN-L2 ES-UX-MG-BK-IN-L3 ES-UX-G-BK-CA-L4 ES-UX-MG-MON-IN-L2 ES-UX-MG-MON-CR-L4 ES-UX-MG-MPC-CA-L4 ) 

echo "" | /usr/bin/tee -a ${LOG}
echo " Check Netgroup are present " | /usr/bin/tee -a ${LOG}
echo " -------------------------- " | /usr/bin/tee -a ${LOG}
echo "" | /usr/bin/tee -a ${LOG}

for i in "${netgroup_chk[@]}"

        do
                getent netgroup $i > /dev/null 2>&1 && echo ".... NETGROUP FOUND $i.    Pass ...." | /usr/bin/tee -a ${LOG} || echo ".... NETGROUP NOT FOUND $i.    Fail ...." | /usr/bin/tee -a ${LOG} ; 
        done 

echo "" | /usr/bin/tee -a ${LOG}

}

function CheckSeLinux {

echo "" | /usr/bin/tee -a ${LOG}
echo " Check SeLinux is enabled " | /usr/bin/tee -a ${LOG}
echo " ------------------------ " | /usr/bin/tee -a ${LOG}
echo "" | /usr/bin/tee -a ${LOG}

awk 'BEGIN {"getenforce" | getline SELINUX; close ("getenforce"); if (SELINUX~/Enforcing/) print ".... Selinux.    Pass ...."; else print ".... Selinux.    Failed .... --- enforcing it at /etc/sysconfig/selinux --- "}' | /usr/bin/tee -a ${LOG}

echo "" | /usr/bin/tee -a ${LOG}

}

function CheckKDUMP {

echo "" | /usr/bin/tee -a ${LOG}
echo " Check Kdump  " | /usr/bin/tee -a ${LOG}
echo " ----------------" | /usr/bin/tee -a ${LOG}
echo "" | /usr/bin/tee -a ${LOG}

OPERATIONAL=$(systemctl list-units kdump.service | sed $'s|^\(UNIT.*\)|\f\\DESCRIPTION|' | awk 'BEGIN { RS="\f" } /kdump.service loaded/ { print $3 $4}');
        
if [ $OPERATIONAL = loadedactive ]; then
        echo ".... Kdump  Configured.    Pass ...." | /usr/bin/tee -a ${LOG}
else
        echo ".... Kdump NOT Configured.    Fail ...." | /usr/bin/tee -a ${LOG}
fi

echo "" | /usr/bin/tee -a ${LOG}

}
function CheckCoreFS {
echo " ------------------" | /usr/bin/tee -a ${LOG}
echo " ------------------" | /usr/bin/tee -a ${LOG}
echo " ------------------" | /usr/bin/tee -a ${LOG}
echo "     CoreFS Check  " | /usr/bin/tee -a ${LOG}
echo " ------------------" | /usr/bin/tee -a ${LOG}
makedumpfile -f --mem-usage /proc/kcore | tee -a /tmp/coresize-$(date +'%d-%m-%y').txt | /usr/bin/tee -a ${LOG}
coresize=$(expr $(cat /tmp/coresize-$(date +'%d-%m-%y').txt|grep Total\ size| awk '{print $5}'|uniq) / 1024);
fssize=$(df -P /var/crash|tail -1|awk '{print $2}')
memsize=$(free -b|grep Mem|awk '{print $2}')
Msize=$(($memsize / 1024))
Fsize=$(($memsize / 1024))
echo "========================================================" | /usr/bin/tee -a ${LOG}
echo "Estimated vmcore size is:                      $coresize KB" | /usr/bin/tee -a ${LOG}
echo "Current filesystem /var/crash size is:         $fssize KB" | /usr/bin/tee -a ${LOG}
echo "FS /var/crash size should be:(equal to mem)     $Fsize KB" | /usr/bin/tee -a ${LOG} # change here
echo "--------------------------------------------------------" | /usr/bin/tee -a ${LOG}
echo " " | /usr/bin/tee -a ${LOG}
echo "Filesystem size value: (should be equal to memory)" | /usr/bin/tee -a ${LOG} # change here
if   (( $Fsize > $fssize ));
then
        echo "current /var/crash size is smaller than required size value (equal to Memory)			Fail...." | /usr/bin/tee -a ${LOG}
elif  (( $Fsize < $fssize ));
then
        echo "current /var/crash size is bigger than required size value							Pass...." | /usr/bin/tee -a ${LOG}
else
        echo "/var/crash should be equal to the value of the memory								Fail...." | /usr/bin/tee -a ${LOG} # change here
		echo "/var/crash $fssize KB" | /usr/bin/tee -a ${LOG}
		echo "memory size $Msize KB" | /usr/bin/tee -a ${LOG}
fi
echo " "
rm -f /tmp/coresize-$(date +'%d-%m-%y').txt

}


function CheckCore {
echo " ------------------" | /usr/bin/tee -a ${LOG}
echo " ------------------" | /usr/bin/tee -a ${LOG}
echo " ------------------" | /usr/bin/tee -a ${LOG}
echo " RHEL VMCORE Check  " | /usr/bin/tee -a ${LOG}
echo " ------------------" | /usr/bin/tee -a ${LOG}

lastcrash=$(ls -ldtr /var/crash/127.0.0.1*| tail -1|awk '{print $9}')
fL=$(grep -i set\ hostname /var/log/messages*|tail -1|cut -d: -f1)
fLwc=${#fL}
SysrqT=$(cat $lastcrash/vmcore-dmesg.txt|grep Trigger |awk '{print $4" "$5" "$6" "$7" "$8}')
Sysrq=$(cat $lastcrash/vmcore-dmesg.txt|grep Trigger|awk '{print $1}'|cut -d[ -f2|cut -d] -f1)
ut=`cut -d' ' -f1 </proc/uptime`
ts=`date +%s`
corefile=$(date -d"70-1-1 + $ts sec - $ut sec + $(date +%:::z) hour + $Sysrq sec - 1 hours" +"%F %T")
dcorefile=$(date -d"70-1-1 + $ts sec - $ut sec + $(date +%:::z) hour + $hNd sec - 1 hours" +"%F %T")
validCore=$(find "$lastcrash" -name 'vmcore-dmesg.txt' -type f -mtime -30)
M=$(grep -i set\ hostname /var/log/messages|tail -1|awk '{print $1 " " $2 " " $3}'|date +%s)
MfL=$(grep -i set\ hostname $fL|tail -1|cut -c $fLwc-|awk '{print $1 " " $2 " " $3}'|date +%s)
vmc=$(date +%s -r $lastcrash/vmcore-dmesg.txt)
#hN=$(grep -i set\ hostname /var/log/messages|tail -1|awk '{print $9}'|tr -cd '[a-zA-Z0-9]');
hN=$(cat /etc/hostname);
hNfL=$(grep -i set\ hostname $fL|tail -1|awk '{print $9}'|tr -cd '[a-zA-Z0-9]');



echo "========================================================" | /usr/bin/tee -a ${LOG}
echo "Core file validation:"| /usr/bin/tee -a ${LOG}
if [[ -d "$lastcrash" ]]
then
        if [[ -f $fL ]] 
        then
                echo "" | /usr/bin/tee -a ${LOG}
                echo ".... Core file validation                                                                 Pass...."| /usr/bin/tee -a ${LOG}
                echo ".... corefile generated hostname $hNfL at $dcorefile" | /usr/bin/tee -a ${LOG}
                echo ".... generated $SysrqT at $dcorefile" | /usr/bin/tee -a ${LOG}
                echo "========================================================" | /usr/bin/tee -a ${LOG}
        else
                echo "" | /usr/bin/tee -a ${LOG}
                echo ".... Core file validation                                                                 Pass...."| /usr/bin/tee -a ${LOG}
                echo ".... corefile generated hostname $hN at $dcorefile" | /usr/bin/tee -a ${LOG}
                echo ".... generated $SysrqT at $dcorefile" | /usr/bin/tee -a ${LOG}
                echo "========================================================" | /usr/bin/tee -a ${LOG}
        fi
else
        echo "" | /usr/bin/tee -a ${LOG}
        echo ".... Core file validation                                                 Fail...."| /usr/bin/tee -a ${LOG}
        echo "....              Please generate CORE DUMP, validate config under /etc/kdump.conf                        "| /usr/bin/tee -a ${LOG}
        echo "....              kindly invoke the command:  echo 1 > /proc/sys/kernel/sysrq                     "| /usr/bin/tee -a ${LOG}
        echo "....              Followed by the command:  echo c > /proc/sysrq-trigger          "| /usr/bin/tee -a ${LOG}
        echo "========================================================" | /usr/bin/tee -a ${LOG}
fi

if [[ -n "$lastcrash" ]] ;
then
        if [[ -f $fL ]] 
        then
                if [[ `uname -n` == $hN ]] && [[ $MfL > $vmc ]];
                then
                echo "....Core file hostname match                                                              Pass...."| /usr/bin/tee -a ${LOG}
                        if [[ ! -n "$validCore" ]]
                        then
                                echo "" | /usr/bin/tee -a ${LOG}
                                echo "$lastcrash"| /usr/bin/tee -a ${LOG}
                                echo ".... Core file is more than 30 days                                                       Fail...."| /usr/bin/tee -a ${LOG}
                                echo " ------------------" | /usr/bin/tee -a ${LOG}
                                echo "                          Please generate a new CORE DUMP, "| /usr/bin/tee -a ${LOG}
                                echo "                          kindly invoke the command:  echo 1 > /proc/sys/kernel/sysrq          "| /usr/bin/tee -a ${LOG}
                                echo "                          Followed by the command:  echo c > /proc/sysrq-trigger          "| /usr/bin/tee -a ${LOG}
                                echo " ------------------" | /usr/bin/tee -a ${LOG}
                                echo " ------------------" | /usr/bin/tee -a ${LOG}
                        else
                                echo " ------------------" | /usr/bin/tee -a ${LOG}
                                echo "$lastcrash"| /usr/bin/tee -a ${LOG}
                                echo ".... Core file is still valid                                                             Pass...."| /usr/bin/tee -a ${LOG}
                                echo " ------------------" | /usr/bin/tee -a ${LOG}
                                echo " ------------------" | /usr/bin/tee -a ${LOG}
                        fi
                else
                        echo "" | /usr/bin/tee -a ${LOG}
                        echo " ------------------" | /usr/bin/tee -a ${LOG}
                        echo " ------------------" | /usr/bin/tee -a ${LOG}
                        echo ".... Core file invalid, not matching                                                      Fail..." | /usr/bin/tee -a ${LOG};
                        echo " ------------------" | /usr/bin/tee -a ${LOG}
                        echo " ------------------" | /usr/bin/tee -a ${LOG}
                        echo "" | /usr/bin/tee -a ${LOG}
                fi
        else
                echo "" | /usr/bin/tee -a ${LOG}
                echo " ------------------" | /usr/bin/tee -a ${LOG}
                echo "....CoreCheck                                                             Fail..." | /usr/bin/tee -a ${LOG};
                echo " ------------------" | /usr/bin/tee -a ${LOG}
                echo "" | /usr/bin/tee -a ${LOG}
                echo "....                      Please generate CORE DUMP, validate config under /etc/kdump.conf                     "| /usr/bin/tee -a ${LOG}
                echo "....                      kindly invoke the command:  echo 1 > /proc/sys/kernel/sysrq                     "| /usr/bin/tee -a ${LOG}
                echo "....                      Followed by the command:  echo c > /proc/sysrq-trigger          "| /usr/bin/tee -a ${LOG}
                echo "" | /usr/bin/tee -a ${LOG}
                echo " ------------------" | /usr/bin/tee -a ${LOG}
                echo " ------------------" | /usr/bin/tee -a ${LOG}
                if [[ `uname -n` == $hN ]] && [[ "$M" > "$vmc" ]];
                then
                        echo "....Core file hostname match                                                              Pass...."| /usr/bin/tee -a ${LOG}
                        if [[ ! -n "$validCore" ]]
                        then
                                echo "" | /usr/bin/tee -a ${LOG}
                                echo "$lastcrash"| /usr/bin/tee -a ${LOG}
                                echo ".... Core file is more than 30 days                                                       Fail...."| /usr/bin/tee -a ${LOG}
                                echo " ------------------" | /usr/bin/tee -a ${LOG}
                                echo "                          Please generate a new CORE DUMP, "| /usr/bin/tee -a ${LOG}
                                echo "                          kindly invoke the command:  echo 1 > /proc/sys/kernel/sysrq          "| /usr/bin/tee -a ${LOG}
                                echo "                          Followed by the command:  echo c > /proc/sysrq-trigger          "| /usr/bin/tee -a ${LOG}
                                echo " ------------------" | /usr/bin/tee -a ${LOG}
                                echo " ------------------" | /usr/bin/tee -a ${LOG}
                        else
                                echo " ------------------" | /usr/bin/tee -a ${LOG}
                                echo "$lastcrash"| /usr/bin/tee -a ${LOG}
                                echo ".... Core file is still valid                                                             Pass...."| /usr/bin/tee -a ${LOG}
                                echo " ------------------" | /usr/bin/tee -a ${LOG}
                                echo " ------------------" | /usr/bin/tee -a ${LOG}
                        fi
                else
                        echo "" | /usr/bin/tee -a ${LOG}
                        echo " ------------------" | /usr/bin/tee -a ${LOG}
                        echo " ------------------" | /usr/bin/tee -a ${LOG}
                        echo ".... Core file invalid, not matching                                                      Fail..." | /usr/bin/tee -a ${LOG};
                        echo " ------------------" | /usr/bin/tee -a ${LOG}
                        echo " ------------------" | /usr/bin/tee -a ${LOG}
                        echo "" | /usr/bin/tee -a ${LOG}
                fi
        fi
else
        echo "" | /usr/bin/tee -a ${LOG}
        echo " ------------------" | /usr/bin/tee -a ${LOG}
        echo "....CoreCheck                                                             Fail..." | /usr/bin/tee -a ${LOG};
        echo " ------------------" | /usr/bin/tee -a ${LOG}
        echo "" | /usr/bin/tee -a ${LOG}
        echo "....                      Please generate CORE DUMP, validate config under /etc/kdump.conf                        "| /usr/bin/tee -a ${LOG}
        echo "....                      kindly invoke the command:  echo 1 > /proc/sys/kernel/sysrq                     "| /usr/bin/tee -a ${LOG}
        echo "....                      Followed by the command:  echo c > /proc/sysrq-trigger          "| /usr/bin/tee -a ${LOG}
        echo "" | /usr/bin/tee -a ${LOG}
        echo " ------------------" | /usr/bin/tee -a ${LOG}
        echo " ------------------" | /usr/bin/tee -a ${LOG}
fi
}


#function CheckSub {
#echo "" | /usr/bin/tee -a ${LOG}
#echo " ------------------" | /usr/bin/tee -a ${LOG}
#echo " ------------------" | /usr/bin/tee -a ${LOG}
#echo " ------------------" | /usr/bin/tee -a ${LOG}
#echo " Subscription Check" | /usr/bin/tee -a ${LOG}
#echo " ------------------" | /usr/bin/tee -a ${LOG}
#echo "" | /usr/bin/tee -a ${LOG}
#echo "" | /usr/bin/tee -a ${LOG}
#subs=$(/usr/sbin/subscription-manager list|grep -i Status\:|awk '{print $2}')
#/usr/sbin/subscription-manager list| /usr/bin/tee -a ${LOG}
#if [[ "$subs" != "Subscribed" ]]
#then
#		echo "" | /usr/bin/tee -a ${LOG}
#        echo ".... Server subscription status is showing not subscribed                         Fail...."| /usr/bin/tee -a ${LOG}
#        echo ".... kindly register the server to satellite ...."| /usr/bin/tee -a ${LOG}
#        /usr/sbin/subscription-manager identity| /usr/bin/tee -a ${LOG}
#		echo "" | /usr/bin/tee -a ${LOG}
#else
#		echo "" | /usr/bin/tee -a ${LOG}
#        echo ".... Server subscription status shows Subscribed                  Pass...."| /usr/bin/tee -a ${LOG}
#        /usr/sbin/subscription-manager identity| /usr/bin/tee -a ${LOG}
#		echo "" | /usr/bin/tee -a ${LOG}
#fi
#echo "" | /usr/bin/tee -a ${LOG}
#echo "" | /usr/bin/tee -a ${LOG}
#}

function CheckSub {
echo "" | /usr/bin/tee -a ${LOG}
echo " ------------------" | /usr/bin/tee -a ${LOG}
echo " ------------------" | /usr/bin/tee -a ${LOG}
echo " ------------------" | /usr/bin/tee -a ${LOG}
echo " Subscription Check" | /usr/bin/tee -a ${LOG}
echo " ------------------" | /usr/bin/tee -a ${LOG}
echo "" | /usr/bin/tee -a ${LOG}
echo "" | /usr/bin/tee -a ${LOG}

# Get the number of subscriptions with "Subscribed" status
num_subscribed=$( /usr/sbin/subscription-manager list | grep -i Status: | grep -c Subscribed )

# Get the total number of subscriptions
num_total=$( /usr/sbin/subscription-manager list | grep -i Status: | wc -l )

# Check if all subscriptions are in "Subscribed" status
if [[ $num_subscribed -eq $num_total ]]
then
        echo "" | /usr/bin/tee -a ${LOG}
        echo ".... All server subscriptions show Subscribed                  Pass...."| /usr/bin/tee -a ${LOG}
        /usr/sbin/subscription-manager identity| /usr/bin/tee -a ${LOG}
        echo "" | /usr/bin/tee -a ${LOG}
else
        echo "" | /usr/bin/tee -a ${LOG}
        echo ".... Server subscription status is showing not subscribed                         Fail...."| /usr/bin/tee -a ${LOG}
        echo ".... kindly register the server to satellite ...."| /usr/bin/tee -a ${LOG}
        /usr/sbin/subscription-manager identity| /usr/bin/tee -a ${LOG}
        echo "" | /usr/bin/tee -a ${LOG}
fi

echo "" | /usr/bin/tee -a ${LOG}
echo "" | /usr/bin/tee -a ${LOG}
}

#-------------------------------------------
#-------------------------------------------
#-------------HARDWARE SECTION--------------
#-------------------------------------------
#-------------------------------------------

function CheckBoot {
echo " ------------------" | /usr/bin/tee -a ${LOG}
echo " ------------------" | /usr/bin/tee -a ${LOG}
echo " ------------------" | /usr/bin/tee -a ${LOG}
echo " Check Boot Type  " | /usr/bin/tee -a ${LOG}
echo " ------------------" | /usr/bin/tee -a ${LOG}
lsblk | grep boot
rowt=$(lsblk | grep boot | head -1|awk '{print $1}'|cut -d"-" -f2| cut -b 1-3);

if  [[ "$rowt" == "mpa" && "$rowt" == "dm" ]] #<<<< added dm
then
	echo " ------------------" | /usr/bin/tee -a ${LOG}
	echo " ------------------" | /usr/bin/tee -a ${LOG}
	echo "....server is on SAN boot ...."
	echo " ------------------" | /usr/bin/tee -a ${LOG}
else 
	lspci | grep `ls -l /sys/block/"$rowt" | tr -s ' ' | cut -d" " -f11 | cut -d"/" -f5 | cut -d":" -f2,3` | /usr/bin/tee -a ${LOG}
	type=$(lspci | grep `ls -l /sys/block/"$rowt"  | tr -s ' ' | cut -d" " -f11 | cut -d"/" -f5 | cut -d":" -f2,3`| awk '{print $2}')
	echo " ------------------" | /usr/bin/tee -a ${LOG}
	echo " ------------------" | /usr/bin/tee -a ${LOG}
	echo "....server is on "$type" ...."
	echo " ------------------" | /usr/bin/tee -a ${LOG}
fi
}

function CheckKDUMP_BM {

echo "" | /usr/bin/tee -a ${LOG}
echo " Check Kdump for Bare-Metal " | /usr/bin/tee -a ${LOG}
echo " ----------------" | /usr/bin/tee -a ${LOG}
echo "" | /usr/bin/tee -a ${LOG}

OPERATIONAL=$(systemctl list-units kdump.service | sed $'s|^\(UNIT.*\)|\f\\DESCRIPTION|' | awk 'BEGIN { RS="\f" } /kdump.service loaded/ { print $3 $4}');
        
if [ $OPERATIONAL = loadedactive ]; then
        echo ".... Kdump  Configured.    Pass ...." | /usr/bin/tee -a ${LOG}
else
        echo ".... Kdump NOT Configured.    Fail ...." | /usr/bin/tee -a ${LOG}
fi

mem_check=$(free -g | grep Mem | awk '{print $2}');
ckernel_column=$(awk '{ for (i=1; i<=NF; ++i) { if ($i ~ "crashkernel") print i } }' /etc/default/grub);
ckernel_Value_check=$(grep crashkernel /etc/default/grub|awk '{print $'$ckernel_column'}');

echo "actual memory size(GB): $mem_check" | /usr/bin/tee -a ${LOG};
echo "defined value $ckernel_Value_check" | /usr/bin/tee -a ${LOG};

ckernel_match=$( grep crashkernel /etc/default/grub|awk '{print $'$ckernel_column'}' | cut -d= -f2);
ckernel_match_value=$( grep crashkernel /etc/default/grub|awk '{print $'$ckernel_column'}' | cut -d= -f2 | cut -d M -f1);

if [[ "$ckernel_match" == "auto" ]]; then
        echo "...crash kernel value not set correctly   		Fail ...." | /usr/bin/tee -a ${LOG};
else
        if [[ "$mem_check" -ge 8 ]] && [[ "$ckernel_match_value" -ge 512 ]]; then
                echo "...crash kernel value is set correctly    		Pass ...." | /usr/bin/tee -a ${LOG};
        else
                echo "...please check /etc/default/grub manually			 Fail..." | /usr/bin/tee -a ${LOG};
        fi
fi

echo "" | /usr/bin/tee -a ${LOG}

}

function CheckNET {
echo " ------------------" | /usr/bin/tee -a ${LOG}
echo " ------------------" | /usr/bin/tee -a ${LOG}
echo " ------------------" | /usr/bin/tee -a ${LOG}
echo " Net Interface Check  " | /usr/bin/tee -a ${LOG}
echo " ------------------" | /usr/bin/tee -a ${LOG}
cat /dev/null > /tmp/ifcfg
ls -l /sys/class/net|grep -v total|awk '{print $9}'|grep -v "\ "|grep -v lo >> /tmp/ifcfg | /usr/bin/tee -a ${LOG}
while read line; 
do 
echo "$line" 
ethtool "$line" | grep Link 
link=$(ethtool "$line"| grep Link |awk '{print $3}')
if [[ "$link" = "no" ]]
then
echo ".... ethernet port "$line" is not detected    Fail ...." | /usr/bin/tee -a ${LOG}
else 
echo ".... ethernet port "$line" is detected	Pass ...." | /usr/bin/tee -a ${LOG}
fi;
done < /tmp/ifcfg;

rm -f /tmp/ifcfg
echo " ------------------" | /usr/bin/tee -a ${LOG}
echo "" | /usr/bin/tee -a ${LOG}
}

function CheckTeaming {

echo " ------------------" | /usr/bin/tee -a ${LOG}
echo " ------------------" | /usr/bin/tee -a ${LOG}
echo " ------------------" | /usr/bin/tee -a ${LOG}
echo " Net Teaming Check  " | /usr/bin/tee -a ${LOG}
echo " ------------------" | /usr/bin/tee -a ${LOG}

check=$(ip link show |grep ": team"| head -1 | awk '{print $2}'| cut -d":" -f1| cut -b 1-4)
T=$(ip link show |grep ": team"| head -1 | awk '{print $2}'| cut -d":" -f1)

if [ -n "$check" ]
then
	echo "....Teaming ports...." | /usr/bin/tee -a ${LOG}
	ports=$(teamnl "$T" ports)
	echo "$ports"
	echo " ------------------" | /usr/bin/tee -a ${LOG}
	echo " ------------------" | /usr/bin/tee -a ${LOG}
	portdown=$(echo "$ports" | awk '{print $3}' | grep down)
	if [[ "$portdown" = down ]]
	then 
		pd=$(teamnl team0 ports | grep down|awk '{print $2}'|cut -d: -f1)
		echo ".... port "$pd" is down; Check Status of "$T" interfaces.    		Fail ...." | /usr/bin/tee -a ${LOG}
	else
		echo ".... ports are up; Status of "$T" interfaces Check.    		Pass ...." | /usr/bin/tee -a ${LOG}
	fi
	echo " ------------------"  | /usr/bin/tee -a ${LOG}
	echo " ------------------" | /usr/bin/tee -a ${LOG}
	state=$(teamdctl "$T" state| head -2|grep runner | awk '{print $2}') 
	echo ".... Teaming is under "$state" ...." | /usr/bin/tee -a ${LOG}
	echo " ------------------" | /usr/bin/tee -a ${LOG}
	echo " ------------------" | /usr/bin/tee -a ${LOG}
	for TEAM in `ifconfig -a |grep team|cut -d: -f1|fgrep -v .`
	do 
		COUNT=`teamdctl $TEAM state | grep agg | sort -u | wc -l`
		if [ $COUNT -gt 1 ]
		then
			teamdctl "$T" state |grep agg | sort -u | /usr/bin/tee -a ${LOG}
			echo " ------------------" | /usr/bin/tee -a ${LOG}
			echo " ------------------" | /usr/bin/tee -a ${LOG}
			echo "....$TEAM shows multiple aggregator ID.    		Fail ...." | /usr/bin/tee -a ${LOG}
		else
			teamdctl "$T" state |grep agg | sort -u | /usr/bin/tee -a ${LOG}
			echo " ------------------" | /usr/bin/tee -a ${LOG}
			echo " ------------------" | /usr/bin/tee -a ${LOG}
			echo "....$TEAM aggregator ID is singular    		Pass ...." | /usr/bin/tee -a ${LOG}
		fi
	done
	echo " ------------------" | /usr/bin/tee -a ${LOG}
else
	echo " ------------------" | /usr/bin/tee -a ${LOG}
	echo "....Teaming not setup ...." | /usr/bin/tee -a ${LOG}
	echo " ------------------" | /usr/bin/tee -a ${LOG}
fi
}

function CheckBonding {
echo " ------------------" | /usr/bin/tee -a ${LOG}
echo " ------------------" | /usr/bin/tee -a ${LOG}
echo " ------------------" | /usr/bin/tee -a ${LOG}
echo " Net Bonding Check  " | /usr/bin/tee -a ${LOG}
echo " ------------------" | /usr/bin/tee -a ${LOG}

if [ -n "$(ls -A /proc/net/bonding/)" ]
then
ls -l /proc/net/bonding/bond[0-9] | awk '{print $9}' > /tmp/B
while read line
do 
echo " ------------------" | /usr/bin/tee -a ${LOG}
echo "$line" | cut -d"/" -f5
cat "$line" | grep -i interface
echo " ------------------" | /usr/bin/tee -a ${LOG}
done < /tmp/B
echo " ------------------" | /usr/bin/tee -a ${LOG}
rm -f /tmp/B
else
	echo " ------------------" | /usr/bin/tee -a ${LOG}
	echo " ------------------" | /usr/bin/tee -a ${LOG}
	echo "....Bonding not setup ...."
	echo " ------------------" | /usr/bin/tee -a ${LOG}
fi
}

function Check_Tools {
echo " ------------------" | /usr/bin/tee -a ${LOG}
echo " ------------------" | /usr/bin/tee -a ${LOG}
echo " Systool Check " | /usr/bin/tee -a ${LOG}
echo " ------------------" | /usr/bin/tee -a ${LOG}
echo " ------------------" | /usr/bin/tee -a ${LOG}
echo "" | /usr/bin/tee -a ${LOG}
if [ -n "$(rpm -qa |grep sysfsutils)" ]
then 
	echo "" | /usr/bin/tee -a ${LOG}
	rpm -qa |grep sysfsutils  | /usr/bin/tee -a ${LOG}
	echo "....Systool is installed 			PASS ...."  | /usr/bin/tee -a ${LOG}
	echo "" | /usr/bin/tee -a ${LOG}
	echo "" | /usr/bin/tee -a ${LOG}
else 
	echo "" | /usr/bin/tee -a ${LOG}
	echo "....Systool is not installed		FAIL ...."  | /usr/bin/tee -a ${LOG}
	echo "....please install sysfsutils	...."  | /usr/bin/tee -a ${LOG}
	echo "" | /usr/bin/tee -a ${LOG}
	echo "" | /usr/bin/tee -a ${LOG}
fi
if [[ $(rpm -qa |grep 'sysstat') = sysstat* ]];
then
	echo "" | /usr/bin/tee -a ${LOG}
	rpm -qa |grep sysstat 
	echo "....sysstat is installed 			PASS ...."  | /usr/bin/tee -a ${LOG}
	echo " ------------------" | /usr/bin/tee -a ${LOG} 
	else 
	echo "" | /usr/bin/tee -a ${LOG}
	echo "....sysstat is not installed		FAIL ...."  | /usr/bin/tee -a ${LOG}
	echo "....please install sysfsutils	...."  | /usr/bin/tee -a ${LOG}
	echo " ------------------" | /usr/bin/tee -a ${LOG}
fi
}

function Check_FC { 
echo " ------------------" | /usr/bin/tee -a ${LOG}
echo " ------------------" | /usr/bin/tee -a ${LOG}
echo " FC Check " | /usr/bin/tee -a ${LOG}
echo " ------------------" | /usr/bin/tee -a ${LOG}
echo " ------------------" | /usr/bin/tee -a ${LOG}
echo "Listing installed FC host adapter" | /usr/bin/tee -a ${LOG}
echo " ------------------" | /usr/bin/tee -a ${LOG}
echo "" | /usr/bin/tee -a ${LOG}
lspci |egrep -i 'fiber|fibre|hba' | /usr/bin/tee -a ${LOG}
echo " ------------------" | /usr/bin/tee -a ${LOG}
echo "Confirming Active Fiber channels" | /usr/bin/tee -a ${LOG}
systool -c fc_host -v | egrep 'Class\ Device\ \=\ \"host|port_name|port_state'  | /usr/bin/tee -a ${LOG}
echo " ------------------" | /usr/bin/tee -a ${LOG}
echo " ------------------" | /usr/bin/tee -a ${LOG}
ST=`systool -c fc_host -v | grep port_state|egrep -i 'error|unknown'|awk '{print $3}'` 
if [[ ! -z "$ST" ]]
then 
echo "....Error or an Unknown FC Host is showing		FAIL ...."  | /usr/bin/tee -a ${LOG}
echo " ------------------" | /usr/bin/tee -a ${LOG}
fi
}

function Check_HBA_MPATH {

/usr/sbin/dmidecode -t system|grep 'Manufacturer\|Product' |grep VMware | /usr/bin/tee -a ${LOG}

if [ `echo $?` == 0 ]
then
CheckHBA_CARD_ON_DIFF_PORT
CheckHBA_MULTI_PATH
else
echo "            Machine is: Virtual" | /usr/bin/tee -a ${LOG}
fi
}

function CheckHBA_CARD_ON_DIFF_PORT {

echo "" | /usr/bin/tee -a ${LOG}
echo " Dual HBA Card on Different I/O Chassis " | /usr/bin/tee -a ${LOG}
echo " --------------------------------------" | /usr/bin/tee -a ${LOG}
echo "" | /usr/bin/tee -a ${LOG}

lsscsi | egrep "HSV|3PAR|EMC" >/dev/null
if [ $? = 0 ]; then

#num_of_HBA=`lsscsi -k | egrep "3PAR|HSV|EMC" | awk '{print $1}' | cut -c 2 | sort | uniq |wc -l`
num_of_HBA=`lsscsi -k | egrep "3PAR|HSV|EMC" | awk '{print $1}' | cut -d[ -f2 |cut -d: -f1|sort|uniq|wc -l`
        if [ $num_of_HBA = 2 ]; then
                        echo "....  HBA Cards are on Different I/O.   Pass ...."| /usr/bin/tee -a ${LOG}
                else
                        echo ".... HBA Cards are NOT on Different I/O.   Fail ...."| /usr/bin/tee -a ${LOG}
        fi
else
                        echo ".... HBA Cards Not Installed.   Info ...."| /usr/bin/tee -a ${LOG}
fi

echo "" | /usr/bin/tee -a ${LOG}

}

function CheckHBA_MULTI_PATH {

echo "" | /usr/bin/tee -a ${LOG}
echo " Multipath Information for SAN Disks " | /usr/bin/tee -a ${LOG}
echo " -----------------------------------" | /usr/bin/tee -a ${LOG}
echo "" | /usr/bin/tee -a ${LOG}

lsscsi | egrep "HSV|3PAR|EMC" >/dev/null

if [ $? = 0 ]; then
	for i in `multipath -ll | grep dm- |awk '{print $1}'`
		do 
		   number_path=`multipath -ll $i | grep active |grep -v policy |cut -d: -f1|cut -d" " -f4| sort |uniq |wc -l `
			if [ $number_path -gt 1 ]; then
			   echo ".... Disk $i has $number_path Path.    Pass ...." | /usr/bin/tee -a ${LOG}
			else
			   echo ".... Disk $i has $number_path Path.    Fail ...." | /usr/bin/tee -a ${LOG}
			fi
		done
else
	echo ".... HBA Cards Not Installed.   Info ...." | /usr/bin/tee -a ${LOG}
fi

echo "" | /usr/bin/tee -a ${LOG}

}

function CheckClus {
echo "" | /usr/bin/tee -a ${LOG}
echo " Check Clustering " | /usr/bin/tee -a ${LOG}
echo " -----------------------------------" | /usr/bin/tee -a ${LOG}
echo "" | /usr/bin/tee -a ${LOG}
clustat=$(ps -ef|grep modclusterd | grep -v grep|awk '{print $8}')
pacemaker=$(ps -ef|grep pacemakerd | grep -v grep|awk '{print $8}'|cut -d"/" -f4)
had=$(ps -ef|grep -w had |grep -v grep| awk '{print $8}'|cut -d "/" -f5)

cluster=$(echo "$clustat""$pacemaker""$had")
case $cluster in
        modclusterd) echo "....cluster rhel cluster is configured Pass ...." | /usr/bin/tee -a ${LOG}
				stat=$(clustat |egrep -i 'offline|failed')
				if [ -n "$stat" ]
				then 
					echo "....there is an offline node or failed service on the cluster 	Fail...." | /usr/bin/tee -a ${LOG}
					echo "$stat" | /usr/bin/tee -a ${LOG}
				else 
					"....Nodes are online 			Pass...." | /usr/bin/tee -a ${LOG}
				fi;;
        pacemakerd) echo "....cluster pacemaker is configured Pass ...." | /usr/bin/tee -a ${LOG}
                stat=$(pcs status|grep -i offline)
                if [ -n "$stat" ]
                then
                        pcs status | head -13|tail -5|head -3|tail -2
                        off=$(pcs status |grep -i offline | awk '{print $3}')
                        echo "....Node is offline "$off"                Fail...." | /usr/bin/tee -a ${LOG}
                else
                        pcs status | head -13|tail -5|head -3|tail -2
                        echo "....Nodes are online              Pass...." | /usr/bin/tee -a ${LOG}
                fi;;
        had)echo "....HA cluster is configured Pass ...." | /usr/bin/tee -a ${LOG}
				stat=$(/opt/VRTS/bin/hasys -state |egrep -i 'stopped | offline| exited')
				if [ -n "$stat" ]
				then 
						echo "$stat" | /usr/bin/tee -a ${LOG}
						echo "....there is a System State that is offline/faulty		Fail...." | /usr/bin/tee -a ${LOG}
				else
						/opt/VRTS/bin/hasys -state 
						echo "....Nodes are online              Pass...." | /usr/bin/tee -a ${LOG}
				fi;;
        *) echo ".... server is not clustered Pass ..." | /usr/bin/tee -a ${LOG};;
esac
}

function BMTools {
echo "" | /usr/bin/tee -a ${LOG}
echo "" | /usr/bin/tee -a ${LOG}
echo "" | /usr/bin/tee -a ${LOG}
echo "  BareMetal Check  " | /usr/bin/tee -a ${LOG}
echo " ------------------" | /usr/bin/tee -a ${LOG}
echo "" | /usr/bin/tee -a ${LOG}
BM=$(/usr/sbin/dmidecode -t system|grep 'Manufacturer'| awk '{print $2}' | cut -d "," -f1)

HL=$(/opt/dell/srvadmin/sbin/racadm getconfig -g ifcRacManagedNodeOs|grep ifcRacMnOsHostname|cut -d= -f2)
HH=$(/opt/dell/srvadmin/sbin/racadm get system.ServerOS.HostName|grep -i hostname|cut -d= -f2)
Lvers=$(/opt/dell/srvadmin/sbin/racadm getversion|grep -i Lifecycle|awk '{print $5}')
version="4.40.00.00"

case $BM in
	Dell) if [ -f /opt/dell/srvadmin/sbin/racadm ]; 
		then
			echo " " | /usr/bin/tee -a ${LOG}
			echo ".... RACADM is installed	              	  Pass...." | /usr/bin/tee -a ${LOG}
			bios=$(/usr/sbin/dmidecode|grep -i bios\ revision|awk '{print $3}')
			if [[ "$bios" = "2.15" ]]
			then
				echo ".... Dell iDRAC versions are up to date	              	  Pass...."  | /usr/bin/tee -a ${LOG}
				echo " " | /usr/bin/tee -a ${LOG}
			else
				echo " " | /usr/bin/tee -a ${LOG}
				echo ".... please update iDRAC FW/BIOS/Driver versions to latest		                Fail...." | /usr/bin/tee -a ${LOG}
				echo " " | /usr/bin/tee -a ${LOG}
			fi
			if [[ $Lvers > $version ]]
			then
				if [[ `hostname --short` == $HH ]]
				then
					echo " ------------------" | /usr/bin/tee -a ${LOG}
					echo ".... iDRAC Hostname is set correctly	              	  Pass...."  | /usr/bin/tee -a ${LOG}
					echo "" | /usr/bin/tee -a ${LOG}
				else
					echo " ------------------" | /usr/bin/tee -a ${LOG}
					echo ".... kindly set iDRAC Hostname to Server Hostname		                Fail...." | /usr/bin/tee -a ${LOG}
					echo "" | /usr/bin/tee -a ${LOG}
				fi
			else
				if [[ `hostname --short` == $HL ]]
				then
					echo " ------------------" | /usr/bin/tee -a ${LOG}
					echo "iDRAC Hostname is set correctly	              	  Pass...."  | /usr/bin/tee -a ${LOG}
					echo "" | /usr/bin/tee -a ${LOG}
				else
					echo " ------------------" | /usr/bin/tee -a ${LOG}
					echo "kindly set iDRAC Hostname to Server Hostname		                Fail...." | /usr/bin/tee -a ${LOG}
					echo "" | /usr/bin/tee -a ${LOG}
				fi
			fi			
		else 
			echo " " | /usr/bin/tee -a ${LOG}
			echo ".... please install RACADM tools									                Fail...." | /usr/bin/tee -a ${LOG}
			echo ".... execute wget http://cbmcclr174i.ca.cibcwm.com/ks/software/DELL/DellEMC-iDRACTools-Web-LX-9.3.1-3669_A00.tar.gz" | /usr/bin/tee -a ${LOG}
			echo ".... extract and install manually inside the server"  | /usr/bin/tee -a ${LOG}
			echo " " | /usr/bin/tee -a ${LOG}
		fi;;
	HP) if [ -f /sbin/hponcfg ];
		then
			echo " " | /usr/bin/tee -a ${LOG}
			echo ".... HPONCFG is installed							                Pass...."  | /usr/bin/tee -a ${LOG}
		else
			echo " " | /usr/bin/tee -a ${LOG}
			echo ".... please install hponcfg tools									                Fail...." | /usr/bin/tee -a ${LOG}
			echo ".... execute wget http://cbmcclr174i.ca.cibcwm.com/ks/software/HP/hponcfg/hponcfg-4.6.0-0.x86_64.zip" | /usr/bin/tee -a ${LOG}
			echo ".... extract and install manually inside the server" | /usr/bin/tee -a ${LOG}
			echo " " | /usr/bin/tee -a ${LOG}
		fi
		if [ -f /sbin/hpssacli ];
		then
			echo ".... HPSSACLI is installed							                Pass...." 
		else
			echo " " | /usr/bin/tee -a ${LOG}
			echo ".... please install hpssacli tools									                Fail...." | /usr/bin/tee -a ${LOG}
			echo ".... execute wget http://cbmcclr174i.ca.cibcwm.com/ks/software/HP/tools_hp/hpssacli-2.40-13.0.x86_64.rpm" | /usr/bin/tee -a ${LOG}
			echo ".... extract and install manually inside the server" | /usr/bin/tee -a ${LOG}
			echo " " | /usr/bin/tee -a ${LOG}
		fi
		if [ -f /sbin/hpasmcli ];
		then
			echo ".... HPASMCLI is installed							                Pass...."  | /usr/bin/tee -a ${LOG}
		else
			echo " " | /usr/bin/tee -a ${LOG}
			echo ".... please install hpasmcli tools									                Fail...." | /usr/bin/tee -a ${LOG}
			echo ".... execute wget http://cbmcclr174i.ca.cibcwm.com/ks/software/HP/tools_hp/hp-health-10.90-1873.8.rhel7.x86_64.rpm" | /usr/bin/tee -a ${LOG}
			echo ".... extract and install manually inside the server" | /usr/bin/tee -a ${LOG}
			echo " " | /usr/bin/tee -a ${LOG}
		fi;;
	*)	echo ".... server is not physical, kindly validate or contact RUN Config lead              Fail...." | /usr/bin/tee -a ${LOG}
		echo " " | /usr/bin/tee -a ${LOG};;
esac
}

function CheckLoopbackMTU {

echo "" | /usr/bin/tee -a ${LOG}
echo "" | /usr/bin/tee -a ${LOG}
echo "" | /usr/bin/tee -a ${LOG}
echo "  MTU Check  " | /usr/bin/tee -a ${LOG}
echo " ------------------" | /usr/bin/tee -a ${LOG}
echo "" | /usr/bin/tee -a ${LOG}

  if ps -ef | grep [o]ra_pmon; then
    mtu=$(ifconfig lo | grep -i "MTU" | awk '{print $4}')
    mtu_setting=$(grep -i "MTU" /etc/sysconfig/network-scripts/ifcfg-lo | awk -F "=" '{print $2}')
    echo "" | /usr/bin/tee -a ${LOG}
    echo " Loopback MTU Check  " | /usr/bin/tee -a ${LOG}
    echo " ------------------" | /usr/bin/tee -a ${LOG}
    echo "" | /usr/bin/tee -a ${LOG}
    if [ "$mtu" -eq 16384 ]; then
      echo ".... Loopback MTU is set to 16384    Pass ...." | /usr/bin/tee -a ${LOG}
    else
      echo ".... Loopback MTU is not set to 16384    Fail ...." | /usr/bin/tee -a ${LOG}
    fi
    echo " ------------------" | /usr/bin/tee -a ${LOG}
    echo "" | /usr/bin/tee -a ${LOG}
    if [ -z "$mtu_setting" ] || [ "$mtu_setting" -ne 16384  ]; then
      echo ".... MTU is not set to 16384 in ifcfg-lo    Fail ...." | /usr/bin/tee -a ${LOG}
    else
      echo ".... MTU is set to $mtu_setting in ifcfg-lo    Pass ...." | /usr/bin/tee -a ${LOG}
    fi
    echo " ------------------" | /usr/bin/tee -a ${LOG}
    echo "" | /usr/bin/tee -a ${LOG}
    echo "Oracle processes found. This is a database server." | /usr/bin/tee -a ${LOG}
  else
    echo "No Oracle processes found. This is a non-database server." | /usr/bin/tee -a ${LOG}
  fi
}

checkLDAP() {

echo " " | /usr/bin/tee -a ${LOG}
echo " " | /usr/bin/tee -a ${LOG}
echo " ------------------" | /usr/bin/tee -a ${LOG}
echo " Check LDAP Server  " | /usr/bin/tee -a ${LOG}
echo " ------------------" | /usr/bin/tee -a ${LOG}

envi=$(cat /etc/CIBC/setenv.done)
ldap_uri=$(grep ldap_uri /etc/sssd/sssd.conf | sed 's/ldap:\/\/\|ldaps:\/\///' | awk '{print $3}' | tr -d '/')
if [ -s /etc/CIBC/setenv.done ] && [ -f /etc/CIBC/setenv.done ]; then
  case $envi in
      d)
          if [ "$ldap_uri" == "ptevds.cibc.com" ]; then
              echo "Server environment is DEV and it is using $ldap_uri. ....PASS" | /usr/bin/tee -a "${LOG}"
          else
              echo "Server environment is DEV, but ldap server is $ldap_uri. It should be ptevds.cibc.com. ....FAIL" | /usr/bin/tee -a "${LOG}"
              echo "Please check server environment in ESL and SNOW and fix ldap configuration." | /usr/bin/tee -a "${LOG}"
          fi
          ;;
      u)
          if [ "$ldap_uri" == "ptevds.cibc.com" ]; then
              echo "Server environment is UAT and it is using $ldap_uri. ....PASS" | /usr/bin/tee -a "${LOG}"
          else
              echo "Server environment is UAT, but ldap server is $ldap_uri. It should be should be ptevds.cibc.com. ....FAIL" | /usr/bin/tee -a "${LOG}"
              echo "Please check server environment in ESL and SNOW and fix ldap configuration." | /usr/bin/tee -a "${LOG}"
          fi
          ;;
      b)
          if [ "$ldap_uri" == "vds.cibc.com" ]; then
              echo "Server environment is DR and it is using $ldap_uri. ....PASS" | /usr/bin/tee -a "${LOG}"
          else
              echo "Server environment is DR, but ldap server is $ldap_uri. It should be vds.cibc.com. ....FAIL" | /usr/bin/tee -a "${LOG}"
              echo "Please check server environment in ESL and SNOW and fix ldap configuration." | /usr/bin/tee -a "${LOG}"
          fi
          ;;
      p)
          if [ "$ldap_uri" == "vds.cibc.com" ]; then
              echo "Server environment is PROD and it is using $ldap_uri. ....PASS" | /usr/bin/tee -a "${LOG}"
          else
              echo "Server environment is PROD, but ldap server is $ldap_uri. It should be vds.cibc.com. ....FAIL" | /usr/bin/tee -a "${LOG}"
              echo "Please check server environment in ESL and SNOW and fix ldap configuration." | /usr/bin/tee -a "${LOG}"
          fi
          ;;
  esac
else
    echo "/etc/CIBC/setenv.done file does not exists"
        exit 1
fi
}

checkHOSTNAME() {

echo " " | /usr/bin/tee -a ${LOG}
echo " " | /usr/bin/tee -a ${LOG}
echo " ------------------" | /usr/bin/tee -a ${LOG}
echo " Check Hostname Alias" | /usr/bin/tee -a ${LOG}
echo " ------------------" | /usr/bin/tee -a ${LOG}

  if [ -f /usr/local/bin/hostname ] && grep -q "hostname -f" /usr/local/bin/hostname; then
        echo "File /usr/local/bin/hostname found and hostname alias found. ....PASS" | /usr/bin/tee -a ${LOG}
  else

        echo "File /usr/local/bin/hostname and hostname alias not found. Please check. ......FAIL" | /usr/bin/tee -a ${LOG}
  fi

}


function QA_END {

echo "" | /usr/bin/tee -a ${LOG}
echo "................Ending the QA......"  | /usr/bin/tee -a ${LOG}
echo "" | /usr/bin/tee -a ${LOG}
echo " ------------------------------------------" | /usr/bin/tee -a ${LOG}   
  
}

QA_Start
QA_END