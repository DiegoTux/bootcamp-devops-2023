#!/bin/bash
#Variable
repo="bootcamp-devops-2023"
USERID=$(id -u)
#colores
LRED='\033[1;31m'
LGREEN='\033[1;32m'
NC='\033[0m'
LBLUE='\033[0;34m'
LYELLOW='\033[1;33m'



if [ "${USERID}" -ne 0 ]; then
    echo -e "\n${LRED}Este script debe con permisos de sudo o como root.${NC}"
    exit 1
fi 

# STAGE 1: [Init]


# Actualizar el servidor
echo "====================================="
apt-get update
echo -e "\n${LGREEN}El Servidor se encuentra Actualizado ...${NC}"



# Verificar si los paquetes están instalados
packages=("git" "apache2" "mariadb-server" "curl" "php" "libapache2-mod-php" "php-mysql" "php-mbstring" "php-zip" "php-gd" "php-json" "php-curl")

for package in "${packages[@]}"; do
    if ! dpkg -l | grep -q "^ii  $package"; then
        echo -e "\n${LYELLOW}instalando $package...${NC}"
        apt-get install -y $package
    fi
done

# STAGE 2: [Build]

# se clona la clase 2 del ejercicio

git clone -b clase2-linux-bash https://github.com/roxsross/$repo.git
 
### Iniciando la base de datos y Apache
    systemctl start mariadb
    systemctl enable mariadb
    systemctl start apache2
    systemctl enable apache2

 echo -e "\n${LBLUE}Configurando base de datos ...${NC}"
### Configuracion de la base de datos 
    mysql -e "
    CREATE DATABASE devopstravel;
    CREATE USER 'codeuser'@'localhost' IDENTIFIED BY 'codepass';
    GRANT ALL PRIVILEGES ON *.* TO 'codeuser'@'localhost';
    FLUSH PRIVILEGES;"

### Poblar la DB

mysql < /bootcamp-devops-2023/app-295devops-travel/database/devopstravel.sql


# Instalar codigo de la aplicacion

# Validar si existe el repo
if [ -d "$repo" ]; then
    echo -e "\n${LBLUE}La carpeta $repo existe ...${NC}"
    rm -rf $repo
fi

echo -e "\n${LYELLOW}instalando WEB ...${NC}"
sleep 1
git clone -b clase2-linux-bash https://github.com/roxsross/$repo.git
mv /var/www/html/index.html /var/www/html/index.html.bkp
cp -r $repo/app-295devops-travel/* /var/www/html
sed -i "s/\$dbPassword = \"\";/\$dbPassword = \"codepass\";/" /var/www/html/config.php
echo "====================================="

# Cambiar el orden de los índices en Apache
echo -e "\n${LBLUE}Configurando Apache para priorizar index.php...${NC}"
sed -i '/<IfModule mod_dir.c>/,/<\/IfModule>/ s/DirectoryIndex.*/DirectoryIndex index.php index.htm index.html index.cgi index.pl index.xhtml/' /etc/apache2/mods-enabled/dir.conf

# STAGE 3: [Deploy]
### reload
systemctl reload apache2


# STAGE 4: [Notify]

#Validar funcionamiento de php (agregar logica para que devuelva error si no da 200 por ejemplo)
curl localhost/info.php

