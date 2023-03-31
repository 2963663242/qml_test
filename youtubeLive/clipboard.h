#ifndef CLIPBOARD_H
#define CLIPBOARD_H

#include <QObject>

class Clipboard:public QObject
{
    Q_OBJECT
public:
     Clipboard();
    Q_INVOKABLE QString getText();
};

#endif // CLIPBOARD_H
