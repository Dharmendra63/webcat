import QtQuick 2.0
import Sailfish.Silica 1.0
import "../db.js" as DB
import "../"

// ToolBar

Rectangle
{
    id: toolbarParent
    width: parent.width
    z: 91

    height: fPage.toolbarheight
    anchors.bottom: fPage.bottom
    state: "expanded"

    property alias toolbarSep: toolbarSep
    property alias webTitle: webTitle
    property alias bookmarkButton: bookmarkButton
    property alias urlText: urlText
    property alias backIcon: backIcon
    property alias forIcon: forIcon
    property alias niLeftButton: niLeftButton
    property alias niRightButton: niRightButton
    property QtObject fPage: parent

    states: [
        State {
            name: "expanded"
            PropertyChanges {
//                target: toolbar
                target: toolbarParent
                height: fPage.toolbarheight
            }
            PropertyChanges {
                target: urlTitle
                visible: false
            }
            PropertyChanges {
                target: gotoButton
                visible: true
                enabled: true
            }
            PropertyChanges {
                target: backIcon
                visible: mainWindow.toolbarSwipeAction != 1 && fPage.webview.canGoBack
                enabled: true
            }
            PropertyChanges {
                target: forIcon
                visible: mainWindow.toolbarSwipeAction != 1 && fPage.webview.canGoForward
                enabled: true
            }
            PropertyChanges {
                target: urlText
                visible: true
                enabled: true
            }
            PropertyChanges {
                target: refreshButton
                visible: true
                enabled: true
            }
            PropertyChanges {
                target: bookmarkButton
//                visible: fPage.readerMode ? true : false
                visible: false
                enabled: true
            }
            PropertyChanges {
                target: webTitle
                visible: urlText.visible
                enabled: true
            }
        },
        State {
            name: "minimized"
            PropertyChanges {
//                target: toolbar
                target: toolbarParent
                height: Math.floor(fPage.toolbarheight / 3)
            }
            PropertyChanges {
                target: urlTitle
                visible: true
            }
            PropertyChanges {
                target: gotoButton
                visible: false
                enabled: false
            }
            PropertyChanges {
                target: backIcon
                visible: false
                enabled: false
            }
            PropertyChanges {
                target: forIcon
                visible: false
                enabled: false
            }
            PropertyChanges {
                target: urlText
                visible: false
                enabled: false
            }
            PropertyChanges {
                target: refreshButton
                visible: false
                enabled: false
            }
            PropertyChanges {
                target: bookmarkButton
                visible: false
                enabled: false
            }
            PropertyChanges {
                target: webTitle
                visible: false
                enabled: false
            }
        }
    ]

    Behavior on height {
        NumberAnimation { duration: 200; easing.type: Easing.InOutQuad }
    }


    Image {
        anchors.fill: parent
        fillMode: Image.Tile
        source: "../../img/graphic-diagonal-line-texture.png"
        visible: mainWindow.privateBrowsing
        verticalAlignment: Image.AlignTop
    }


    //color: Theme.highlightBackgroundColor // As alternative perhaps maybe someday
    gradient: Gradient {
        GradientStop { position: 0.0; color: "#262626" }
        GradientStop { position: 0.85; color: "#1F1F1F"}
    }

    Rectangle { // grey seperation between page and toolbar
        id: toolbarSep
        height: 2
        width: parent.width
        anchors.top: parent.top
        color: "grey"
    }

    SilicaFlickable {

        id: content

        property QtObject ngfeffect
        property Item selectedItem: null

        anchors.fill: parent

        flickableDirection: Flickable.HorizontalFlick
        boundsBehavior: {
    //        if(!normalMode || querybar.editing || (currentTab() && !currentTab().viewStack.empty))
//                return Flickable.StopAtBounds;

            return Flickable.DragAndOvershootBounds;
        }

        Component.onCompleted: {
            ngfeffect = Qt.createQmlObject("import org.nemomobile.ngf 1.0; NonGraphicalFeedback { event: 'pulldown_highlight' }", content, 'NonGraphicalFeedback');
        }

        onContentXChanged: {
            if(!dragging)
                return;

            if(niLeftButton.visible && (contentX < (-niLeftButton.width + Theme.paddingSmall))) {
                if(selectedItem !== niLeftButton)
                    ngfeffect.play();

                selectedItem = niLeftButton;
            }
            else if(niRightButton.visible && ((contentX + width) > ((niRightButton.x + niRightButton.width) - Theme.paddingSmall))) {
                if(selectedItem !== niRightButton)
                    ngfeffect.play();

                selectedItem = niRightButton;
            }
            else {
                if(selectedItem)
                    ngfeffect.play();

                selectedItem = null;
            }
        }

        onDraggingChanged: {
            if(dragging || !webview)
                return;

            if(mainWindow.toolbarSwipeAction == 0) {
                if(selectedItem === niLeftButton)
                    mainWindow.switchToTab(mainWindow.tabModel.get(mainWindow.currentTabIndex-1).pageid);
                else if(selectedItem === niRightButton)
                    mainWindow.switchToTab(mainWindow.tabModel.get(mainWindow.currentTabIndex+1).pageid);
            } else if(mainWindow.toolbarSwipeAction == 1) {
                if(selectedItem === niLeftButton)
                    fPage.webview.goBack();
                else if(selectedItem === niRightButton)
                    fPage.webview.goForward();
            }
            selectedItem = null;
        }

        ImageButton
        {
            id: niLeftButton
            anchors { right: toolbar.left; top: parent.top; bottom: parent.bottom }
            visible:  {
                if(mainWindow.toolbarSwipeAction == 0) {
                    if (! mainWindow.currentTabIndex < 1) true
                    else false
                } else if(mainWindow.toolbarSwipeAction == 1) fPage.webview.canGoBack

            }

            width: visible ? parent.height : 0
            highlighted: content.selectedItem === niLeftButton
            source: {
                if(mainWindow.toolbarSwipeAction == 0) "image://theme/icon-m-left"
                else if(mainWindow.toolbarSwipeAction == 1) "image://theme/icon-m-back"
            }
        }

        Rectangle {
            id: toolbar
            width: parent.width
            height: parent.height
            property alias state: toolbarParent.state
            anchors.fill: parent
            color: "transparent"

            Image {
                id: webIcon
                source: fPage.webview.icon != "" ? fPage.webview.icon : "image://theme/icon-lock-social";
                height: toolbar.height - Theme.paddingSmall
                width: height
                anchors.left: toolbar.left
                anchors.leftMargin: Theme.paddingSmall
                anchors.verticalCenter: toolbar.verticalCenter
                visible: toolbar.state == "minimized"
                asynchronous: true
                onSourceChanged: favIconSaver.requestPaint()
            }
            Canvas {
                id: favIconSaver
                visible: false
                width: Theme.iconSizeLauncher
                height: width
                onImageLoaded: requestPaint();
                onPaint: {
                    //console.debug("[FirstPage.qml] favIconSaver paint called")
                    var ctx = getContext("2d")
                    ctx.clearRect(0,0,width,height);
                    ctx.reset();
                    ctx.drawImage(webIcon,0,0,width,height)
                }
            }

            Label {
                id: urlTitle
                text: fPage.webview.title + " - " + fPage.webview.url
                anchors.top: toolbar.top
                anchors.topMargin: 3
                anchors.left: webIcon.right
                anchors.leftMargin: Theme.paddingSmall
                font.bold: true
                font.pixelSize: Theme.fontSizeTiny //parent.height - 4
                visible: false
                truncationMode: TruncationMode.Fade
            }
            MouseArea {
                id: expandToolbar
                anchors.fill: toolbar
                onClicked: if (toolbar.state == "minimized") toolbar.state = "expanded"
                property int mx
    //            onPressed: {
    //                // Gesture detecting here
    //                mx = mouse.x
    //            }
    //            onReleased: {
    //                if (mx != -1 && mouse.x < mx - 150) { //Right to left swipe
    //                    fPage.webview.goBack();
    //                }
    //                else if (mx != -1 && mouse.x > mx + 150) { // Left to right swipe
    //                    fPage.webview.goForward();
    //                }
    //            }
    //            onCanceled: {
    //                mx = -1
    //            }
    //            onExited: {
    //                mx = -1
    //            }
            }

            IconButton {
                id: gotoButton
                icon.source: "image://theme/icon-m-tabs"
                anchors.left: toolbar.left
                anchors.leftMargin: Theme.paddingSmall
                height: fPage.toolbarheight / 1.5
                width: height
                icon.height: toolbar.height
                icon.width: icon.height
                anchors.verticalCenter: toolbar.verticalCenter

                onClicked: {
                        fPage.extraToolbar.hide()
                        pageStack.push(Qt.resolvedUrl("../../SelectUrl.qml"), { dataContainer: page, siteURL: fPage.webview.url, bookmarks: fPage.bookmarks, siteTitle: fPage.webview.title})
                }
//                property int mx
                property bool searchButton: false
                onPressAndHold: {
                    if (fPage.extraToolbar.opacity == 0 || fPage.extraToolbar.visible == false) {
                        fPage.extraToolbar.quickmenu = true
                        fPage.extraToolbar.show()
                        fPage.extraToolbar.height = fPage.extratoolbarheight
                        fPage.extraToolbar.minimizeButton.highlighted = true
                        mx = mouse.x
                    }
                }
                onPositionChanged: {
                    if (fPage.extraToolbar.opacity == 1 && fPage.extraToolbar.quickmenu && mouse.y > ((fPage.extratoolbarheight + fPage.toolbarheight) * -1)) {
                        //console.debug("X Position: " + mouse.x)
                        if (mouse.x > fPage.extraToolbar.newTabButton.x && mouse.x < fPage.extraToolbar.newWindowButton.x) { fPage.extraToolbar.minimizeButton.highlighted = false; fPage.extraToolbar.newTabButton.highlighted = true; fPage.extraToolbar.newWindowButton.highlighted = false; fPage.extraToolbar.closeTabButton.highlighted = false; fPage.extraToolbar.orientationLockButton.highlighted = false; fPage.extraToolbar.readerModeButton.highlighted = false; fPage.extraToolbar.searchModeButton.highlighted = false; fPage.extraToolbar.shareButton.highlighted = false; }
                        else if (mouse.x < fPage.extraToolbar.newTabButton.x) {fPage.extraToolbar.minimizeButton.highlighted = true; fPage.extraToolbar.newTabButton.highlighted = false; fPage.extraToolbar.newWindowButton.highlighted = false; fPage.extraToolbar.closeTabButton.highlighted = false; fPage.extraToolbar.orientationLockButton.highlighted = false; fPage.extraToolbar.readerModeButton.highlighted = false; fPage.extraToolbar.searchModeButton.highlighted = false; fPage.extraToolbar.shareButton.highlighted = false; }
                        else if (mouse.x > fPage.extraToolbar.newWindowButton.x && mouse.x < fPage.extraToolbar.closeTabButton.x) { fPage.extraToolbar.minimizeButton.highlighted = false; fPage.extraToolbar.newTabButton.highlighted = false; fPage.extraToolbar.newWindowButton.highlighted = true; fPage.extraToolbar.closeTabButton.highlighted = false; fPage.extraToolbar.orientationLockButton.highlighted = false; fPage.extraToolbar.readerModeButton.highlighted = false; fPage.extraToolbar.searchModeButton.highlighted = false; fPage.extraToolbar.shareButton.highlighted = false; }
                        else if (mouse.x > fPage.extraToolbar.closeTabButton.x && mouse.x < fPage.extraToolbar.orientationLockButton.x) { fPage.extraToolbar.minimizeButton.highlighted = false; fPage.extraToolbar.newTabButton.highlighted = false; fPage.extraToolbar.newWindowButton.highlighted = false; fPage.extraToolbar.closeTabButton.highlighted = true; fPage.extraToolbar.orientationLockButton.highlighted = false; fPage.extraToolbar.readerModeButton.highlighted = false; fPage.extraToolbar.searchModeButton.highlighted = false; fPage.extraToolbar.shareButton.highlighted = false; }
                        else if (mouse.x > fPage.extraToolbar.orientationLockButton.x && mouse.x < fPage.extraToolbar.orientationLockButton.x + fPage.extraToolbar.orientationLockButton.width + Theme.paddingMedium) { fPage.extraToolbar.minimizeButton.highlighted = false; fPage.extraToolbar.newTabButton.highlighted = false; fPage.extraToolbar.newWindowButton.highlighted = false; fPage.extraToolbar.closeTabButton.highlighted = false; fPage.extraToolbar.orientationLockButton.highlighted = true; fPage.extraToolbar.readerModeButton.highlighted = false; fPage.extraToolbar.searchModeButton.highlighted = false; fPage.extraToolbar.shareButton.highlighted = false; }
                        else if (mouse.x > fPage.extraToolbar.readerModeButton.x && mouse.x < fPage.extraToolbar.readerModeButton.x + fPage.extraToolbar.readerModeButton.width + Theme.paddingMedium) { fPage.extraToolbar.minimizeButton.highlighted = false; fPage.extraToolbar.newTabButton.highlighted = false; fPage.extraToolbar.newWindowButton.highlighted = false; fPage.extraToolbar.closeTabButton.highlighted = false; fPage.extraToolbar.orientationLockButton.highlighted = false; fPage.extraToolbar.readerModeButton.highlighted = true; fPage.extraToolbar.searchModeButton.highlighted = false; fPage.extraToolbar.shareButton.highlighted = false; }
                        else if (mouse.x > fPage.extraToolbar.searchModeButton.x && mouse.x < fPage.extraToolbar.searchModeButton.x + fPage.extraToolbar.searchModeButton.width + Theme.paddingMedium) { fPage.extraToolbar.minimizeButton.highlighted = false; fPage.extraToolbar.newTabButton.highlighted = false; fPage.extraToolbar.newWindowButton.highlighted = false; fPage.extraToolbar.closeTabButton.highlighted = false; fPage.extraToolbar.orientationLockButton.highlighted = false; fPage.extraToolbar.readerModeButton.highlighted = false; fPage.extraToolbar.searchModeButton.highlighted = true; fPage.extraToolbar.shareButton.highlighted = false;}
                        else if (mouse.x > fPage.extraToolbar.shareButton.x && mouse.x < fPage.extraToolbar.shareButton.x + fPage.extraToolbar.shareButton.width + Theme.paddingMedium) { fPage.extraToolbar.minimizeButton.highlighted = false; fPage.extraToolbar.newTabButton.highlighted = false; fPage.extraToolbar.newWindowButton.highlighted = false; fPage.extraToolbar.closeTabButton.highlighted = false; fPage.extraToolbar.orientationLockButton.highlighted = false; fPage.extraToolbar.readerModeButton.highlighted = false; fPage.extraToolbar.searchModeButton.highlighted = false; fPage.extraToolbar.shareButton.highlighted = true; }
                        else if (mouse.x > fPage.extraToolbar.shareButton.x + fPage.extraToolbar.shareButton.width + Theme.paddingMedium) { fPage.extraToolbar.minimizeButton.highlighted = false; fPage.extraToolbar.newTabButton.highlighted = false; fPage.extraToolbar.newWindowButton.highlighted = false; fPage.extraToolbar.closeTabButton.highlighted = false; fPage.extraToolbar.orientationLockButton.highlighted = false; fPage.extraToolbar.readerModeButton.highlighted = false; fPage.extraToolbar.searchModeButton.highlighted = false; fPage.extraToolbar.shareButton.highlighted = false; }
                    }
                    if (mouse.y < ((fPage.extratoolbarheight + fPage.toolbarheight) * -1)) {
                        fPage.extraToolbar.minimizeButton.highlighted = false;
                        fPage.extraToolbar.newTabButton.highlighted = false;
                        fPage.extraToolbar.newWindowButton.highlighted = false;
                        fPage.extraToolbar.closeTabButton.highlighted = false;
                        fPage.extraToolbar.orientationLockButton.highlighted = false;
                        fPage.extraToolbar.readerModeButton.highlighted = false;
                        fPage.extraToolbar.searchModeButton.highlighted = false;
                        fPage.extraToolbar.shareButton.highlighted = false;
                        tabListOverlay.curTab = mainWindow.tabModel.getIndexFromId(mainWindow.currentTab);
                        tabListOverlay.tabCount = tabListOverlay.list.count;
                        for (var i=1; i <= tabListOverlay.tabCount ; i++) {
                               if (mouse.y < (fPage.toolbarheight + Theme.paddingSmall) * -(i+1) && mouse.y > (fPage.toolbarheight + Theme.paddingSmall) * -(i+2)) {
                                   tabListOverlay.list.currentIndex = tabListOverlay.curIndex = tabListOverlay.list.count - i
                                   break;
                               }
                        }

        //                    if (mouse.y < fPage.toolbarheight * -2 && mouse.y > fPage.toolbarheight * -3) {
        //                        tabListOverlay.list.currentIndex = tabListOverlay.list.count - 1
        //                        tabListOverlay.curIndex = tabListOverlay.list.count - 1
        //                    }
        //                    if (mouse.y < fPage.toolbarheight * -3 && mouse.y > fPage.toolbarheight * -4) {
        //                        tabListOverlay.list.currentIndex = tabListOverlay.list.count - 2
        //                        tabListOverlay.curIndex = tabListOverlay.list.count - 2
        //                    }
        //                    if (mouse.y < fPage.toolbarheight * -4 && mouse.y > fPage.toolbarheight * -5) {
        //                         tabListOverlay.list.currentIndex = tabListOverlay.list.count - 3
        //                         tabListOverlay.curIndex = tabListOverlay.list.count - 3
        //                    }
                    }
                }

    //            onReleased: {
    //                if (fPage.extraToolbar.opacity == 1 && fPage.extraToolbar.quickmenu && fPage.extraToolbar.minimizeButton.highlighted == true) fPage.extraToolbar.minimizeButton.clicked(undefined)
    //                else if (fPage.extraToolbar.opacity == 1 && fPage.extraToolbar.quickmenu && fPage.extraToolbar.newTabButton.highlighted == true) fPage.extraToolbar.newTabButton.clicked(undefined)
    //                else if (fPage.extraToolbar.opacity == 1 && fPage.extraToolbar.quickmenu && fPage.extraToolbar.newWindowButton.highlighted == true) fPage.extraToolbar.newWindowButton.clicked(undefined)
    //                else if (fPage.extraToolbar.opacity == 1 && fPage.extraToolbar.quickmenu && fPage.extraToolbar.closeTabButton.highlighted == true) fPage.extraToolbar.closeTabButton.clicked(undefined)
    //                else if (fPage.extraToolbar.opacity == 1 && fPage.extraToolbar.quickmenu && fPage.extraToolbar.orientationLockButton.highlighted == true) fPage.extraToolbar.orientationLockButton.clicked(undefined)
    //                else if (fPage.extraToolbar.opacity == 1 && fPage.extraToolbar.quickmenu && fPage.extraToolbar.readerModeButton.highlighted == true) fPage.extraToolbar.readerModeButton.clicked(undefined)
    //                else if (fPage.extraToolbar.opacity == 1 && fPage.extraToolbar.quickmenu && fPage.extraToolbar.searchModeButton.highlighted == true) fPage.extraToolbar.searchModeButton.clicked(undefined)
    //                else if (fPage.extraToolbar.opacity == 1 && fPage.extraToolbar.quickmenu && fPage.extraToolbar.shareButton.highlighted == true) fPage.extraToolbar.shareButton.clicked(undefined)
    //                else if (fPage.extraToolbar.opacity == 1 && fPage.extraToolbar.quickmenu && mouse.y > ((fPage.extratoolbarheight + fPage.toolbarheight) * -1)) fPage.extraToolbar.hide()
    //                else if (fPage.extraToolbar.opacity == 1 && fPage.extraToolbar.quickmenu && mouse.y < ((fPage.extratoolbarheight + fPage.toolbarheight) * -1)) {
    //                    // tabListOverlay.list click curent index item
    //                    if (tabListOverlay.curTab == tabListOverlay.list.currentIndex) { tabListOverlay.hideTriggered(); }
    //                    else {
    //                        console.debug("[FirstPage.qml] tabListOverlay.curIndex = " + tabListOverlay.curIndex + " ; tabListOverlay.list.currentIndex = " + tabListOverlay.list.currentIndex);
    //                        tabListOverlay.hideTriggered();
    //                        mainWindow.switchToTab(mainWindow.tabModel.get(tabListOverlay.curIndex).pageid);
    //                    }
    //                } // last else if
    //            }

                Label {
                    id: tabNumberLbl
                    text: mainWindow.tabModel.count
                    anchors.centerIn: parent
                    font.pixelSize: Theme.fontSizeExtraSmall
                    font.bold: true
                    color: gotoButton.down ? Theme.highlightColor : Theme.primaryColor
                    horizontalAlignment: Text.AlignHCenter
                }
                ProgressCircle {
                    id: progressCircle
                    z: 2
                    anchors.centerIn: parent
                    visible: urlLoading && toolbar.state == "expanded"
                    height: gotoButton.height - Theme.paddingMedium
                    width: height
                    Timer {
                        interval: 32
                        repeat: true
                        onTriggered: progressCircle.value = (progressCircle.value + 0.005) % 1.0
                        running: urlLoading
                    }
                }
            }

            IconButton {
                id:backIcon
                icon.source: "image://theme/icon-m-back"
                height: fPage.toolbarheight / 1.5
                width: height
                enabled: fPage.webview.canGoBack
                visible: mainWindow.toolbarSwipeAction != 1 && fPage.webview.canGoBack
                anchors.left: gotoButton.right
                anchors.leftMargin: Theme.paddingMedium
                onClicked: {
                    fPage.webview.goBack();
                    forIcon.visible = true;
                }
                anchors.verticalCenter: toolbar.verticalCenter
                icon.height: toolbar.height
                icon.width: icon.height
            }

            IconButton {
                id: forIcon
                icon.source: "image://theme/icon-m-forward"
                height: fPage.toolbarheight / 1.5
                width: height
                enabled: fPage.webview.canGoForward
                visible: mainWindow.toolbarSwipeAction != 1 && fPage.webview.canGoForward
                anchors.left: backIcon.visible ? backIcon.right : gotoButton.right
                anchors.leftMargin: Theme.paddingMedium
                onClicked: {
                    fPage.webview.goForward();
                }
                anchors.verticalCenter: toolbar.verticalCenter
                icon.height: toolbar.height
                icon.width: icon.height
            }


            Label {
                id: webTitle
                text: fPage.webview.title

                anchors.top: toolbar.top
                anchors.topMargin: Theme.paddingSmall
                anchors.left: {
                    if (forIcon.visible) return forIcon.right
                    else if (backIcon.visible) return backIcon.right
                    else return gotoButton.right
                }
                anchors.leftMargin: Theme.paddingMedium
                font.bold: true
                font.pixelSize: height //parent.height - 4
                visible: false
                onVisibleChanged: {
                    if (visible) {
                        urlText.anchors.topMargin = Theme.paddingSmall / 2
                        height = Theme.fontSizeSmall / 1.337 + Theme.paddingSmall
                    }
                    else {
                        urlText.anchors.topMargin = parent.height / 2 - urlText.height / 4
                        height = 0
                    }
                }

                color: urlText.color
                height: 0
                Behavior on height {
                        NumberAnimation { duration: 200 }
                }
                width: urlText.width
                truncationMode: TruncationMode.Fade
                MouseArea {
                    enabled: parent.visible
                    anchors.fill: parent
                    onClicked: {
                        urlText.forceActiveFocus()
                    }
                }
            }
            // Url textbox here
            TextField{
                id: urlText
                visible: true
                text: simplifyUrl(url)
                inputMethodHints: Qt.ImhUrlCharactersOnly
                placeholderText: qsTr("Enter an url")
                font.pixelSize: {
                    if (webTitle.height != 0 && !focus) Theme.fontSizeTiny
                    else Theme.fontSizeMedium
                }
                //y: parent.height / 2 - height / 4
                anchors.top: {
                    if (webTitle.height != 0 && webTitle.text != "") webTitle.bottom
                    else parent.top
                }
                anchors.topMargin: parent.height / 2 - height / 4
                background: null
                color: Theme.primaryColor
                property string fullUrl: url
                anchors.left: {
                    if (forIcon.visible) return forIcon.right
                    else if (backIcon.visible) return backIcon.right
                    else return gotoButton.right
                }
                anchors.leftMargin: Theme.paddingVerySmall
                anchors.right: refreshButton.left
                anchors.rightMargin: Theme.paddingVerySmall
                width: { //180 // minimum
                    if (backIcon.visible === false && forIcon.visible === false) return parent.width - gotoButton.width - refreshButton.width
                    else if (backIcon.visible === true && forIcon.visible === false) return parent.width - gotoButton.width - refreshButton.width - backIcon.width
                    else if (backIcon.visible === false && forIcon.visible === true) return parent.width - gotoButton.width - refreshButton.width - forIcon.width
                    else if (backIcon.visible === true && forIcon.visible === true) return parent.width - gotoButton.width - refreshButton.width - backIcon.width - backIcon.width
                }
                onFocusChanged: {
                    if (focus) {
                        backIcon.visible = false
                        forIcon.visible = false
                        bookmarkButton.visible = true
                        gotoButton.searchButton = true
                        text = fullUrl
                        color = Theme.primaryColor
                        suggestionView.visible = false
                        webTitle.visible = false
                        selectAll();
                    }
                    else {
                        backIcon.visible = fPage.webview.canGoBack
                        forIcon.visible = fPage.webview.canGoForward
//                        if (!fPage.readerMode)
                            bookmarkButton.visible = false
                        gotoButton.searchButton = false
                        text = simplifyUrl(url)
                        if (webTitle.text != "") {
                            webTitle.visible = urlText.visible
                        }
                    }
                }
                onTextChanged: {
                    mainWindow.historyModel.clear();
                    if (text.length > 1 && focus == true) {
                        DB.searchHistory(text.toString());
                    }
                    else {
                        fPage.suggestionView.visible = false;
                    }
                }

                Keys.onEnterPressed: {
                    if (fPage.suggestionView.visible) fPage.suggestionView.visible = false;
                    fPage.webview.url = fixUrl(urlText.text);
                    urlText.focus = false;  // Close keyboard
                    fPage.webview.focus = true;
                }

                Keys.onReturnPressed: {
                    if (fPage.suggestionView.visible) fPage.suggestionView.visible = false;
                    fPage.webview.url = fixUrl(urlText.text);
                    urlText.focus = false;
                    fPage.webview.focus = true;
                }
                function simplifyUrl(url) {
                    url = url.toString();
                    if(url.match(/http:\/\//))
                    {
                        color = Theme.primaryColor
                        url = url.substring(7);
                    }
                    if(url.match(/https:\/\//))
                    {
                        color = "lightgreen" // Indicator for https
                        url = url.substring(8);
                    }
                    if(url.match(/^www\./))
                    {
                        url = url.substring(4);
                    }
                    return url;
                }
            }


            IconButton {
                id: refreshButton
                icon.source: {
                    if (urlText.focus) "image://theme/icon-m-refresh"
                    else fPage.webview.loading ? "image://theme/icon-m-reset" : "image://theme/icon-m-menu"
                }
                onClicked: {
                    if (fPage.webview.loading) fPage.webview.stop()
                    else if (icon.source == "image://theme/icon-m-refresh") fPage.webview.reload()
                    else if (fPage.extraToolbar.opacity == 0 || fPage.extraToolbar.visible == false) {
                        fPage.extraToolbar.quickmenu = false
                        fPage.extraToolbar.show()
                    }
                    else if (fPage.extraToolbar.opacity == 1 || fPage.extraToolbar.visible == true) {
                        fPage.extraToolbar.hide()
                    }
                }
                anchors.right: {
//                    if (urlText.focus || fPage.readerMode) bookmarkButton.left
                    if (urlText.focus) bookmarkButton.left
                    else parent.right
                }
                anchors.rightMargin: Theme.paddingMedium
                visible:true
                height: fPage.toolbarheight / 1.5
                width: height
                anchors.verticalCenter: toolbar.verticalCenter
                icon.height: toolbar.height
                icon.width: icon.height
            }


            IconButton {
                id: bookmarkButton
                property bool favorited: bookmarks.count > 0 && bookmarks.contains(fPage.webview.url)
                icon.source: {
//                    if (fPage.readerMode)
//                        fPage.nightMode ? "image://theme/icon-camera-wb-sunny" : "image://theme/icon-camera-wb-tungsten"
//                    else
                        favorited ? "image://theme/icon-m-favorite-selected" : "image://theme/icon-m-favorite"
                }
                anchors.right: parent.right
                anchors.rightMargin: Theme.paddingSmall
                height: fPage.toolbarheight / 1.5
                width: height
                anchors.verticalCenter: toolbar.verticalCenter
                icon.height: toolbar.height
                icon.width: icon.height
                onClicked: {
//                    if (fPage.readerMode) {
//                        if (!nightMode)
//                            fPage.webview.experimental.evaluateJavaScript("document.body.style.backgroundColor=\"#262626\"; document.body.style.color=\"#FFFFFF\"");
//                        else
//                            fPage.webview.experimental.evaluateJavaScript("document.body.style.backgroundColor=\"#f4f4f4\"; document.body.style.color=\"#000000\"");

//                        nightMode = !nightMode
//                    }
//                    else {
                        if (favorited) {
                            bookmarks.removeBookmark(fPage.webview.url.toString())
                        } else {
                            bookmarks.addBookmark(fPage.webview.url.toString(), fPage.webview.title, userAgent)
                        }
//                    }
                }
                onPressAndHold: {
                    favIconSaver.loadImage(webIcon.source)
                    //console.debug("[FirstPage.qml] favIconSaver image loaded: " + favIconSaver.isImageLoaded(webIcon.source));
                    var favIconPath = _fm.getHome() + "/.local/share/applications/" + mainWindow.findHostname(fPage.webview.url) + "-" + mainWindow.findBaseName(fPage.webview.url) + ".png"
                    var savingFav = favIconSaver.save(favIconPath);
                    //console.debug("[FirstPage.qml] Saving FavIcon: " + savingFav)
                    mainWindow.infoBanner.parent = page
                    mainWindow.infoBanner.anchors.top = fPage.top
                    mainWindow.createDesktopLauncher(favIconPath ,fPage.webview.title,fPage.webview.url);
                    mainWindow.infoBanner.showText(qsTr("Created Desktop Launcher for " + fPage.webview.title));
                }
            }
        }

        ImageButton
        {
            id: niRightButton
            anchors { left: toolbar.right; top: parent.top; bottom: parent.bottom }
            visible: {
                if(mainWindow.toolbarSwipeAction == 0) {
                    if (mainWindow.currentTabIndex < mainWindow.tabModel.count-1) true
                    else false
                } else if(mainWindow.toolbarSwipeAction == 1) fPage.webview.canGoForward
            }
            width: visible ? parent.height : 0
            highlighted: content.selectedItem === niRightButton
            source: {
                if(mainWindow.toolbarSwipeAction == 0) "image://theme/icon-m-right"
                else if(mainWindow.toolbarSwipeAction == 1) "image://theme/icon-m-forward"
            }
        }
    }
}
