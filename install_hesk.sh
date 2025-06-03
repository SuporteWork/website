#!/bin/bash
set -e  # Parar em caso de erro
LOGFILE="/var/log/hesk_install.log"

# Função de log
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOGFILE"
}

function download_hesk() {
    HESK_URL="https://mnu.ac.ke/hesk/hesk353.zip"
    HESK_FILE="/tmp/hesk.zip"
    
    echo "Baixando HESK versão ${HESK_VERSION}..."
    if command -v curl >/dev/null 2>&1; then
        curl -L -o "${HESK_FILE}" "${HESK_URL}"
    elif command -v wget >/dev/null 2>&1; then
        wget -O "${HESK_FILE}" "${HESK_URL}"
    else
        echo "Erro: curl ou wget não encontrados. Por favor, instale um deles."
        exit 1
    fi

    if [ ! -f "${HESK_FILE}" ]; then
        echo "Erro: Falha ao baixar o arquivo HESK"
        return 1
    fi

    return 0
}

function check_requirements() {
    # Verificar se está rodando como root
    if [ "$EUID" -ne 0 ]; then 
        echo "Este script precisa ser executado como root"
        exit 1
    fi

    # Verificar dependências básicas
    DEPS="apache2 mysql-server php"
    for dep in $DEPS; do
        if ! dpkg -l | grep -q "^ii.*$dep"; then
            echo "Dependência necessária não encontrada: $dep"
            echo "Por favor, instale todas as dependências primeiro"
            exit 1
        fi
    done
}

function sed_configuracao() {
	orig=$(echo $1 | tr -s ' ' '|' | cut -d '|' -f 1 | head -n 1)
	origparm=$(echo $1 | tr -s ' ' '|' | cut -d '|' -f 3 | head -n 1)
		if [[ -z $origparm ]];then
			origparm=$(echo $1 | tr -s ' ' '|' | cut -d '|' -f 2 | head -n 1)
		fi
	dest=$(grep -E "^(#|\;|)$orig" $2 | tr -s ' ' '|' | cut -d '|' -f 1 | head -n 1)
	destparm=$(grep -E "^(#|\;|)$orig" $2 | tr -s ' ' '|' | cut -d '|' -f 3 | head -n 1)
		if [[ -z $destparm ]];then
			destparm=$(grep -E "^(#|\;|)$orig" $2 | tr -s ' ' '|' | cut -d '|' -f 2 | head -n 1)
		fi
case ${dest} in
	\#${orig})
			sed -i "/^$dest.*$destparm/c\\${1}" $2
		;;
	\;${orig})
			sed -i "/^$dest.*$destparm/c\\${1}" $2
		;;
	${orig})
			if [[ $origparm != $destparm ]]; then
				sed -i "/^$orig/c\\${1}" $2
				else
					if [[ -z $(grep '[A-Z\_A-ZA-Z]$origparm' $2) ]]; then
						fullorigparm3=$(echo $1 | tr -s ' ' '|' | cut -d '|' -f 3 | head -n 1)
						fullorigparm4=$(echo $1 | tr -s ' ' '|' | cut -d '|' -f 4 | head -n 1)
						fullorigparm5=$(echo $1 | tr -s ' ' '|' | cut -d '|' -f 5 | head -n 1)
						fulldestparm3=$(grep -E "^(#|\;|)$orig" $2 | tr -s ' ' '|' | cut -d '|' -f 3 | head -n 1)
						fulldestparm4=$(grep -E "^(#|\;|)$orig" $2 | tr -s ' ' '|' | cut -d '|' -f 4 | head -n 1)
						fulldestparm5=$(grep -E "^(#|\;|)$orig" $2 | tr -s ' ' '|' | cut -d '|' -f 5 | head -n 1)
						sed -i "/^$dest.*$fulldestparm3\ $fulldestparm4\ $fulldestparm5/c\\$orig\ \=\ $fullorigparm3\ $fullorigparm4\ $fullorigparm5" $2
					fi
			fi
		;;
		*)
			echo ${1} >> $2
		;;
	esac
}
clear
RELEASE=$(cat /etc/lsb-release | grep DISTRIB_CODENAME | cut -c18-30)

