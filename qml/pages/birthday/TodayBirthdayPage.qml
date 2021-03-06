import QtQuick 2.4
import Ubuntu.Components 1.3
import Ubuntu.Components.Popups 1.3
import Ubuntu.Components.Pickers 1.3
import Ubuntu.Layouts 1.0

import U1db 1.0 as U1db

/* replace the 'incomplete' QML API U1db with the low-level QtQuick API */
import QtQuick.LocalStorage 2.0
import Ubuntu.Components.ListItems 1.3 as ListItem

/* note: alias name must have first letter in upperCase */
import "../../js/utility.js" as Utility
import "../../js/storage.js" as Storage

//----------------- Today BirthDay -----------------
Page {
     id: todayBirthdayPage
     anchors.fill: parent

     header: PageHeader {
        id: todayBirthdayPageHeader
        title: i18n.tr("Today BirthDay")+ ": " + todayBirthdayModel.count
     }


     Item{
         id: todayBirthDayTablet
     //    width: parent.width
     //    height: parent.height
           anchors.fill: parent

         UbuntuListView {
             id: todayBirthDayResultList
             /* necessary, otherwise hide the search criteria row */
             anchors.topMargin: todayBirthdayPageHeader.height
             anchors.fill: parent
             focus: true
             /* nececessary otherwise the list scroll under the header */
             clip: true
             model: todayBirthdayModel
             boundsBehavior: Flickable.StopAtBounds
             highlight:
                 Component {
                     id: highlightBirthDayComponent

                     Rectangle {
                         width: 180; height: 44
                         color: "blue";
                         radius: 2
                         /* move the Rectangle on the currently selected List item with the keyboard */
                         y: todayBirthDayResultList.currentItem.y

                         /* show an animation on change ListItem selection */
                         Behavior on y {
                             SpringAnimation {
                                 spring: 5
                                 damping: 0.1
                             }
                         }
                     }
                }

             delegate:
                 Item{
                 /*
                    Delegate Component to show details of a person with a birthday
                 */
                 id: birthdayItem
                 width: parent.width
                 height: units.gu(11)

                 /* a container for each person */
                 Rectangle {
                     id: background
                     x: 2; y: 2; width: parent.width - x*2; height: parent.height - y*1
                     border.color: "black"
                     radius: 5
                     /* to get the background color of the curreunt theme. Necessary if default theme is not used */
                     color: theme.palette.normal.background
                 }

                 MouseArea {
                     id: selectableMouseArea
                     width: parent.width
                     height: parent.height

                     onClicked: {
                         /* move the highlight component to the currently selected item */
                         todayBirthDayResultList.currentIndex = index
                     }
                 }

                 /* Crete a row for EACH entry (ie Person) in the ListModel */
                 Row {
                     id: topLayout
                     x: 10; y: 7;
                     height: background.height;
                     width: parent.width
                     spacing: units.gu(4)

                     Column {
                         id:personInfoColumn
                         width: background.width/3 *2.2;
                         height: birthdayItem.height
                         spacing: units.gu(0.1)

                         Label {
                             text: name+ "<br> "+surname
                             font.bold: true;
                             font.pointSize: units.gu(1.3)
                         }
                         Label {
                             text: i18n.tr("phone")+": "+phone
                             fontSize: "small"
                         }
                         Label {
                             text: i18n.tr("mobile")+": "+mobilePhone
                             fontSize: "small"
                         }
                         Label {
                             text: i18n.tr("mail")+": "+email
                             fontSize: "small"
                         }
                     }
                 }
             }
         }
     }


}
