#!/bin/bash

USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
NO="\e[0m" #no color

LOGS_FOLDER="/var/log/shell-roboshop"
SCRIPT_NAME=$( echo $0 | cut -d "." -f1)
MONGODB_HOST=mongodb.harivara.fun
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"

mkdir -p $LOGS_FOLDER
echo "Script started executed at:: $(date)" | tee -a $LOG_FILE # to apend in log

if [ $USERID -ne 0 ]; then 
    echo "ERROR:: Please run this script with root privilage"
    exit 1 #failure is other than 0
fi

VALIDATE(){ #functions recieve i/p's through args like shell script args

    if [ $1 -ne 0 ]; then
        echo -e " $2 is...... $R failure $NO" | tee -a $LOG_FILE
        exit 1
    else
        echo -e  " $2 is.......... $G  SUCCESS $NO" | tee -a $LOG_FILE
    fi

}

#####NODEJS INSTALLATION#####
dnf module disable nodejs -y
VALIDATE $? "Disabling NodeJS"

dnf module enable nodejs:20 -y
VALIDATE $? "Enabling NodeJS 20"

dnf install nodejs -y
VALIDATE $? "installing NodeJS"

useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
VALIDATE $? "Creating system user"

mkdir /app
VALIDATE $? "Creating App Directory"

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip 
VALIDATE $? "Downloading catalogue Directory"

cd /app 
VALIDATE $? "Changing to App Directory"
unzip /tmp/catalogue.zip
VALIDATE $? "unzip catalogue"
npm install
VALIDATE $? "install dependencies"
cp catalogue.serivce /etc/systemd/system/catalogue.service
VALIDATE $? "Copy Systemctl Service"
systemctl daemon-reload
systemctl enable catalogue
VALIDATE $? "Enabling Catalogue"

cp mongo.repo /etc/yum.repos.d/mongo.repo
VALIDATE $? "Copy mongo repo"
dnf install mongodb-mongosh -y
VALIDATE $? "Install MONGODB client"
mongosh --host $MONGODB_HOST </app/db/master-data.js
VALIDATE $? "Load Catalogue Products"
systemctl restart catalogue
VALIDATE $? "Restarting Catalogue Service"