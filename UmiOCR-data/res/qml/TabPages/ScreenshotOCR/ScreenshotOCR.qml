// ==============================================
// =============== 功能页：截图OCR ===============
// ==============================================

import QtQuick 2.15

import ".."
import "../../Widgets"
import "../../Widgets/ResultLayout"
import "../../Widgets/ImageViewer"

TabPage {
    id: tabPage
    // 配置
    ScreenshotOcrConfigs { id: screenshotOcrConfigs } 
    configsComp: screenshotOcrConfigs
    
    // TODO: 测试用
    Timer {
        interval: 200
        running: true
        onTriggered: {
            // screenshot()
            imageViewer.setSource("file:///D:/Pictures/Screenshots/屏幕截图 2023-04-23 191053.png")
        }
    }

    // ========================= 【逻辑】 =========================

    // 开始截图
    function screenshot() {
        const grabList = tabPage.callPy("screenshot")
        ssWindowManager.create(grabList)
    }

    // 截图完毕
    function screenshotEnd(argd) {
        const x = argd["clipX"], y = argd["clipY"], w = argd["clipW"], h = argd["clipH"]
        if(x < 0 || y < 0 || w <= 0 || h <= 0) // 裁切区域无实际像素
            return
        const configDict = screenshotOcrConfigs.getConfigValueDict()
        const clipID = tabPage.callPy("screenshotEnd", argd, configDict)
        if(clipID.startsWith("[Error]")) {
            qmlapp.popup.message(qsTr("截图裁切异常"), clipID, "error")
            return
        }
        imageViewer.setSource("image://pixmapprovider/"+clipID)
    }

    // 开始粘贴
    function paste() {
        const configDict = screenshotOcrConfigs.getConfigValueDict()
        const pasteID = tabPage.callPy("paste", configDict)
        if(pasteID.startsWith("[Error]")) {
            qmlapp.popup.message(qsTr("获取剪贴板异常"), pasteID, "error")
            return
        }
        else if(pasteID === "[Warning] No image.") {
            qmlapp.popup.simple(qsTr("剪贴板中未找到图片"), "")
            return
        }
        imageViewer.setSource("image://pixmapprovider/"+pasteID)
    }

    // ========================= 【python调用qml】 =========================
    
    // 获取一个OCR的返回值
    function onOcrGet(imgID, res) {
        // 添加到结果
        imageViewer.setSource("image://pixmapprovider/"+imgID)
        resultsTableView.addOcrResult(res)
        // 若tabPanel面板的下标没有变化过，则切换到记录页
        if(tabPanel.indexChangeNum < 2)
            tabPanel.currentIndex = 1
    }

    // ========================= 【布局】 =========================

    // 截图窗口管理器
    ScreenshotWindowManager{
        id: ssWindowManager
        screenshotEnd: tabPage.screenshotEnd
    }

    // 左控制栏
    Item {
        id: leftCtrlPanel
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.margins: theme.spacing
        width: 32

        Column {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            spacing: theme.spacing

            Item {
                anchors.left: parent.left
                anchors.right: parent.right
                height: width
            }

            IconButton {
                anchors.left: parent.left
                anchors.right: parent.right
                height: width
                icon_: "screenshot"
                color: theme.textColor
                toolTip: qsTr("屏幕截图")
                onClicked: tabPage.screenshot()
            }
            IconButton {
                anchors.left: parent.left
                anchors.right: parent.right
                height: width
                icon_: "paste"
                color: theme.textColor
                toolTip: qsTr("粘贴图片")
                onClicked: tabPage.paste()
            }
        }
    }
    // 主区域：双栏面板
    DoubleColumnLayout {
        anchors.left: leftCtrlPanel.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        initSplitterX: 0.5

        // 左面板
        leftItem: Panel {
            anchors.fill: parent

            ImageViewer {
                id: imageViewer
                anchors.fill: parent
            }
        }

        // 右面板
        rightItem: Panel {
            anchors.fill: parent

            TabPanel {
                id: tabPanel
                anchors.fill: parent
                anchors.margins: theme.spacing

                // 结果面板
                ResultsTableView {
                    id: resultsTableView
                    anchors.fill: parent
                    visible: false
                }

                tabsModel: [
                    {
                        "key": "configs",
                        "title": qsTr("设置"),
                        "component": screenshotOcrConfigs.panelComponent,
                    },
                    {
                        "key": "ocrResult",
                        "title": qsTr("记录"),
                        "component": resultsTableView,
                    },
                ]
            }
        }
    }
}