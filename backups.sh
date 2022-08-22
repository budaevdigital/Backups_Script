#!/bin/sh
set -e

# bdir="/home/$(whoami)"
# bfile="$bdir/backups/$(whoami)_$(date +%F).tar.gzip"  

EXCLUDE_ARGUMENT='S'  #$1 # 'F' or 'S'
# WHATS_DIRECTORY_BACKUP=  #$2 # Sample '/etc /home /root /usr'
GPG2_PUB_KEY="83739A3C11FD9556C32D72FA28B631B7CF06FE44"
#"83739A3C11FD9556C32D72FA28B631B7CF06FE44"  #$2

BASE_DIR="/home/$(whoami)"
DIRECTORY_FOR_SAVE="$BASE_DIR/backups/"
NAME_BACKUP_FILE="$(whoami)_$(date +%F)"
NAME_ZIP_BACKUP_FILE=$NAME_BACKUP_FILE.tar.gz
ZIP=$DIRECTORY_FOR_SAVE$NAME_ZIP_BACKUP_FILE
ZIP_DIRECTORY=$DIRECTORY_FOR_SAVE$NAME_BACKUP_FILE
EXCLUDE=""

WHATS_DIRECTORY_BACKUP="/etc /home /root /usr"

if [ ! -d $DIRECTORY_FOR_SAVE ]; then
    echo "Создание директории $DIRECTORY_FOR_SAVE"
    mkdir $DIRECTORY_FOR_SAVE
fi



# if [ $EXCLUDE_ARGUMENT == "S" ]; then
# else
# fi

echo -n "1: Сборка файлов в отдельной директории для бэкапа $NAME_BACKUP_FILE ..."
sudo rsync --archive --one-file-system \
    $WHATS_DIRECTORY_BACKUP \
    --exclude="virtualbox" \
    --exclude=".cache/*" \
    --exclude="*Cache*/*" \
    --exclude="backups" \
    --exclude="downloads" \
    --exclude="*tmp/*" \
    --exclude="Downloads" \
    --exclude="Documents" \
    --exclude="Pictures" \
    --exclude=".Trash" \
    --exclude=".local/*" \
    --exclude="virtualbox" \
    --delete $ZIP_DIRECTORY \
    2>/dev/null && echo " Выполнено!" || echo " Ошибка!"


echo -n "2: Архивация полученной директории $NAME_ZIP_BACKUP_FILE ... "
sudo tar -czpvf $ZIP $ZIP_DIRECTORY 2>/dev/null && echo " Выполнено!" || echo " Ошибка!"


echo -n "3: Шифрование архива используя ключ GPG2 ..."
gpg --out "$ZIP.asc" \
    --recipient "$GPG2_PUB_KEY" \
    --encrypt $ZIP \
    && echo " Выполнено!" || echo " Ошибка!"

echo -n "4: Удаление ненужных исходных backup файлов ..."

echo -n "Удаление незашифрованных backup файлов: $ZIP"
sudo rm -rf $ZIP && echo " Выполнено!" || echo " Ошибка!"

echo -n "Удаление незашифрованных backup файлов: $ZIP_DIRECTORY"
sudo rm -rf $ZIP_DIRECTORY/ && echo " Выполнено!" || echo " Ошибка!"



echo "Создание backup файла: $ZIP.asc - Выполнено!"








