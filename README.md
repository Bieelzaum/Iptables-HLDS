# Iptables HLDS

Essa config bloqueia entrada e saída, libera apenas a porta UDP 27015 com um pedido por segundo, você pode aumentar isso em hashlimit-upto

Execute o iptables.sh: ./iptables.sh

Depois salve: service iptables save

Instale o rsyslog

Edite o arquivo rsyslog.conf em /etc

Adicione:

># kern.debug                        /var/log/firewall.log

:msg,startswith,"iptables" -/var/log/iptables.log

& ~

service rsyslog restart

Veja os logs na pasta /var/log/iptables.log
