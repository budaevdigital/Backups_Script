#!/bin/sh
set -e

# Принимаем имя бэкап-файла, без расширения
BACKUP_FILE=$1 # sample: 'arkalaust_2022-08-23'
DIRECTORY_WHERE_SAVE=${2:-'/'} # your custom directory or '/'


CURRENT_DIR=$(pwd)
BASE_DIR="/home/$(whoami)"
DIRECTORY_FOR_SAVE="$BASE_DIR/backups/"
RECOVERY_DIR="$BASE_DIR/backups/recovery/"


if [ ! $BACKUP_FILE ]
then
    echo "Ошибка! Укажите файл для восстановления бэкапа."
else
    if [ -f "$DIRECTORY_FOR_SAVE$BACKUP_FILE.tar.gz.asc" ]
    then
        echo "Файл $BACKUP_FILE.tar.gz.asc найден! Начитается восстановление"
        echo -n "1: Дешифровка бэкап файла... "
        gpg --out "$DIRECTORY_FOR_SAVE$BACKUP_FILE.tar.gz" --decrypt "$DIRECTORY_FOR_SAVE$BACKUP_FILE.tar.gz.asc" \
            2>/dev/null && echo " Выполнено!" || echo " Ошибка!"

        if [ ! -d $RECOVERY_DIR ]
        then
            echo "  - Создание директории для восстановления $RECOVERY_DIR"
            mkdir $RECOVERY_DIR
        fi

        echo -n "2: Восстановление из архива... "
        sudo tar --extract --same-permissions --file "$DIRECTORY_FOR_SAVE$BACKUP_FILE.tar.gz" -C $RECOVERY_DIR \
            2>/dev/null && echo " Выполнено!" || echo " Ошибка!"

        echo -n "3: Перенос файлов в основной каталог $DIRECTORY_WHERE_SAVE ... "
        cd $RECOVERY_DIR$DIRECTORY_FOR_SAVE$BACKUP_FILE
        sudo mv * $DIRECTORY_WHERE_SAVE && echo " Выполнено!" || echo " Ошибка!"
        cd $CURRENT_DIR

        echo -n "4: Удаление незашифрованного архива после восстановления: $BACKUP_FILE.tar.gz... "
        sudo rm -rf "$DIRECTORY_FOR_SAVE$BACKUP_FILE.tar.gz" \
            && echo " Выполнено!" || echo " Ошибка!"
        
        echo -n "  - Удаление незашифрованой директории 'recovery'... "
        sudo rm -r "$RECOVERY_DIR" \
            && echo " Выполнено!" || echo " Ошибка!"
    else
        echo "Файл $BACKUP_FILE.tar.gz.asc - не найден!"
        echo "Бэкап-файл должен находится в директории: $DIRECTORY_FOR_SAVE"
    fi
fi