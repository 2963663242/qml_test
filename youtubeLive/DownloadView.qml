import QtQuick 2.0
import QtQuick.Controls 2.0
import QtQuick.Layouts 1.15
Item {
     signal selectOver(string msg)
    ColumnLayout{
        anchors.fill: parent
        spacing: 0
//        Rectangle{
//            id: rectTab
//            property int index: 0
//            border{

//                    color:"gray"
//            }
//            Layout.fillWidth: true
//            Layout.preferredHeight: 50
//            RowLayout{
//                anchors.fill: parent
//                spacing: 10
//                Item {
//                    Layout.fillWidth: true
//                    Layout.fillHeight:true
//                }
//                Rectangle{
//                    Layout.preferredWidth: 100
//                    Layout.preferredHeight: 40
//                    Layout.alignment: Qt.AlignHCenter
//                    color:"grey"
//                    radius: 10
//                    Text{
//                         anchors.fill: parent
//                        text: qsTr("downloading")
//                        horizontalAlignment: Text.AlignHCenter
//                        verticalAlignment:  Text.AlignVCenter
//                    }
//                    MouseArea{
//                         anchors.fill: parent
//                         onClicked: {
//                              forceActiveFocus()
//                                 rectTab.index = 0;
//                         }
//                         onFocusChanged: {
//                             parent.color = activeFocus==0? "grey" : "blue"
//                         }
//                    }
//                }
//                Rectangle{
//                    Layout.preferredWidth: 100
//                    Layout.preferredHeight: 40
//                    Layout.alignment: Qt.AlignHCenter
//                    color: "grey"
//                    radius: 10
//                    Text{
//                        anchors.fill: parent
//                        text: qsTr("downloaded")
//                        horizontalAlignment: Text.AlignHCenter
//                        verticalAlignment:  Text.AlignVCenter

//                    }
//                    MouseArea{
//                         anchors.fill: parent
//                        onClicked: {
//                                forceActiveFocus()
//                                rectTab.index = 1;
//                        }
//                        onFocusChanged: {
//                            parent.color = activeFocus==0? "grey" : "blue"
//                        }
//                    }
//                }
//                Item {
//                    Layout.fillWidth: true
//                    Layout.fillHeight:true
//                }
//            }

//        }

        Rectangle{
            id:rectTabView
//           color: "blue"
            Layout.fillWidth: true
            Layout.fillHeight:true

            Rectangle{
                    anchors.fill: parent
//                    color: "red"
                   // visible: rectTab.index== 0 ? true:false
                    DownloadingView{
                        id:downloadingView
                        anchors.fill: parent
                    }
            }
//            Rectangle{
//                    anchors.fill: parent
//                    color: "blue"
//                    visible: rectTab.index== 1 ? true:false
//            }

        }

    }
    Component.onCompleted: {
        selectOver.connect(downloadingView.selectOver)

    }

}
