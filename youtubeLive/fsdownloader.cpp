#include "fsdownloader.h"
#include <QCoreApplication>
#include <iostream>
#include <QJsonObject>
#include <QJsonDocument>
#include <QJsonParseError>
#include <qDebug>
using namespace std;

#define LOG_PATH "Log"

QString initSavePath();

QString FsDownloader::savePath = initSavePath();

FsDownloader::FsDownloader(QObject *parent) : QObject(parent)
{

    static bool configSuss = [](){
        Downloader::setLogPath((char *)LOG_PATH);
        std::string exePath = QCoreApplication::applicationDirPath().toLocal8Bit().toStdString();
        Downloader::setexePath((char *)exePath.c_str());
        return true;
    }();
}


void FsDownloader::stateInform(char * json){
   // cout << json << endl;
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
     cout << json << endl;
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

void FsDownloader::download(QString url,QString formatId){
    if(m_tmpDir)
        delete m_tmpDir;
    m_tmpDir = new QTemporaryDir;

    QJsonObject root;
    QJsonObject downloader;

    root["log_path"] = LOG_PATH;
    root["ffmpeg_location"] = QCoreApplication::applicationDirPath()+"/winBin";
    downloader["url"] =url;
    downloader["save_path"] = m_tmpDir->path();
    downloader["sniff_only"] = "false";
    downloader["custom_format"]=formatId;
    root["downloader"] = downloader;
    QJsonDocument jsonDocument(root);
    QString jsonString = jsonDocument.toJson(QJsonDocument::Indented);
    string strJson = jsonString.toStdString();
    m_downloader.download((char *)strJson.c_str(),this);

}


QString FsDownloader::stop(QString path){

    m_downloader.stop(this);
    
    return saveFile(path);
}

QString FsDownloader::saveFile(QString path){
    QString ext;
     QFileInfo fileInfo(path);
     bool isFile = fileInfo.isFile();
     cout <<path.toStdString()<< "is File : " << isFile << endl;
   QString filename = fileInfo.fileName();
   ext = filename.mid(filename.lastIndexOf("."),filename.length()-filename.lastIndexOf("."));
   if(ext == ".part")
        filename = filename.mid(0,filename.lastIndexOf("."));

   QString newPath = FsDownloader::savePath +"/"+filename;
   cout << "newPath:"<<newPath.toStdString() << endl;
    bool ret =  QFile::copy(path, newPath);
    cout << "copy result: " << ret << endl;
     return newPath;
}
QString initSavePath(){

    QDir currentDir = QDir::current();
    QString path =  currentDir.absoluteFilePath("videos");
    QDir dir;

    if (!dir.exists(path)) {
       bool res =  dir.mkpath(path);
       qDebug() << "新建目录是否成功" << res;
    }
    return path;
}
