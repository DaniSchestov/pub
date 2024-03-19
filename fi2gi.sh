#!/bin/bash
giversion="1.7.1"
#Check if FI Agent is installed
if [ -f /etc/fusioninventory/agent.cfg ]
then
    fitag=$(awk '/^[Tt]ag = /{print $3}' /etc/fusioninventory/agent.cfg)
    echo $fitag
    apt purge fusioninventory* -y
    else
    echo "No FI Agent installed"
fi
if [ ! -f /etc/glpi-agent/agent.cfg ] && [ ! -f /etc/glpi-agent/conf.d/00-install.cfg ]
then
    apt install -y wget
    wget "https://github.com/glpi-project/glpi-agent/releases/download/$giversion/glpi-agent-$giversion-linux-installer.pl" -O /tmp/glpi-agent-$giversion-linux-installer.pl
    perl /tmp/glpi-agent-$giversion-linux-installer.pl --server="https://glpi.osrc.it/plugins/fusioninventory/,https://glpi.osrc.it/plugins/glpiinventory/" --tag=$fitag --service --install --runnow
    rm /tmp/glpi-agent-$giversion-linux-installer.pl
else
    echo "GLPI Agent is already installed"
fi
