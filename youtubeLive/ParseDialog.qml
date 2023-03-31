import QtQuick 2.0
import QtQuick.Window 2.15
import com.Downloader 1.0
Window{
    id:root
    width: 300
    height: 600
    title: qsTr("parseDialog")
    visible: false
    modality: Qt.WindowModal
    function open(){
        root.show();
        loading_img.visible=true;
    }

    function parseUrl(url){
        //调用downloader.parse
        downlaoder.parse(url);
    }

    function showParsResult(json){
        console.log(json);
        loading_img.visible=false;
       var root = JSON.parse(json);
       var msg = root["msg"];
       var is_live = msg['is_live']
        if(is_live === true){

        }
        else{
            error_text.visible=true;
        }
    }
    AnimatedImage {
            id:loading_img
            anchors.centerIn: parent
            source: "qrc:/imgs/loading.gif"
            width: 100
            height: 100
            visible: true
        }


    FsDownloader{
        id:downlaoder
    }

    Text{
        id: error_text
        anchors.centerIn: parent
        visible: false
        text: qsTr("this video is not live!!!");
    }



    Component.onCompleted: {
        downlaoder.parseSucc.connect(showParsResult);
        closing.connect(()=>{
                         loading_img.visible=false;
                         error_text.visible=false;
                        })
    }


}
