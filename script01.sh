su 
# ввод пароля, пароль предоставляет клиент
echo -e 'proxyuser\n' | su
apt install sudo

# добавляем пользователя VPN proxy и даем право беспарольного sudo
sudo useradd -p proxyuser -s /bin/bash -m proxyuser
#
echo "proxyuser ALL=(ALL) NOPASSWD: ALL" | sudo tee -a /etc/sudoers.d/010_proxyuser-nopasswd

# создаем директорию для ssh-key и добавляем серверный ключ
mkdir /home/proxyuser/.ssh && \
echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCsnQsdLZGlF6fIzaNIAxb0Sb1p0GZoXMtW6eOPRWD3hROaMbmaSt5dzBnjOzDfdGcXTkhbM7R9auSXiNGn2ZlXenkhyCmglp5iOjpvCI5th1Oas2dOAayWejBigekjmlAS3FQINuSNAyTxtmYQdR/bCp8r5MltPhPQArJTz50tahjWsFGDxd64S/nXwrW1vfbpUgD//u4VCRxIckjLT5NVOi6bVIPekgb+2347EgWXtGcheW4Rx4jza4oD0Ln2ex1HfPt1UUHS6x0PTQighOQbMwecBnyQeJUZbIbSokr4zt7dOxSm8emAm/hlIqxXgd43JIJMboUxKTrAo0qshze/ proxyuser@ovpn" \n
| sudo tee -a /home/proxyuser/.ssh/authorized_keys

# добавляем репозиторий с ПО
sudo apt install gnupg -y
echo "deb http://repo.open-s.info/ buster main" | sudo tee -a /etc/apt/sources.list.d/bos.list
wget -qO - http://repo.open-s.info/aptly.gpg.key | sudo apt-key add


# ошибка depends:libtiff5 is not installable
# закомментировать все что связано с 12 версией
sudo sed -i '/^deb/s/^/#/' /etc/apt/sources.list

# добавление строк 11 Debian
sudo cat <<EOF>> /etc/apt/sources.list
deb http://deb.debian.org/debian/ bullseye main
deb-src http://deb.debian.org/debian/ bullseye main

deb http://security.debian.org/debian-security bullseye-security main
deb-src http://security.debian.org/debian-security bullseye-security main

deb http://deb.debian.org/debian/ bullseye-updates main
deb-src http://deb.debian.org/debian/ bullseye-updates main
EOF

# установка нужных библиотек
sudo apt update
sudo apt-get -y install libicu67
sudo apt-get -y install libtiff5
sudo apt-get -y install libssl1.1

# снять комментарий с 12 версии и добавить на 11
sudo sed -i '/#deb/s/#//' /etc/apt/sources.list
sudo sed -i '1s/^/#/' /etc/apt/sources.list
sudo sed -i '/bullseye/s/^/#/' /etc/apt/sources.list

# устанавливаем последний релиз sst-iiko из добавленных реп и включаем автозапуск
sudo apt update
sudo apt install sst-iiko -y
sudo systemctl enable sst-iiko
sudo systemctl start sst-iiko 


# создать и заполнить конфиг
sudo cat <<EOF>> /etc/sst-iiko/settings.ini
[General]
fontFamily=roboto
preorderMode=false
submitBasketTimeout=200 
userSessionTimeout=1m30s 
userSessionWarningTimeoutDelta=59s 

[BarCode]
scanDelay=2
scanDelayTimeout=2

[Common]
carryOutEnabled=true
dineInEnabled=true
modifersExpanded=true
preorderMode=false
remoteBasket=true
showOrderTypeEmptyChoice=false
submitBasketRequestTimer=200

[FP]
fiscal\type=Dummy
printer\SETTINGS_PATH=/etc/sst-iiko/print_settings.ini
printer\TEMPLATE_PATH=./templates/
printer\type=Dummy
type=Dummy

[HttpServer]
ip=0.0.0.0
port=10000

[Idle]
alwaysShowOrderTypeChoice=false
carryOutEnabled=true
dineInEnabled=true
idlePageDisplayMode=imageRotation
orderTypesDirectionLeftToRight=true
rotationIntervalTimeout=59s
showOrderTypePage=true

[Language]
primary=ru
secondary=en

[Loyalty]
forceLoyaltyOpening=false

[Menu]
allowQuickAdd=false
packageBasingDishAutoOpening=true
productCardType=1
relatedProductsBlockType=2
showAllMenuGroup=false
showCategoryPage=true
showCounterForDishWithModifiers=false
showMenuPage=true
showMenuTags=false
showPricePrefix=true

[OrderType]
carryOutEnabled=true
dineInEnabled=false

[PostMenu]
allowReceiptPageSkip=true
canSkipLocatorPage=false
finalPageInteractTimeout=10s
receiptShowMinimumTimeout=5s
showLocatorPage=false
showLocatorPageNotInside=false

[Terminal]
type=Dummy

[Theme]
formatType=standart
theme=basic

[iiko]
adminCard=
host=ws://
port=8001
tid=
EOF

# включить правило проверки сети
sudo systemctl enable systemd-networkd-wait-online.service

# запуск ПО киоска и подключение его к iikofront и backoffice
sudo systemctl start sst-iiko
