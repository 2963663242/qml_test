import QtQuick 2.0
import QtQuick.Window 2.15
import com.Downloader 1.0
import QtQml.Models 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15

Window {
    id: root
    width: 300
    height: 600
    title: qsTr("parseDialog")
    visible: false
    flags: Qt.CustomizeWindowHint | Qt.WindowTitleHint | Qt.WindowCloseButtonHint | Qt.WindowStaysOnTopHint | Qt.MSWindowsFixedSizeDialogHint
    modality: Qt.WindowModal
    signal selectOver(string message);
    property string strUrl: "";

    function open() {
        root.show()
        loading_img.visible = true
    }

    function parseUrl(url) {
        //调用downloader.parse
        downlaoder.parse(url)
        strUrl = url;
    }

    function showParsResult(json) {
        console.log(json)
        var rootJson = JSON.parse(json)
        if (rootJson["type"] == "parsed") {
            var msg = rootJson["msg"]
            var is_live = msg['is_live']
            if (is_live === true) {
                root.title = msg["title"]
//                for(var v in msg["videos"])
//                    v["format_id"] = v["id"]
                data.clear();
                data.append(msg["videos"]);
                //console.log(msg["thumbnails"][msg["thumbnails"].length-1]["url"])
                image_thumbnail.source=msg["thumbnails"][msg["thumbnails"].length-1]["url"]
               //image_thumbnail.source = "C:\\Users\\Administrator\\AppData\\Local\\Temp\\youtubeLive-BhvZha\\7b8b3daf50f32eec2eaa2f02a61eb67e.jpg"
                live_info.visible = true;

            } else {
                text_no_live.visible = true
            }
        }
        else if(rootJson["type"] == "finished"){
            //解析完成关闭加载图标
            loading_img.visible = false
             var msg = rootJson["msg"]
            if(parseInt(msg["ret_code"]) != "1"){
                text_error.visible = true
            }
        }

    }
    AnimatedImage {
        id: loading_img
        anchors.centerIn: parent
        source: "qrc:/imgs/loading.gif"
        width: 100
        height: 100
        visible: true
    }

    FsDownloader {
        id: downlaoder
    }

    Text {
        id: text_no_live
        anchors.centerIn: parent
        visible: false
        text: qsTr("this video is not live!!!")
    }
    Text {
        id: text_error
        anchors.centerIn: parent
        visible: false
        text: qsTr("parse url error occur!!!")
    }
    Rectangle{
        id: live_info
        visible: false
        anchors.fill: parent
        ColumnLayout{
            anchors.fill: parent
                Image{

                    Layout.preferredWidth:300
                    Layout.preferredHeight:sourceSize.height * 300 / sourceSize.width
                    id:image_thumbnail
                    Layout.alignment: Qt.AlignHCenter
                }

            ListView{
                    id:chioceView
                    Layout.fillHeight: true
                    Layout.fillWidth:true
                    model:ListModel{
                        id: data
                    }
                    delegate:
                        RadioButton {
                            objectName:id
                            anchors.left: parent.left
                            anchors.leftMargin: 50
                            text: "      "+ext+"        "+quality+"P     "+filesize
                            onClicked: {

                                    btn_download.enabled=true
                            }
                        }
                }

            Button{
                id:btn_download
                text: "download"
                 Layout.alignment:Qt.AlignRight
                 enabled : false
                 onClicked: {

                       for (var i = 0; i < chioceView.count; i++) {

                           var radioButton = chioceView.itemAtIndex(i);
                           if (radioButton.checked) {
                                 var objName = radioButton.objectName


                                var rootData =   {
                                   imgUrl:image_thumbnail.source,
                                   selectData:data.get(i),
                                   url:root.strUrl,
                                   title:root.title
                               }
                                  root.selectOver(JSON.stringify(rootData));
                                  root.close()
                           }
                       }
                   }
            }
    }
    }


    Component.onCompleted: {
        downlaoder.parseSucc.connect(showParsResult)
        closing.connect(() => {
                            loading_img.visible = false
                            text_no_live.visible = false
                            text_error.visible = false
                            live_info.visible = false
                        })
    }
}
