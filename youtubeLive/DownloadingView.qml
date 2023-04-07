import QtQuick 2.0
import QtQuick.Layouts 1.15
import QtQml.Models 2.15
import QtQuick.Controls 2.15
import com.Downloader 1.0
Item {
    signal selectOver(string msg)
    ColumnLayout {
        anchors.fill: parent
        ListView {
            id: chioceView
            Layout.fillHeight: true
            Layout.fillWidth: true
            model: ListModel {
                id: listdata
//                ListElement {
//                    imgUrl: "https://lh3.googleusercontent.com/a/AGNmyxblCKLVZfXAQLGRnH1hspikwsLXFrNlOV6k3vhN=s128-b16-cc-rp-mo"
//                    title: "hello"
//                    quality: "1080"
//                    ext: "mp4"
//                }
//                ListElement {
//                    imgUrl: "https://lh3.googleusercontent.com/a/AGNmyxblCKLVZfXAQLGRnH1hspikwsLXFrNlOV6k3vhN=s128-b16-cc-rp-mo"
//                    title: "world"
//                    quality: "720"
//                    ext: "mp4"
//                }
            }
            delegate:

                DownloadItem {
                 id:downloadItem
                format_id: formatId
                strUrl:url
                width: parent.width
                height:100
                imgSource: imgUrl
                vTitle:title
                vQuality: quality
                vExt:ext
                  onDownloadFinished: {
                      var index = 0;
                      for(var i=0;i<chioceView.count;i++){

                            var item = chioceView.itemAtIndex(i)
                            if(item == downloadItem){
                                listdata.remove(i)
                                //chioceView.count-=1
                                break;
                            }
                        }
//                      var index = listdata.indexFor(downloadItem)
//                      if (index >= 0) {
//                             listdata.remove(index)
//                         }
                     // visible=false;
                  }
                }

        }

        Rectangle{
            Layout.fillHeight: true
             Layout.fillWidth: true
        }
        Button{
            text: "open saveDir"
            onClicked: {

                Qt.openUrlExternally(downloader.savePath)
            }
        }
    }

    FsDownloader{
        id:downloader
    }

    Component.onCompleted: {
        selectOver.connect((msg)=>{
                            msg = JSON.parse(msg)
                           var selectData = msg["selectData"]
                           listdata.append({
                                        formatId:selectData["id"],
                                        url:msg["url"],
                                        imgUrl:msg["imgUrl"],
                                        title:msg["title"],
                                        quality:selectData["quality"],
                                        ext:selectData["ext"]
                                       })

                           })
    }

}
