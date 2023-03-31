#ifndef FSDOWNLOADER_H
#define FSDOWNLOADER_H

#include <QObject>
#include "Downloader.h"
#include <QTemporaryDir>



class FsDownloader : public QObject,public STATECALLBACK
{
    Q_OBJECT
public:
    explicit FsDownloader(QObject *parent = nullptr);
    virtual void  stateInform(char* json);
   Q_INVOKABLE  void parse(QString url);
signals:
    void parseSucc(QString json);
private:
    Downloader m_downloader;
    QTemporaryDir * m_tmpDir=0;
};

#endif // FSDOWNLOADER_H