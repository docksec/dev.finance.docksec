#!/bin/bash

# Atualizar o sistema
sudo apt update
sudo apt upgrade

# Adicionar conteúdo ao /etc/hosts
echo "127.0.0.1 localhost localhost" | sudo tee -a /etc/hosts
echo "127.0.1.1 srvdocksec.docksec.com srvdocksec" | sudo tee -a /etc/hosts
echo "192.168.28.136 srvdocksec.docksec.com srvdocksec" | sudo tee -a /etc/hosts

# Desativar e parar o systemd-resolved
sudo systemctl disable systemd-resolved
sudo systemctl stop systemd-resolved

# Remover /etc/resolv.conf existente e adicionar novo conteúdo
sudo rm /etc/resolv.conf
echo "nameserver 208.67.222.222" | sudo tee -a /etc/resolv.conf

# Instalar dnsmasq
sudo apt install dnsmasq

# Adicionar conteúdo ao /etc/dnsmasq.conf
echo "" | sudo tee /etc/dnsmasq.conf
echo "# Conteúdo adicionado automaticamente" | sudo tee -a /etc/dnsmasq.conf
echo "server=192.168.28.136" | sudo tee -a /etc/dnsmasq.conf
echo "domain=docksec.com" | sudo tee -a /etc/dnsmasq.conf
echo "mx-host=docksec.com,mail.docksec.com,5" | sudo tee -a /etc/dnsmasq.conf
echo "listen-address=127.0.0.1" | sudo tee -a /etc/dnsmasq.conf

# Reiniciar dnsmasq
sudo systemctl restart dnsmasq

# Baixar e extrair o Zimbra
wget https://files.zimbra.com/downloads/8.8.15_GA/zcs-8.8.15_GA_3869.UBUNTU18_64.20190918004220.tgz
tar xfz zcs-8.8.15_GA_3869.UBUNTU18_64.20190918004220.tgz
cd zcs-8.8.15_GA_3869.UBUNTU18_64.20190918004220

#Iniciando a instalação do Zimbra

ID=`id -u`

if [ "x$ID" != "x0" ]; then
  echo "Run as root!"
  exit 1
fi

if [ ! -x "/usr/bin/perl" ]; then
  echo "ERROR: System perl at /usr/bin/perl must be present before installation."
  exit 1
fi

MYDIR="$(cd "$(dirname "$0")" && pwd)"

. ./util/utilfunc.sh

