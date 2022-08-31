#!/bin/sh
set -e

# Аргументы, которые передаются вместе с командой
WHATS_DIRECTORY_BACKUP=$1 # 'default' or '/etc /home /root /usr'
EXCLUDE_ARGUMENT=$2 # 's' or 'exclude.lst'
GPG_PUB_KEY=$3
DELETE_OLD_BACKUP=${4:-'no'} # 'delete-old' or 'no'


CURRENT_DIR=$(pwd)
BASE_DIR="/home/$(whoami)"
DIRECTORY_FOR_SAVE="$BASE_DIR/backups/"
NAME_BACKUP_FILE="$(whoami)_$(date +%F)"
NAME_ZIP_BACKUP_FILE=$NAME_BACKUP_FILE.tar.gz
ZIP=$DIRECTORY_FOR_SAVE$NAME_ZIP_BACKUP_FILE
ZIP_DIRECTORY=$DIRECTORY_FOR_SAVE$NAME_BACKUP_FILE

if [ ! $GPG_PUB_KEY ]
then
    echo "Ошибка! Укажите ключ для шифрования бэкапа."
else

    if [ ! -d $DIRECTORY_FOR_SAVE ]
    then
        echo "Создание директории $DIRECTORY_FOR_SAVE"
        mkdir $DIRECTORY_FOR_SAVE
    fi

    if [ $WHATS_DIRECTORY_BACKUP = "default" ]
    then
        echo "Выбраны стандартные директории для бэкапа"
        WHATS_DIRECTORY_BACKUP=$BASE_DIR
        echo $WHATS_DIRECTORY_BACKUP
    fi

    if [ $DELETE_OLD_BACKUP = "delete-old" ]
    then
        cd $DIRECTORY_FOR_SAVE
        echo "Удаление старых бэкапов из $DIRECTORY_FOR_SAVE"
        find . -name '$(whoami)*' -type f | xargs stat -c "%Y %n" | sort -n \
            | head -1 | cut -d' ' -f2 | xargs rm -f
        cd $CURRENT_DIR
    fi

    if [ $EXCLUDE_ARGUMENT = "s" ]
    then
        echo -n "1: Сборка файлов для стандартного бэкапа $NAME_BACKUP_FILE ..."
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
            --delete $ZIP_DIRECTORY \
            2>/dev/null && echo " Выполнено!" || echo " Ошибка!" 
    else
        echo -n "1: Сборка файлов для стандартного бэкапа $NAME_BACKUP_FILE \
            с исключениями из файла $EXCLUDE_ARGUMENT ..."
        sudo rsync --archive --one-file-system \
            $WHATS_DIRECTORY_BACKUP \
            --exclude-from=$EXCLUDE_ARGUMENT \
            --delete $ZIP_DIRECTORY \
            2>/dev/null && echo " Выполнено!" || echo " Ошибка!"    
    fi

    echo -n "2: Архивация бэкапа $NAME_ZIP_BACKUP_FILE ... "
    # добавив ключ -v можно увидеть подробности архивации
    sudo tar -czpf $ZIP $ZIP_DIRECTORY 2>/dev/null && echo " Выполнено!" || echo " Ошибка!"

    echo -n "3: Шифрование архива используя ключ GPG2 ..."
    gpg --out "$ZIP.asc" \
        --recipient "$GPG_PUB_KEY" \
        --encrypt $ZIP \
        && echo " Выполнено!" || echo " Ошибка!"

    echo -n "4: Удаление ненужных исходных backup файлов ..."

    echo -n "- Удаление незашифрованного архива backup файлов: $ZIP"
    sudo rm -rf $ZIP && echo " Выполнено!" || echo " Ошибка!"

    echo -n "- Удаление директории незашифрованных backup файлов: $ZIP_DIRECTORY"
    sudo rm -rf $ZIP_DIRECTORY/ && echo " Выполнено!" || echo " Ошибка!"

    echo "Создание backup файла: $ZIP.asc - Выполнено!"
fi
