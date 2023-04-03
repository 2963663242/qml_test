import QtQuick 2.15
import QtQuick.Window 2.15
import QtQuick.Controls 2.15
import com.common 1.0
import QtQuick.Layouts 1.3
import QtQuick.Controls 2.0

Window {
    width: 640
    height: 480
    visible: true
    title: qsTr("Hello World")
    function isUrl(text) {
        // 正则表达式模式
        var pattern = /^(?:\w+:)?\/\/([^\s\.]+\.\S{2}|localhost[\:?\d]*)\S*$/

        // 使用正则表达式测试文本
        return pattern.test(text)
    }
    ColumnLayout{
        anchors.fill: parent
        Button {
            text: qsTr("parse url")
            onClicked: {

                var text = clipboard.getText()
                if (!isUrl(text)) {
                    return
                }
                parseDialog.open()
                parseDialog.parseUrl(text)
            }
        }

        DownloadView{
            id:downloadView
            Layout.fillWidth: true
            Layout.fillHeight: true
        }
    }




    ParseDialog {
        id: parseDialog
    }

    Clipboard {
        id: clipboard
    }

    Component.onCompleted: {
        parseDialog.selectOver.connect(downloadView.selectOver);
    }
}