for i in ./util/modules/*sh; do
	. $i
done

UNINSTALL="no"
SOFTWAREONLY="no"
SKIP_ACTIVATION_CHECK="no"
SKIP_UPGRADE_CHECK="no"
ALLOW_PLATFORM_OVERRIDE="no"
FORCE_UPGRADE="no"

usage() {
  echo "$0 [-r <dir> -l <file> -a <file> -u -s -c type -x -h] [defaultsfile]"
  echo ""
  echo "-h|--help               Usage"
  echo "-l|--license <file>     License file to install."
  echo "-a|--activation <file>  License activation file to install. [Upgrades only]"
  echo "-r|--restore <dir>      Restore contents of <dir> to localconfig"
  echo "-s|--softwareonly       Software only installation."
  echo "-u|--uninstall          Uninstall ZCS"
  echo "-x|--skipspacecheck     Skip filesystem capacity checks."
  echo "--beta-support          Allows installer to upgrade Network Edition Betas."
  echo "--platform-override     Allows installer to continue on an unknown OS."
  echo "--skip-activation-check Allows installer to continue if license activation checks fail."
  echo "--skip-upgrade-check    Allows installer to skip upgrade validation checks."
  echo "--force-upgrade         Force upgrade to be set to YES. Used if there is package installation failure for remote packages."
  echo "[defaultsfile]          File containing default install values."
  echo ""
  exit
}

while [ $# -ne 0 ]; do
  case $1 in
    -r|--restore|--config)
      shift
      RESTORECONFIG=$1
      ;;
    -l|--license)
      shift
      LICENSE=$1
      if [ x"$LICENSE" = "x" ]; then
        echo "Valid license file required for -l."
        usage
      fi

      if [ ! -f "$LICENSE" ]; then
        echo "Valid license file required for -l."
        echo "${LICENSE}: file not found."
        usage
      fi
      ;;
    -a|--activation)
      shift
      ACTIVATION=$1
      if [ x"$ACTIVATION" = "x" ]; then
        echo "Valid license activation file required for -a."
        usage
      fi

      if [ ! -f "$ACTIVATION" ]; then
        echo "Valid license activation file required for -a."
        echo "${ACTIVATION}: file not found."
        usage
      fi
      ;;
    -u|--uninstall)
      UNINSTALL="yes"
      ;;
    -s|--softwareonly)
      SOFTWAREONLY="yes"
      ;;
    -x|--skipspacecheck)
      SKIPSPACECHECK="yes"
      ;;
    -platform-override|--platform-override)
      ALLOW_PLATFORM_OVERRIDE="yes"
      ;;
    -beta-support|--beta-support)
      BETA_SUPPORT="yes"
      ;;
    -skip-activation-check|--skip-activation-check)
      SKIP_ACTIVATION_CHECK="yes"
      ;;
    -skip-upgrade-check|--skip-upgrade-check)
      SKIP_UPGRADE_CHECK="yes"
      ;;
    -force-upgrade|--force-upgrade)
      FORCE_UPGRADE="yes"
      UPGRADE="yes"
      ;;
    -h|-help|--help)
      usage
      ;;
    *)
      DEFAULTFILE=$1
      if [ ! -f "$DEFAULTFILE" ]; then
        echo "ERROR: Unknown option $DEFAULTFILE"
        usage
      fi
      ;;
  esac
  shift
done

. ./util/globals.sh

getPlatformVars

mkdir -p $SAVEDIR
chown zimbra:zimbra $SAVEDIR 2> /dev/null
chmod 750 $SAVEDIR

echo ""
echo "Operations logged to $LOGFILE"

if [ "x$DEFAULTFILE" != "x" ]; then
	AUTOINSTALL="yes"
else
	AUTOINSTALL="no"
fi

if [ x"$LICENSE" != "x" ] && [ -e $LICENSE ]; then
  if [ ! -d "/opt/zimbra/conf" ]; then
    mkdir -p /opt/zimbra/conf
  fi
  cp $LICENSE /opt/zimbra/conf/ZCSLicense.xml
  chown zimbra:zimbra /opt/zimbra/conf/ZCSLicense.xml 2> /dev/null
  chmod 444 /opt/zimbra/conf/ZCSLicense.xml
fi

if [ x"$ACTIVATION" != "x" ] && [ -e $ACTIVATION ]; then
  if [ ! -d "/opt/zimbra/conf" ]; then
    mkdir -p /opt/zimbra/conf
  fi
  cp $ACTIVATION /opt/zimbra/conf/ZCSLicense-activated.xml
  chown zimbra:zimbra /opt/zimbra/conf/ZCSLicense-activated.xml 2> /dev/null
  chmod 444 /opt/zimbra/conf/ZCSLicense-activated.xml
fi

checkExistingInstall

if [ x"$INSTALLED" != "xyes" ] && [ x"$ACTIVATION" != "x" ]; then
  echo "License activation file option is only available on upgrade."
  usage
fi

if [ x$UNINSTALL = "xyes" ]; then
	askYN "Completely remove existing installation?" "N"
	if [ $response = "yes" ]; then
		REMOVE="yes"
		findUbuntuExternalPackageDependencies
		saveExistingConfig
		removeExistingInstall
	fi
	exit 1
fi

displayLicense

displayThirdPartyLicenses

checkUser root

if [ $AUTOINSTALL = "yes" ]; then
	loadConfig $DEFAULTFILE
fi

checkRequired

