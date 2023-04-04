#ifndef FSDOWNLOADER_H
#define FSDOWNLOADER_H

#include <QObject>
#include "Downloader.h"
#include <QTemporaryDir>



class FsDownloader : public QObject,public STATECALLBACK
{
    Q_OBJECT
    Q_PROPERTY(QString savePath READ getSavePath CONSTANT)
public:
    explicit FsDownloader(QObject *parent = nullptr);
    virtual void  stateInform(char* json);
   Q_INVOKABLE  void parse(QString url);
   Q_INVOKABLE  void download(QString url,QString formatId);
    Q_INVOKABLE  QString stop(QString path);
    QString getSavePath(){

        return savePath;
    }
public:
    static QString savePath;
signals:
    void parseSucc(QString json);
private:
    Downloader m_downloader;
    QTemporaryDir * m_tmpDir=0;
};

#endif // FSDOWNLOADER_H
