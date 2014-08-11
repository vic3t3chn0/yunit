/*
 * Copyright 2014 Canonical Ltd.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.0
import QtTest 1.0
import Unity.Test 0.1 as UT
import ".."
import "../../../qml/Stages"
import Ubuntu.Components 0.1
import Ubuntu.Components.ListItems 1.0 as ListItem
import Unity.Application 0.1

Rectangle {
    color: "red"
    id: root
    width: units.gu(70)
    height: units.gu(70)

    QtObject {
        id: fakeApplication
        property url screenshot: ""

        function updateScreenshot() {}
        function discardScreenshot() {}

        property int state: ApplicationInfo.Running
        property string name: "Gallery"
        property url icon: "../../../qml/graphics/applicationIcons/gallery.png"

        property var surface: Image {
            source: "../../../qml/Dash/graphics/phone/screenshots/gallery@12.png"
            width: spreadDelegateLoader.width
            height: spreadDelegateLoader.height

            property var application: fakeApplication

            signal removed()
            function release() {}
        }

        property bool fullscreen: true
    }

    Component {
        id: spreadDelegateComponent
        SpreadDelegate {
            anchors.fill: parent
            swipeToCloseEnabled: swipeToCloseCheckbox.checked
            closeable: closeableCheckbox.checked
            application: fakeApplication
        }
    }
    Loader {
        id: spreadDelegateLoader
        anchors {
            top: parent.top
            bottom: parent.bottom
            left: parent.left
        }
        width: units.gu(40)
        sourceComponent: spreadDelegateComponent
    }

    Rectangle {
        color: "white"
        anchors {
            top: parent.top
            bottom: parent.bottom
            left: spreadDelegateLoader.right
            right: parent.right
        }

        Column {
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: units.gu(1) }
            spacing: units.gu(1)
            Row {
                anchors { left: parent.left; right: parent.right }
                CheckBox { id: swipeToCloseCheckbox; checked: false; }
                Label { text: "swipeToCloseEnabled" }
            }
            Row {
                anchors { left: parent.left; right: parent.right }
                CheckBox { id: closeableCheckbox; checked: false }
                Label { text: "closeable" }
            }
        }
    }

    UT.UnityTestCase {
        id: testCase
        name: "SpreadDelegate"
        when: windowShown

        SignalSpy {
            id: spyClosedSignal
            target: spreadDelegateLoader.item
            signalName: "closed"
        }

        property var dragArea

        function init() {
            dragArea = findInvisibleChild(spreadDelegateLoader.item, "dragArea");
            dragArea.__dateTime = fakeDateTime;
        }

        function cleanup() {
            // reload our test subject to get it in a fresh state once again
            spreadDelegateLoader.active = false;
            spreadDelegateLoader.active = true;

            spyClosedSignal.clear();
        }

        function test_swipeToClose_data() {
            return [
                {tag: "swipeToClose=true closeable=true -> appWindow moves away",
                 swipeToClose: true, closeable: true },

                {tag: "swipeToClose=true closeable=alse -> appWindow bounces back",
                 swipeToClose: true, closeable: false },

                {tag: "swipeToClose=false -> appWindow stays put",
                 swipeToClose: false, closeable: true },
            ]
        }

        function test_swipeToClose(data) {
            var appWindowWithShadow = findChild(spreadDelegateLoader.item, "appWindowWithShadow");

            verify(appWindowWithShadow.y === 0);

            swipeToCloseCheckbox.checked = data.swipeToClose;
            closeableCheckbox.checked = data.closeable;

            var dragDistance = spreadDelegateLoader.item.height / 2;
            var touchX = spreadDelegateLoader.item.width / 2;
            var fromY = spreadDelegateLoader.item.height / 2;
            var toY = fromY - dragDistance;
            touchFlick(spreadDelegateLoader.item,
                touchX /* fromX */,  fromY, touchX /* toX */,  toY,
                true /* beginTouch */, false /* endTouch */, dragArea.minSpeedToClose * 1.1 /* speed */);


            if (data.swipeToClose) {
                verify(appWindowWithShadow.y < 0);
                verify(Math.abs(Math.abs(appWindowWithShadow.y) - dragDistance) < units.gu(1));

                touchRelease(spreadDelegateLoader.item, touchX, toY - units.gu(1));

                waitForCloseAnimationToFinish();

                if (data.closeable) {
                    verify(spyClosedSignal.count === 1);
                } else {
                    verify(spyClosedSignal.count === 0);
                    tryCompare(appWindowWithShadow, "y", 0);
                }

            } else {
                verify(appWindowWithShadow.y === 0);

                touchRelease(spreadDelegateLoader.item, touchX, toY);
            }
        }

        function waitForCloseAnimationToFinish() {
            var closeAnimation = findInvisibleChild(spreadDelegateLoader.item, "closeAnimation");
            wait(closeAnimation.duration * 1.5);
            tryCompare(closeAnimation, "running", false);
        }

    }
}
