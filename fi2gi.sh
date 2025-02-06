if [[ $(getconf LONG_BIT) == "64" ]]
    then
        giversion=$(curl 'https://github.com/glpi-project/glpi-agent/releases/latest' -si | sed -n '/^location.*/ s#.*/##1p' | sed 's/\r//')
        echo "GLPI Agent actual version "$giversion
    else
        giversion="1.7.3"
fi

#functions 
compare-versions()
{
    if [[ $1 == $2 ]]; then
        return 0
    fi
    local IFS=.
    # Everything after the first character not in [^0-9.] is compared
    local i a=(${1%%[^0-9.]*}) b=(${2%%[^0-9.]*})
    local arem=${1#${1%%[^0-9.]*}} brem=${2#${2%%[^0-9.]*}}
    for ((i=0; i<${#a[@]} || i<${#b[@]}; i++)); do
        if ((10#${a[i]:-0} < 10#${b[i]:-0})); then
            echo $1 '<' $2
            return 2
        elif ((10#${a[i]:-0} > 10#${b[i]:-0})); then
            echo $1 '>' $2
            return 1
        fi
    done
    if [ "$arem" '<' "$brem" ]; then
        return 2
    elif [ "$arem" '>' "$brem" ]; then
        return 1
    fi
    return 0
}

install-glpi-agent()
{
    gitag=$1
    apt install -y wget
    wget "https://github.com/glpi-project/glpi-agent/releases/download/$giversion/glpi-agent-$giversion-linux-installer.pl" -O /tmp/glpi-agent-$giversion-linux-installer.pl
    perl /tmp/glpi-agent-$giversion-linux-installer.pl --server="https://glpi.osrc.it/plugins/fusioninventory/,https://glpi.osrc.it/plugins/glpiinventory/" --tag=$gitag --type=all --service --install --runnow
    rm /tmp/glpi-agent-$giversion-linux-installer.pl
    echo "GLPI Agent $givershion installed"

}

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
    install-glpi-agent $fitag
else
    echo "Checking GLPI Agent Version" 
    gicurver=$(glpi-agent --version | grep 'GLPI Agent' | sed -E 's/.*\(([^-]*)-.*/\1/')
    compare-versions $giversion $gicurver
    case "$?" in
        0) echo "Versions are equal" ;;
        1) echo "New version available" 
            gitag=$(awk '/^[Tt]ag = /{print $3}' /etc/glpi-agent/agent.cfg)
            install-glpi-agent $gitag
            ;;
        2) echo "Latest GLPI Agent is already installed"
        ;;
    esac
fi