case "$RELEASE" in
		bionic)
			echo "É UBUNTU 18.04 BIONIC"
			sleep 2
		;;
		focal)
        echo "É UBUNTU 20.04 FOCAL"
	sleep 2
    ;;
    jammy)
        echo "É UBUNTU 22.04 JAMMY"
	sleep 2
    ;;
    noble)
        echo "É UBUNTU 24.04 JAMMY"
	sleep 2
    ;;
    *)
        echo "RELEASE INVALIDA"
	sleep 2
	exit
    ;;
esac

clear
echo "AJUSTANDO REPOSITÓRIOS"
sleep 2
sed -i 's/\/archive/\/br.archive/g' /etc/apt/sources.list

clear
echo "AJUSTANDO IDIOMA"
sleep 2
apt-get update
apt-get --force-yes --yes install language-pack-gnome-pt language-pack-pt-base myspell-pt wbrazilian wportuguese software-properties-common gettext

# Configurações do MySQL
MYSQL_HESK_USER="hesk"
MYSQL_HESK_PASS=$(openssl rand -base64 12)
MYSQL_HESK_DB="hesk"

echo "INSTALANDO MYSQL"
sleep 2
apt-get update
apt-get --force-yes --yes install mysql-server mysql-client

clear
echo "CONFIGURANDO MYSQL"
sleep 2

# Criar arquivo de configuração temporário
cat > /tmp/mysql_setup.sql << EOF
CREATE USER '${MYSQL_HESK_USER}'@'localhost' IDENTIFIED BY '${MYSQL_HESK_PASS}';
CREATE DATABASE ${MYSQL_HESK_DB} CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
GRANT ALL PRIVILEGES ON ${MYSQL_HESK_DB}.* TO '${MYSQL_HESK_USER}'@'localhost';
FLUSH PRIVILEGES;
EOF

# Executar configuração do MySQL
mysql -u root < /tmp/mysql_setup.sql

# Remover arquivo temporário
rm -f /tmp/mysql_setup.sql

# Salvar credenciais para uso posterior
cat > /root/.hesk_credentials << EOF
MYSQL_USER=${MYSQL_HESK_USER}
MYSQL_PASS=${MYSQL_HESK_PASS}
MYSQL_DB=${MYSQL_HESK_DB}
EOF
chmod 600 /root/.hesk_credentials

clear
echo "INSTALANDO APACHE E PHP"
sleep 2
apt-get update
case "$RELEASE" in
	bionic)
		sudo apt-get --force-yes --yes install apache2 php libapache2-mod-php php-{curl,gd,imagick,intl,apcu,memcache,imap,mysql,ldap,tidy,xmlrpc,pspell,mbstring,json,xml,gd,intl} php-zip php-bz2
		;;
	focal)
        sudo apt-get --force-yes --yes install apache2 php libapache2-mod-php php-{curl,gd,imagick,intl,apcu,memcache,imap,mysql,ldap,tidy,xmlrpc,pspell,mbstring,json,xml,gd,intl} php-zip php-bz2
        ;;
    jammy)
        sudo apt-get --force-yes --yes install apache2 php libapache2-mod-php php-{curl,gd,imagick,intl,apcu,memcache,imap,mysql,ldap,tidy,xmlrpc,pspell,mbstring,json,xml,gd,intl} php-zip php-bz2
        ;;
    noble)
        sudo apt-get --force-yes --yes install apache2 php libapache2-mod-php php-{curl,gd,imagick,intl,apcu,memcache,imap,mysql,ldap,tidy,xmlrpc,pspell,mbstring,json,xml,gd,intl} php-zip php-bz2
        ;;
    *)
        echo "RELEASE INVALIDA"
	sleep 2
	exit
    ;;
