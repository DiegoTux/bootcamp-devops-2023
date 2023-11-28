#Definimos colores para usar en el script
#red=
#blue=
#green=
repo=clase2-linux-bash
carpeta=bootcamp-devops-2023

# Chequeamos si el usuario es root. Caso contrario no se avanzará con la ejecución del script
if [[ "${USERID}" -ne "0" ]]; then
    echo -e "\e[31;1;3mDebes ser usuario ROOT.\e[m"
    exit 1
fi

######### Stage 1: init ########

# Verificamos que el servidor esté actualizado
sudo apt-get update

# Declaramos los paquetes a usar
packages=(mariadb-server apache2 git php libapache2-mod-php php-mysql php-mbstring php-zip php-gd php-json php-curl) 

# Verificar si X paquete se encuentra instalado. Caso contrario se procede a instalar el mismo
for pkg in "${packages[@]}"; do
	
	if dpkg -s $pkg > /dev/null 2>&1; then
    echo -e "\n\e[96m$pkg ya se encuentra instalado \033[0m\n"
else
    echo -e "\n\e[92mInstalando $pkg ...\033[0m\n"
    apt install -y $pkg
	fi
	
done

######## Stage 2: Build ########

# Validar si el repositorio de la aplicación no existe, realizar un git clone. 
# y si existe un git pull

if [ -d "$repo" ]; then
    echo "La carpeta $repo existe"
    git pull -b $repo https://github.com/roxsross/bootcamp-devops-2023.git
else
	git clone -b $repo https://github.com/roxsross/bootcamp-devops-2023.git 
fi

# Mover al directorio donde se guardar los archivos de configuración de apache /var/www/html/
cp -r $carpeta/app-295devops-travel/* /var/www/html/

# habilitar MariaDB
sudo systemctl start mariadb
sudo systemctl enable mariadb
# sudo systemctl status mariadb

# Configurar la base de datos
mysql -e "CREATE DATABASE devopstravel;
CREATE USER 'codeuser'@'localhost' IDENTIFIED BY 'codepass';
GRANT ALL PRIVILEGES ON *.* TO 'codeuser'@'localhost';
FLUSH PRIVILEGES;"

# Agregar datos a la database devopstravel Run sql script ruta: database
mysql < $carpeta/app-295devops-travel/database/devopstravel.sql


# Deploy and configure web
sudo systemctl start apache2 
sudo systemctl enable apache2

# Configurar apache para que soporte extensión php
# Con la configuración predeterminada de DirectoryIndex en Apache, un archivo denominado index.html 
# siempre tendrá prioridad sobre un archivo index.php
# Si desea cambiar este comportamiento, deberá editar el archivo /etc/apache2/mods-enabled/dir.conf y modificar el orden en el 
# que el archivo index.php se enumera en la directiva DirectoryIndex:
sudo echo "<IfModule mod_dir.c>
        DirectoryIndex index.php index.html index.cgi index.pl index.xhtml index.htm
</IfModule>" > /etc/apache2/mods-enabled/dir.conf

# Se recarga apache para que los cambios tomen efecto
sudo systemctl reload apache2

# Se debe definir un comando sed que busque la línea:
#
# $dbPassword = ""; 
# Y que la cambie por:
# $dbPassword = "codepass";
# Por último, indicar la ruta en donde se encuentra guardado este archivo que es /var/www/html/config.php 
sed -i "s/\$dbPassword = \"\";/\$dbPassword = \"codepass\";/" /var/www/html/config.php

### STAGE 4: [Notify] ###
# en el chat se puede encontrar el discord.sh en donde indica el token a donde apunta para hacer el webhook

