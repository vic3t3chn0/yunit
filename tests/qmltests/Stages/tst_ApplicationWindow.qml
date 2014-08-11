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

    Component {
        id: fakeSurfaceComponent
        Image {
            source: "../../../qml/Dash/graphics/phone/screenshots/gallery@12.png"
            width: applicationWindowLoader.width
            height: applicationWindowLoader.height

            property var application: fakeApplication
            property int touchPressCount: 0
            property int touchReleaseCount: 0

            Text {
                anchors.fill: parent
                text: "SURFACE"
                color: "yellow"
                font.bold: true
                fontSizeMode: Text.Fit
                minimumPixelSize: 10; font.pixelSize: 200
                verticalAlignment: Text.AlignVCenter
            }

            MultiPointTouchArea {
                anchors.fill: parent
                onPressed: { touchPressCount++; }
                onReleased: { touchReleaseCount++; }
            }

            signal removed()

            function release() {
                fakeApplication.surface = null;
                parent = null;
                removed();
                surfaceCheckbox.checked = false;
            }
        }
    }

    QtObject {
        id: fakeApplication
        property url screenshot: ""

        function updateScreenshot() {
            fakeScreenshotTimer.start();
        }

        function discardScreenshot() {
            screenshot = "";
        }

        property alias state: appStateSelector.selectedApplicationState
        property string name: "Gallery"
        property url icon: "../../../qml/graphics/applicationIcons/gallery.png"
        property var surface: null
        property bool fullscreen: true
        property list<Item> childSurfaces
    }
    Timer {
        id: fakeScreenshotTimer
        interval: 100
        onTriggered: {
            fakeApplication.screenshot = "../../../qml/Dash/graphics/phone/screenshots/gallery@12.png";
        }
    }

    Component {
        id: applicationWindowComponent
        ApplicationWindow {
            anchors.fill: parent
            application: fakeApplication
        }
    }
    Loader {
        id: applicationWindowLoader
        anchors {
            top: parent.top
            bottom: parent.bottom
            left: parent.left
        }
        width: units.gu(40)
        sourceComponent: applicationWindowComponent
    }

    Rectangle {
        color: "white"
        anchors {
            top: parent.top
            bottom: parent.bottom
            left: applicationWindowLoader.right
            right: parent.right
        }

        Column {
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: units.gu(1) }
            spacing: units.gu(1)
            Row {
                anchors { left: parent.left; right: parent.right }
                CheckBox {
                    id: surfaceCheckbox; checked: false
                    onCheckedChanged: {
                        if (applicationWindowLoader.status !== Loader.Ready)
                            return;

                        if (checked && !fakeApplication.surface) {
                            fakeApplication.surface = fakeSurfaceComponent.createObject(null, {});
                        } else if (!checked && fakeApplication.surface) {
                            fakeApplication.surface.release();
                        }
                    }
                }
                Label { text: "Surface" }
            }
            ListItem.ItemSelector {
                id: appStateSelector
                anchors { left: parent.left; right: parent.right }
                text: "Application state"
                model: ["Starting",
                        "Running",
                        "Suspended",
                        "Stopped"]
                property int selectedApplicationState: {
                    if (model[selectedIndex] === "Starting") {
                        return ApplicationInfo.Starting;
                    } else if (model[selectedIndex] === "Running") {
                        return ApplicationInfo.Running;
                    } else if (model[selectedIndex] === "Suspended") {
                        return ApplicationInfo.Suspended;
                    } else {
                        return ApplicationInfo.Stopped;
                    }
                }
            }
        }
    }

    UT.UnityTestCase {
        id: testCase
        name: "ApplicationWindow"
        when: windowShown

        // just to make them shorter
        property int appStarting: ApplicationInfo.Starting
        property int appRunning: ApplicationInfo.Running
        property int appSuspended: ApplicationInfo.Suspended
        property int appStopped: ApplicationInfo.Stopped

        function setApplicationState(appState) {
            switch (appState) {
            case appStarting:
                appStateSelector.selectedIndex = 0;
                break;
            case appRunning:
                appStateSelector.selectedIndex = 1;
                break;
            case appSuspended:
                appStateSelector.selectedIndex = 2;
                break;
            case appStopped:
                appStateSelector.selectedIndex = 3;
                break;
            }
        }

        function cleanup() {
            // reload our test subject to get it in a fresh state once again
            applicationWindowLoader.active = false;

            appStateSelector.selectedIndex = 0;
            surfaceCheckbox.checked = false;

            fakeScreenshotTimer.stop();
            fakeApplication.screenshot = "";
            fakeApplication.surface = null;

            applicationWindowLoader.active = true;
        }

        function test_showSplashUntilAppFullyInit1() {
            var stateGroup = findInvisibleChild(applicationWindowLoader.item, "applicationWindowStateGroup");

            verify(stateGroup.state === "splashScreen");

            setApplicationState(appRunning);

            verify(stateGroup.state === "splashScreen");

            surfaceCheckbox.checked = true;

            tryCompare(stateGroup, "state", "surface");
        }

        function test_showSplashUntilAppFullyInit2() {
            var stateGroup = findInvisibleChild(applicationWindowLoader.item, "applicationWindowStateGroup");

            verify(stateGroup.state === "splashScreen");

            surfaceCheckbox.checked = true;

            verify(stateGroup.state === "splashScreen");

            setApplicationState(appRunning);

            tryCompare(stateGroup, "state", "surface");
        }

        function test_suspendedAppShowsSurface() {
            var stateGroup = findInvisibleChild(applicationWindowLoader.item, "applicationWindowStateGroup");

            surfaceCheckbox.checked = true;
            setApplicationState(appRunning);
            tryCompare(stateGroup, "state", "surface");

            setApplicationState(appSuspended);

            for (var i = 0; i < 10; ++i) {
                wait(50);
                verify(stateGroup.state === "surface");
            }
        }

        function test_killedAppShowsScreenshot() {
            var stateGroup = findInvisibleChild(applicationWindowLoader.item, "applicationWindowStateGroup");

            surfaceCheckbox.checked = true;
            setApplicationState(appRunning);
            tryCompare(stateGroup, "state", "surface");

            setApplicationState(appSuspended);

            verify(stateGroup.state === "surface");
            verify(fakeApplication.surface !== null);

            // kill it!
            setApplicationState(appStopped);

            tryCompare(stateGroup, "state", "screenshot");
            tryCompare(fakeApplication, "surface", null);
        }

        function test_restartApp() {
            var stateGroup = findInvisibleChild(applicationWindowLoader.item, "applicationWindowStateGroup");

            surfaceCheckbox.checked = true;
            setApplicationState(appRunning);
            tryCompare(stateGroup, "state", "surface");

            setApplicationState(appSuspended);

            // kill it
            setApplicationState(appStopped);

            tryCompare(stateGroup, "state", "screenshot");
            tryCompare(fakeApplication, "surface", null);

            // and restart it
            setApplicationState(appStarting);

            wait(50);
            verify(fakeApplication.surface === null);
            tryCompare(stateGroup, "state", "screenshot");

            setApplicationState(appRunning);

            wait(50);
            tryCompare(stateGroup, "state", "screenshot");

            surfaceCheckbox.checked = true;

            tryCompare(stateGroup, "state", "surface");
            tryCompare(fakeApplication, "screenshot", "");
        }

        function test_appCrashed() {
            var stateGroup = findInvisibleChild(applicationWindowLoader.item, "applicationWindowStateGroup");

            surfaceCheckbox.checked = true;
            setApplicationState(appRunning);
            tryCompare(stateGroup, "state", "surface");

            // oh, it crashed...
            setApplicationState(appStopped);

            tryCompare(stateGroup, "state", "screenshot");
            tryCompare(fakeApplication, "surface", null);
        }

        function test_keepSurfaceWhileInvisible() {
            var stateGroup = findInvisibleChild(applicationWindowLoader.item, "applicationWindowStateGroup");

            surfaceCheckbox.checked = true;
            setApplicationState(appRunning);
            tryCompare(stateGroup, "state", "surface");
            verify(fakeApplication.surface !== null);

            applicationWindowLoader.item.visible = false;

            wait(50);
            verify(stateGroup.state === "surface");
            verify(fakeApplication.surface !== null);

            applicationWindowLoader.item.visible = true;

            wait(50);
            verify(stateGroup.state === "surface");
            verify(fakeApplication.surface !== null);
        }

        function test_touchesReachSurfaceWhenItsShown() {
            var stateGroup = findInvisibleChild(applicationWindowLoader.item, "applicationWindowStateGroup");

            setApplicationState(appRunning);
            surfaceCheckbox.checked = true;

            tryCompare(stateGroup, "state", "surface");

            // wait until any transition animation has finished
            tryCompare(stateGroup, "transitioning", false, 2000);

            fakeApplication.surface.touchPressCount = 0;
            fakeApplication.surface.touchReleaseCount = 0;

            tap(applicationWindowLoader.item,
                applicationWindowLoader.item.width / 2, applicationWindowLoader.item.height / 2);

            verify(fakeApplication.surface.touchPressCount === 1);
            verify(fakeApplication.surface.touchReleaseCount === 1);
        }
    }
}

