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
dnf module disable nodejs -y &>>$LOG_FILE
VALIDATE $? "Disabling NodeJS"

dnf module enable nodejs:20 -y &>>$LOG_FILE
VALIDATE $? "Enabling NodeJS 20"

dnf install nodejs -y &>>$LOG_FILE
VALIDATE $? "installing NodeJS"

useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE
VALIDATE$? "Creating system user"

mkdir /app
VALIDATE $? "Creating App Directory"
curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip &>>$LOG_FILE
VALIDATE $? "Downloading catalogue Directory"
cd /app 
VALIDATE $? "Changing to App Directory"
unzip /tmp/catalogue.zip &>>$LOG_FILE
VALIDATE $? "unzip catalogue"
npm install &>>$LOG_FILE
VALIDATE $? "install dependencies"
cp catalogue.serivce /etc/systemd/system/catalogue.service
VALIDATE $? "Copy Systemctl Service"
systemctl daemon-reload
systemctl enable catalogue &>>$LOG_FILE
VALIDATE $? "Enabling Catalogue"

cp mongo.repo /etc/yum.repos.d/mongo.repo
VALIDATE $? "Copy mongo repo"
dnf install mongodb-mongosh -y &>>$LOG_FILE
VALIDATE $? "Install MONGODB client"
mongosh --host $MONGODB_HOST </app/db/master-data.js &>>$LOG_FILE
VALIDATE $? "Load Catalogue Products"
systemctl restart catalogue
VALIDATE $? "Restarted Catalogue"