esac

clear
echo "CONFIGURANDO VIRTUAL HOST"
sleep 2
a2enmod rewrite
a2dissite 000-default default-ssl

cat << APADEF > /etc/apache2/sites-available/hesk.conf
<VirtualHost *:80>

  AddDefaultCharset utf-8
  SetEnv no-gzip 1

  <Directory /var/www/html>
		Options -Indexes +FollowSymLinks +MultiViews
		AllowOverride All
		Require all granted
  </Directory>

	ServerAdmin webmaster@localhost
	DocumentRoot /var/www/html

	ErrorLog /var/log/apache2/error.log
	CustomLog /var/log/apache2/access.log combined

</VirtualHost>

APADEF

a2ensite hesk
/etc/init.d/apache2 restart

clear
echo "FAZENDO DOWNLOAD DO HESK"
sleep 2
ARQUIVO=0
cd /tmp
download_hesk
while [[ $? -eq 1 ]]; do
  rm ${ARQ}
  download_hesk
done

clear
echo "EXTRAINDO ARQUIVOS"
sleep 2
cd /tmp

# Verificar se temos unzip instalado
if ! command -v unzip >/dev/null 2>&1; then
    apt-get --force-yes --yes install unzip
fi

# Limpar diretório de destino
rm -rf /var/www/html/*

# Extrair arquivos
unzip -q "${HESK_FILE}" -d /tmp/hesk_temp
mv /tmp/hesk_temp/hesk/* /var/www/html/
rm -rf /tmp/hesk_temp

# Configurar permissões corretas
find /var/www/html -type f -exec chmod 644 {} \;
find /var/www/html -type d -exec chmod 755 {} \;
chown -R www-data:www-data /var/www/html

# Criar diretório para uploads e dar permissões apropriadas
mkdir -p /var/www/html/attachments
chmod 777 /var/www/html/attachments

# Configurar o config.php inicial
source /root/.hesk_credentials
cat > /var/www/html/hesk_settings.inc.php << EOF
<?php
// Configurações básicas do HESK
\$hesk_settings['db_host'] = 'localhost';
\$hesk_settings['db_name'] = '${MYSQL_DB}';
\$hesk_settings['db_user'] = '${MYSQL_USER}';
\$hesk_settings['db_pass'] = '${MYSQL_PASS}';

// Configurações de segurança
\$hesk_settings['securitykey'] = '$(openssl rand -hex 32)';

// Configurações regionais
\$hesk_settings['language'] = 'pt';
\$hesk_settings['timezone'] = 'America/Sao_Paulo';
EOF

clear
echo "CRIANDO INDEX.HTML"
sleep 2
cat << INDEX > /var/www/html/index.html
<html>
<head>
<title>HESK</title>
<meta http-equiv="refresh" content="0;URL=hesk" />
</head>
<body>
</body>
</html>

INDEX

clear
echo "REINICIADO SERVIÇOS"
sleep 2
/etc/init.d/apache2 restart

clear
echo "============================================"
echo "       INSTALAÇÃO DO HESK CONCLUÍDA        "
echo "============================================"
echo ""
echo "Informações importantes:"
echo "1. URL de acesso: http://$(ip addr show | grep 'inet ' | grep brd | tr -s ' ' '|' | cut -d '|' -f 3 | cut -d '/' -f 1 | head -n 1)/hesk/"
echo "2. Credenciais do banco de dados foram salvas em: /root/.hesk_credentials"
echo "3. Log de instalação disponível em: $LOGFILE"
echo ""
echo "Próximos passos:"
echo "1. Acesse a URL acima para completar a configuração via navegador"
echo "2. Configure um certificado SSL para maior segurança"
echo "3. Faça backup regular do banco de dados e arquivos"
echo ""
echo "Em caso de problemas, consulte o arquivo de log: $LOGFILE"
