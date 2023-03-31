#include "clipboard.h"
#include <QApplication>
#include <QClipboard>
Clipboard::Clipboard()
{

}

QString Clipboard::getText(){
    QClipboard *clipboard = QApplication::clipboard();
    QString text = clipboard->text();
    return text;
}
