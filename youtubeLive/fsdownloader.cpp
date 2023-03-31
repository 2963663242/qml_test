#include "fsdownloader.h"
#include <QCoreApplication>
#include <iostream>
#include <QJsonObject>
#include <QJsonDocument>
#include <QJsonParseError>

using namespace std;

#define LOG_PATH "Log"


FsDownloader::FsDownloader(QObject *parent) : QObject(parent)
{
    auto preConfig = [](){
        Downloader::setLogPath((char *)LOG_PATH);
        std::string exePath = QCoreApplication::applicationDirPath().toStdString();
        Downloader::setexePath((char *)exePath.c_str());
        return true;
    };

    static bool configSuss = preConfig();
}


void FsDownloader::stateInform(char * json){
    cout << json << endl;
//   QJsonParseError jsonParseError;
//   QJsonDocument jsonDocument = QJsonDocument::fromJson(json, &jsonParseError);
//   if (jsonParseError.error == QJsonParseError::NoError) {
//           QJsonObject root = jsonDocument.object();
//            if(root["type"].toString()=="parsed"){

//            }
//            else if(root["type"].toString()=="finished"){

//            }
//    }
     this->parseSucc(json);
}

void FsDownloader::parse(QString url){
    if(m_tmpDir)
        delete m_tmpDir;
    m_tmpDir = new QTemporaryDir;

    QJsonObject root;
    QJsonObject downloader;

    root["log_path"] = LOG_PATH;
    downloader["url"] =url;
    downloader["save_path"] = m_tmpDir->path();
    downloader["sniff_only"] = "true";
    root["downloader"] = downloader;
    QJsonDocument jsonDocument(root);
    QString jsonString = jsonDocument.toJson(QJsonDocument::Indented);
    string strJson = jsonString.toStdString();
    m_downloader.parse((char *)strJson.c_str(),this);

}
