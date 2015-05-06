#!/bin/bash
# This script creates the timesequence, throughput, inflight and delay graphs
# in a folder named as the kernel version where you execute it.
# For the simulation taking the pcap file as argument by using both tcptrace and captcp tools
# This script assumes only one TCP flow going from sender -> receiver. 

if [ "$#" -ne 1 ]; 
then
	echo "Usage: $ ./graph_generator.sh <pcapfile>"
	exit -1
fi

if [[ ! -f /usr/bin/captcp ]]; then
	echo "Error: install captcp"
	echo "http://research.protocollabs.com/captcp/"
	exit -1
fi

if [[ ! -f /usr/bin/xpl2gpl ]]; then
	echo "Error: install xpl2gpl"
	echo "http://www.tcptrace.org/xpl2gpl/"
	exit -1
fi

if [[ ! -f /usr/bin/tcptrace ]]; then
	echo "Error: install tcptrace"
	echo "http://www.tcptrace.org"
	exit -1
fi

pcapfile=$1
dirname="graphs"
tsg="tsg"      # Time Sequence
tput="tput"    # Throughput
rtt="rtt"      # RTT
owin="owin"    # Outstanding data
ssize="ssize"  # Segment Size
tline="tline"  # Time Line

#Remove directory if already exists
echo "[->] Removing all older data"
rm -rf $dirname

#Create the output directories
mkdir -p $dirname 2>/dev/null
mkdir -p $dirname"/captcp/"$tsg
mkdir -p $dirname"/captcp/"$tput
mkdir -p $dirname"/captcp/"$owin

mkdir -p $dirname"/tcptrace/"$tsg
mkdir -p $dirname"/tcptrace/"$tput
mkdir -p $dirname"/tcptrace/"$owin
mkdir -p $dirname"/tcptrace/"$rtt
mkdir -p $dirname"/tcptrace/"$ssize
mkdir -p $dirname"/tcptrace/"$tline


#Copy the pcap file to the directory in case of later analysis
if [ -f $pcapfile ];
then
	cp $pcapfile $dirname
fi

#Captcp statistic output 
echo "[->] Generating captcp statistics file"
captcp statistic $pcapfile > $dirname"/captcp/statistics" 2>/dev/null

#Create Time Sequence graph with captcp
echo "[->] Generating Time Sequence Graph with captcp"
captcp timesequence -f 1.1 -o $dirname"/captcp/"$tsg -i -e $pcapfile &>/dev/null
 
#Create Throughput graph with captcp
echo "[->] Generating Throughput Graph with captcp"
captcp throughput -f 1.1 -u kilobyte -i -o $dirname"/captcp/"$tput $pcapfile &>/dev/null

#Create the Inflight graph with captcp
echo "[->] Generating Inflight Data Graph (owin) with captcp"
captcp inflight -f 1.1 -i -o $dirname"/captcp/"$owin $pcapfile &>/dev/null

#Tcptrace statistics output
echo "[->] Generating tcptrace statistics file"
tcptrace -l $pcapfile > $dirname"/tcptrace/statistics" 2>/dev/null

#Tcptrace generating all graphs
echo "[->] Generating all tcptrace graphs in xplot format"
echo -e "\tTime Sequence"
echo -e "\tTroughput"
echo -e "\tInflight data (owin)"
echo -e "\tRTT"
echo -e "\tSegment Size"
echo -e "\tTime Line"
tcptrace -G $pcapfile &>/dev/null

#Remove b2a flows because not interested.
echo "[->] Removing b2a files"
rm b2a_*

#Move every tcp xplot file to its tcptrace folder
mv a2b_owin.xpl $dirname"/tcptrace/"$owin
mv a2b_rtt.xpl $dirname"/tcptrace/"$rtt
mv a2b_ssize.xpl $dirname"/tcptrace/"$ssize
mv a2b_tput.xpl $dirname"/tcptrace/"$tput
mv a2b_tsg.xpl $dirname"/tcptrace/"$tsg
mv a_b_tline.xpl $dirname"/tcptrace/"$tline

#Generate the gnuplot data and files in every tcptrace folder
echo "[->] Generating gnuplot data and script files from xplot files"
tracedir=$dirname"/tcptrace/"
for i in `ls $tracedir`
do
	if [[ -d $tracedir$i ]];
	then
		cd $tracedir$i
		xpl2gpl *.xpl &>/dev/null
		cd - &>/dev/null
	fi
done




