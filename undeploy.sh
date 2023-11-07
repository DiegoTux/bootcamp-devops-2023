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
    echo -e "\n${LRED}Este script debe ejecutarse con permisos de sudo o como root.${NC}"
    exit 1
fi

# STAGE 1: [Undeploy]

# Detener Apache y MySQL
systemctl stop apache2
systemctl stop mariadb

echo -e "\n${LBLUE}Eliminando la base de datos ...${NC}"
# Eliminar la base de datos
mysql -e "DROP DATABASE devopstravel;"

echo -e "\n${LYELLOW}Eliminando archivos de la aplicación ...${NC}"
# Eliminar archivos de la aplicación
rm -rf /var/www/html/*

# Restaurar el archivo index.html original de Apache
if [ -f /var/www/html/index.html.bkp ]; then
    mv /var/www/html/index.html.bkp /var/www/html/index.html
fi

# Borrar el repositorio clonado
if [ -d "$repo" ]; then
    echo -e "\n${LBLUE}Eliminando el repositorio $repo ...${NC}"
    rm -rf $repo
fi

echo -e "\n${LGREEN}Undeploy completado.${NC}"

# STAGE 2: [Clean Up]

# Eliminar paquetes instalados que no eran parte de la configuración original
packages=("git" "apache2" "mariadb-server" "curl" "php" "libapache2-mod-php" "php-mysql" "php-mbstring" "php-zip" "php-gd" "php-json" "php-curl")
for package in "${packages[@]}"; do
    if dpkg -l | grep -q "^ii  $package"; then
        echo -e "\n${LYELLOW}Eliminando el paquete $package ...${NC}"
        apt-get remove -y $package
    fi
done

# STAGE 3: [Notify]
echo -e "\n${LGREEN}Undeploy completado. La aplicación y la base de datos han sido eliminadas.${NC}"

