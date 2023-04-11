#!/bin/sh
#### Your default SSH Port (Can also be used for FTP)
## SSH_IPS="000.000.0.0/16,000.000.000.0/24,000.000.000.0/32"
SSH_PORT="22"
#### Your GameServer Ports (This will take care of RCON Blocks and Invalid Packets.
GAMESERVERPORT="27015"
# DNS - mude para o DNS do seu HOST
DNS="200.98.20.0/24,200.221.11.0/24,200.98.119.253" 
VALVE_IPS="80.239.194.0/24,207.35.48.0/24,72.165.61.0/24,208.64.201.0/24,162.254.0.0/16,208.78.164.0/24,205.185.194.0/24,155.133.250.0/24,208.64.200.0/24,4.28.130.0/24,208.64.200.0/24,155.133.249.0/24,205.185.194.0/24,62.115.0.0/16,50.242.151.0/24,205.196.6.0/24,208.64.203.0/24,146.66.154.0/24"
## Cleanup Rules First!
##--------------------
iptables -P INPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT
iptables -F
iptables -X
iptables -t nat -F
iptables -t nat -X
iptables -t mangle -F
iptables -t mangle -X
##--------------------
## Policies
##--------------------
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT DROP
##--------------------
## Create Filters
##---------------------
iptables -N LOG_DROP_INPUT
iptables -N LOG_DROP_OUTPUT
iptables -N LOG_DROP_FORWARD
##---------------------
#### Allow Self
iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT
#### Block Fragmented Packets
#### Keep in mind that if your Linux Server acts as a router that this can affect a few things badly, I'd suggest removing/commenting this out if this is the case.
iptables -A INPUT -f -j DROP
#### Block ICMP/Pinging
iptables -A INPUT -p icmp -j DROP
#### Accept Established Connections
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A OUTPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
# Explicitly drop invalid incoming traffic
iptables -A INPUT -m state --state INVALID -j DROP
iptables -A OUTPUT -m state --state INVALID -j DROP
iptables -A FORWARD -m state --state INVALID -j DROP
#### Block Malformed/Null TCP Packets while forcing new connections to be SYN Packets
iptables -A INPUT -p tcp ! --syn -m state --state NEW -j DROP
iptables -A INPUT -p tcp --tcp-flags ALL ALL -j DROP
iptables -A INPUT -p tcp --tcp-flags ALL NONE -j DROP
#### HLDS
#iptables -A INPUT -p udp --dport 27015 -m multiport --sports 1024:1899,1901:2061,2063:3088,3090:5352,5354:7129,7131:9986,9988:27014,27016:27689,27691:65535 -m state --state NEW -m hashlimit --hashlimit-upto 1/sec --hashlimit-burst 3 --hashlimit-mode srcip,dstport --hashlimit-name UDPDOSPROTECT --hashlimit-htable-expire 60000 --hashlimit-htable-max 999999999 -m length --length 28:150 -m ttl --ttl-lt 200 -j ACCEPT
iptables -A INPUT -p udp --dport 27015 -m multiport --sports 1024:1899,1901:2061,2063:3088,3090:5352,5354:7129,7131:27014,27016:65535 -m state --state NEW -m hashlimit --hashlimit-upto 1/sec --hashlimit-burst 3 --hashlimit-mode srcip,dstport --hashlimit-name UDPDOSPROTECT --hashlimit-htable-expire 60000 --hashlimit-htable-max 999999999 -m length --length 28:150 -m ttl --ttl-lt 200 -j ACCEPT
iptables -A OUTPUT -p udp -m udp --sport 53:65535 --dport 53 -d $DNS -j ACCEPT
iptables -A OUTPUT -p udp -m udp --sport 53:65535 --dport 67 -d $DNS -j ACCEPT
iptables -A INPUT -p udp -m udp --sport 53:65535 --dport 68 -s $DNS -j ACCEPT
iptables -A OUTPUT -p tcp -m multiport --dports 80,443 -j ACCEPT
iptables -A INPUT -p tcp -s 131.0.0.0/8,132.0.0.0/8,138.0.0.0/8,143.0.0.0/8,152.0.0.0/8,168.0.0.0/8,177.0.0.0/8,179.0.0.0/8,186.0.0.0/8,187.0.0.0/8,189.0.0.0/8,190.0.0.0/8,191.0.0.0/8,192.0.0.0/8,200.0.0.0/8,201.0.0.0/8 --dport 21 -m state --state NEW,ESTABLISHED -m hashlimit --hashlimit-upto 1/sec --hashlimit-burst 20 --hashlimit-mode srcip,dstport --hashlimit-name SSHPROTECT --hashlimit-htable-expire 60000 --hashlimit-htable-max 999999999 -j ACCEPT
iptables -A OUTPUT -p tcp --sport 20 -j ACCEPT
iptables -A OUTPUT -p udp -m udp --sport 1024:65535 --dport 27017:27021 -d $VALVE_IPS -m length --length 28:150 -j ACCEPT
iptables -A INPUT -p udp -m udp --sport 27017:27021 --dport 26900 -d $VALVE_IPS -m length --length 28:150 -j ACCEPT
#### SSH com seus IPs
# iptables -A INPUT -s $SSH_IPS -p tcp --dport $SSH_PORT -m state --state NEW,ESTABLISHED -m hashlimit --hashlimit-upto 1/sec --hashlimit-burst 20 --hashlimit-mode srcip,dstport --hashlimit-name SSHPROTECT --hashlimit-htable-expire 60000 --hashlimit-htable-max 999999999 -j ACCEPT 
# iptables -A OUTPUT -s $SSH_IPS -p tcp --sport $SSH_PORT -m state --state ESTABLISHED -j ACCEPT
iptables -A INPUT -p tcp --dport $SSH_PORT -m state --state NEW,ESTABLISHED -m hashlimit --hashlimit-upto 1/sec --hashlimit-burst 20 --hashlimit-mode srcip,dstport --hashlimit-name SSHPROTECT --hashlimit-htable-expire 60000 --hashlimit-htable-max 999999999 -j ACCEPT 
iptables -A OUTPUT -p tcp --sport $SSH_PORT -m state --state ESTABLISHED -j ACCEPT
# DROP LOGS
iptables -A INPUT -j LOG_DROP_INPUT
iptables -A LOG_DROP_INPUT -m limit --limit 10/min -j LOG --log-prefix "iptables DROP INPUT: " --log-level 7
iptables -A LOG_DROP_INPUT -j DROP
iptables -A OUTPUT -j LOG_DROP_OUTPUT
iptables -A LOG_DROP_OUTPUT -m limit --limit 10/min -j LOG --log-prefix "iptables DROP OUT: " --log-level 7
iptables -A LOG_DROP_OUTPUT -j DROP
iptables -A OUTPUT -j LOG_DROP_FORWARD
iptables -A LOG_DROP_FORWARD -m limit --limit 10/min -j LOG --log-prefix "iptables DROP FORWARD: " --log-level 7
iptables -A LOG_DROP_FORWARD -j DROP
############ EXTRA STUFF TO HELP HIGH TRAFFIC (DDOS) ##################
############### Make sure this Script is executed at Startup! #########
#######################################################################
echo "20000" > /proc/sys/net/ipv4/tcp_max_syn_backlog
echo "1" > /proc/sys/net/ipv4/tcp_synack_retries
echo "30" > /proc/sys/net/ipv4/tcp_fin_timeout
echo "5" > /proc/sys/net/ipv4/tcp_keepalive_probes
echo "15" > /proc/sys/net/ipv4/tcp_keepalive_intvl
echo "20000" > /proc/sys/net/core/netdev_max_backlog
echo "20000" > /proc/sys/net/core/somaxconn
echo "99999999" > /proc/sys/net/nf_conntrack_max
