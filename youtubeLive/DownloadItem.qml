import QtQuick 2.0
import QtQml.Models 2.2
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.15
import com.Downloader 1.0
Item {
    id:root
    signal downloadFinished();
    enum DoloadStatus {
        Init,
        Downloading,
        Stoped,
        Error,
        Finished
    }
    property alias imgSource: imgVideo.source
    property alias vTitle: textTitle.text
    property alias vQuality: textQuality.text
    property alias vExt: textExt.text
    property double progress: 0.0
    property int state: DownloadItem.DoloadStatus.Init
    property string downloadedSize:"0"
    property string strUrl: ""
    property string format_id: ""
    property string path: ""

    RowLayout {
        anchors.fill: parent
        Image {
            id: imgVideo
            Layout.preferredWidth: 100
            Layout.preferredHeight: sourceSize.height*100/sourceSize.width
        }

       ColumnLayout{
            Layout.fillWidth: true

                Text {
                    Layout.preferredWidth: 200
                    id: textTitle

                }

             RowLayout {
                 Layout.fillWidth: true
                 Layout.bottomMargin: 30
                Text {
                    id: textQuality
                    horizontalAlignment: Qt.AlignHCenter
                    Layout.fillWidth: true
                }
                Text {
                    id: textExt
                    horizontalAlignment: Qt.AlignHCenter
                    Layout.fillWidth: true
                }
//                Text {
//                    id: textStatus
//                    text: "init"
//                    horizontalAlignment: Qt.AlignHCenter
//                    Layout.fillWidth: true
//                }
                Text {
                    id: textFilesize
                    text:downloadedSize
                    horizontalAlignment: Qt.AlignHCenter
                    Layout.fillWidth: true
                }
             }
            ProgressBar {
                  Layout.fillWidth: true
                id: progressBar
                value: progress


            }
    }
        Rectangle {
            id: btnDownload
            Layout.preferredHeight: 40
            Layout.preferredWidth: 100
            Layout.rightMargin: 20
            Text {
                anchors.fill: parent
                text: qsTr("stop")
                color: "white"
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignHCenter
            }
            MouseArea{
                anchors.fill: parent
                hoverEnabled: true
                onEntered: btnDownload.color = "black"
                onExited: btnDownload.color = "grey"
                onPressed: btnDownload.color = "blue"
                onReleased: btnDownload.color = "grey"
                onClicked: {

                   downloader.stop(path);

                }
            }
            color: "grey"
        }
    }

    FsDownloader{
        id:downloader
    }

    function stateCallback(json){
        json = JSON.parse(json)
        if(json["type"] == "downloading"){
            var msg = json["msg"]
            var dProcess = parseFloat(msg["progress"])
            progress = dProcess ;
            var filesize = parseInt(msg["filesize"])
            downloadedSize = String(Math.floor(dProcess * filesize));
        }
        if(json["type"] == "live_info"){
               path = json["msg"]["path"]

        }
        if(json["type"]=="stop"){
         downloadFinished();
        }
        if(json["type"]=="finished"){
         var msg = json["msg"]
         var ret_code = msg["ret_code"]
            if(ret_code!="0")
                downloader.saveFile(path);
            else{
                downloader.saveFile(msg["path"]);

            }
            downloadFinished();
        }
    }
    Component.onCompleted: {
        downloader.download(strUrl,format_id);
        downloader.parseSucc.connect(stateCallback);
    }

}
