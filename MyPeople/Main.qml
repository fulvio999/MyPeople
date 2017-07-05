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
import "./utility.js" as Utility
import "./storage.js" as Storage


MainView {

    id: root
    objectName: "mainView"
    automaticOrientation: true
    anchorToKeyboard: true

    /* applicationName needs to match the "name" field in the application manifest
       Note:' applicationName' value sets the DB storage path if using U1DB api (remove the blank spaces in the url):
       eg: ~phablet/.local/share/<applicationName>/file:/opt/<click.ubuntu.com>/<applicationName>/<version-number>/MyPeople/MyPeople_db
    */
    applicationName: "mypeople.fulvio999"
    width: units.gu(160)
    height: units.gu(90)

    /* Settings file is saved in ~user/.config/<applicationName>/<applicationName>.conf  File */
    Settings {
        id:settings
        /* to show or not the ProductNewFeatures popup */
        property bool isFirstUse: true;
        property bool isNewVersion: true;
        /* to notify user in case of import old contact form version < 1.5 was already done */
        property bool importAlreadyDone: false;
        property bool createMeetingTable: true;
        property bool addTelegramField: true;
        /* on startup display the today meetings: value set in the App Configuration page */
        property bool rememberMeetingsEnabled;
    }

    ActivityIndicator {
        id: loadingPageActivity
    }

    /* Executed at application startup */
    Component.onCompleted:{
        Storage.setDefaultConfig();
        Storage.initialize();
        Storage.createMeetingTable();
        Storage.addTelegramField();        
        Storage.loadAllPeople();

        if(settings.rememberMeetingsEnabled){
          PopupUtils.open(todayMeetingsAlert)
        }

        Utility.showNewFeatures();
    }

    Component {
        id: dataBaseEraser
        DataBaseEraser{}
    }

    Component {
        id: dataBaseImporter
        DatabaseImporter{}
    }

    /* Show new features List for this MyPeople version */
    Component {
        id: showNewFeaturesDialogue
        ProductNewFeatures{}
    }

    Component {
        id: todayMeetingsAlert
        TodayMeetingsAlert{totalTodayMeetings:Storage.getTodayMeetings()}
    }

    /* A PopUp that display the operation result */
    Component {
        id: operationResultDialogue
        OperationResult{}
    }

    Component {
        id: itemNotFoundResultDialogue
        ItemNotFound{}
    }

    /* PopUp with Application Help and info page */
    Component {
        id: aboutComponentDialog
        AboutProduct{}
    }

    /* AdaptivePageLayout provides a flexible way of viewing a stack of pages in one or more columns */
    AdaptivePageLayout {

        id: adaptivePageLayout
        anchors.fill: parent

        /* mandatory field */
        primaryPage: peopleListPage

        Page{
            id: peopleListPage

            header: PageHeader {
                title: "MyPeople"

                leadingActionBar.actions: [
                    Action {
                        id: aboutPopover
                        /* note: icons names are file names under: /usr/share/icons/suru */
                        iconName: "help"
                        text: i18n.tr("Help")
                        onTriggered:{
                            PopupUtils.open(aboutComponentDialog)
                        }
                    }

                ]

                trailingActionBar.actions: [

                    Action {
                        iconName: "list-add"
                        text: "Add"
                        onTriggered:{
                            adaptivePageLayout.addPageToNextColumn(peopleListPage, addPersonPage)
                        }
                    },

                    Action {
                        iconName: "delete"
                        text: "Delete"
                        onTriggered:{
                            PopupUtils.open(dataBaseEraser)
                        }
                    },

                    Action {
                        iconName: "import"
                        text: "Import"
                        onTriggered:{
                            PopupUtils.open(dataBaseImporter)
                        }
                    },

                    /* New config page from version 1.6 */
                    Action {
                        iconName: "settings"
                        text: "Settings"
                        onTriggered:{
                            adaptivePageLayout.addPageToNextColumn(peopleListPage, configurationPage )

                        }
                    }
                ]
            }

            ListModel{
                id: modelListPeople
            }

            /* A list of people */
            UbuntuListView {
                id: listView
                anchors.fill: parent
                model: modelListPeople
                delegate: PeopleListDelegate{}  /* Component used to display an item */

                /* disable the dragging of the model list elements */
                boundsBehavior: Flickable.StopAtBounds
                highlight: HighlightComponent{}
                focus: true

                /* header for the list. Is declared here, inside at the UbuntuListView, to have access at the List items width param */
                Component{
                    id: listHeader

                    Item {
                        id: listHeaderItem
                        width: parent.width
                        height: units.gu(29)
                        x: 5; y: 8;

                        Column{
                            id: clo1
                            spacing: units.gu(1)
                            anchors.verticalCenter: parent.verticalCenter
                            /* placeholder */
                            Rectangle {
                                color: "transparent"
                                width: parent.width
                                height: units.gu(3)
                            }

                            Row{
                                id:row1
                                spacing: units.gu(2)
                                anchors.horizontalCenter: parent.horizontalCenter

                                TextField{
                                    id: searchField
                                    placeholderText: "name OR surname to search"
                                    onTextChanged: {
                                        if(text.length == 0 ) {
                                            Storage.loadAllPeople();
                                        }
                                    }
                                }

                                Button{
                                    id: filterButton
                                    objectName: "Search"
                                    width: units.gu(10)
                                    text: i18n.tr("Search")
                                    onClicked: {
                                        if(searchField.text.length > 0 )
                                        {
                                            modelListPeople.clear();
                                            var peopleFound = Storage.searchPeopleByNameOrSurname(searchField.text);

                                            for(var i =0;i < peopleFound.length;i++){
                                                modelListPeople.append(peopleFound[i]);
                                            }

                                        } else {
                                            Storage.loadAllPeople()
                                        }
                                    }
                                }
                            }

                            Row{
                                id:row2
                                spacing: units.gu(1)
                                Label{
                                    id: peopleFoundLabel                                   
                                    anchors.centerIn: parent.Center                                   
                                    text: i18n.tr("Total people found: ") + listView.count
                                    font.bold: false
                                    font.pointSize: units.gu(1.5)
                                }
                            }

                            Row{
                                id:row3
                                spacing: units.gu(1.5)
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: parent.width

                                Button{
                                    id: showReportbutton
                                    text: i18n.tr("Glogal Agenda Meeting")
                                    color: UbuntuColors.green
                                    height: units.gu(4)
                                    anchors.centerIn: parent.Center
                                    width: parent.width
                                    onClicked: {
                                        meetingWithPersonFoundModel.clear();
                                        allPeopleMeetingFoundModel.clear();

                                                                             //sintax: (current-page, page to add)
                                        adaptivePageLayout.addPageToNextColumn(peopleListPage, searchAnyMeetingPage);
                                    }
                                }
                            }
                        }
                    }
                }

                header: listHeader
            }

            Scrollbar {
                flickableItem: listView
                align: Qt.AlignTrailing
            }
        }


        //-------------------------- PERSON DETAILS PAGE: details of the selected person -----------------------------------
        Page{
            id:personDetailsPage

            anchors.fill: parent

            /* Values passed as input properties when the AdaptiveLayout add the details page (See: PeopleListDelegate.qml)
               Are the details vaules of the selected person in the people list used to fill the TextField
               See Delegate Object of the ListView
            */
            property string id  /* PK field not shown */
            property string personName;
            property string personSurname
            property string personPhone
            property string personEmail
            property string personJob
            property string personTaxCode
            property string personVatNumber
            property string personBirthday
            property string personAddress
            property string personSkype
            property string personTelegram
            property string personMobilePhone
            property string personNote

            header: PageHeader {
                id: headerDetailsPage
                title: i18n.tr("Details for ") + "<b>"+personDetailsPage.personName + " "+personDetailsPage.personSurname+"<\b>"
            }

            /* to have a scrollable column when the keyboard cover some input field */
            Flickable {
                id: personDetailsFlickable
                clip: true
                contentHeight: Utility.getContentHeight()
                anchors {
                    top: parent.top
                    left: parent.left
                    right: parent.right
                    bottom: personDetailsPage.bottom
                    bottomMargin: units.gu(2)
                }

                /* Show the details of the selected person */
                Layouts {
                    id: layoutsDetailsContact
                    width: parent.width
                    height: parent.height
                    layouts:[

                        ConditionalLayout {
                            name: "detailsContactLayout"
                            when: root.width > units.gu(80)

                                DetailsPersonTablet{}
                        }
                    ]
                    //else
                    DetailsPersonPhone{}
                }
            }

            /* To show a scrollbar on the side */
            Scrollbar {
                flickableItem: personDetailsFlickable
                align: Qt.AlignTrailing
            }
        }

        //------------ SEARCH MEETINGS *ONLY WITH* THE SELECTED PERSON ------------
        Page{
            id:searchMeetingWithPersonPage

            anchors.fill: parent

            /* Values passed as input properties when the AdaptiveLayout add the details page (See: PeopleListDelegate.qml)
               Are the details vaules of the selected person in the people list used to fill the TextField
               See Delegate Object of the ListView
            */
            property string id  /* PK field not shown */
            property string personName;
            property string personSurname

            header: PageHeader {
                id: headersearchAnyMeetingPage
                title: i18n.tr("Search meeting with: ") + "<b>"+searchMeetingWithPersonPage.personName + " "+searchMeetingWithPersonPage.personSurname+"<\b>"
            } 

             ListModel {
                id: meetingWithPersonFoundModel
             }

             /* Component that display the Meetings found in the database */
             Component {
                   id: meetingFoundDelegate
                   MeetingFoundDelegate{}
             }

             UbuntuListView {
                    id: meetingSearchResultList
                    /* necessary, otherwise hide the search criteria row */
                    anchors.topMargin: units.gu(36)
                    anchors.fill: parent
                    focus: true
                    /* nececessary otherwise the list scroll under the  */
                    clip: true
                    model: meetingWithPersonFoundModel
                    boundsBehavior: Flickable.StopAtBounds
                    highlight: HighlightComponent{}
                    delegate: meetingFoundDelegate
             }

             /* Show the details of the selected person */
             Layouts {
                   id: layoutSearchMeeting
                   width: parent.width
                   height: parent.height
                   layouts:[

                      ConditionalLayout {
                            name: "detailsContactLayout"
                            when: root.width > units.gu(80)

                                SearchMeetingWithPersonTablet{}
                        }
                   ]
                   //else
                   SearchMeetingWithPersonPhone{}
             }

             /* To show a scrollbar on the side to scroll meeting search result list */
             Scrollbar {
                flickableItem: meetingSearchResultList
                align: Qt.AlignTrailing
             }
        }


        //------------ ADD A NEW MEETING WITH the selected person ------------
        Page{
            id:addMeetingWithPersonPage

            anchors.fill: parent

            /* values passed when the user has chosen a people in the  people list */
            property string id  /* PK field not shown */
            property string personName;
            property string personSurname

            header: PageHeader {
                id: headerAddMeetingPage
                title: i18n.tr("Create a meeting with: ") + "<b>"+addMeetingWithPersonPage.personName + " "+addMeetingWithPersonPage.personSurname+"<\b>"
            }

            /* to have a scrollable column when the keyboard cover some input field */
            Flickable {
                id: addMeetingWithPersonPageFlickable
                clip: true
                contentHeight: Utility.getContentHeight()
                anchors {
                    top: parent.top
                    left: parent.left
                    right: parent.right
                    bottom: addMeetingWithPersonPage.bottom
                    bottomMargin: units.gu(2)
                }


                /* Show the details of the selected person */
                Layouts {
                    id: layoutAddMeeting
                    width: parent.width
                    height: parent.height
                    layouts:[

                        ConditionalLayout {
                            name: "detailsContactLayout"
                            when: root.width > units.gu(80)

                                NewMeetingTablet{}
                        }
                    ]
                    //else
                    NewMeetingPhone{}
                }
            }

            /* To show a scrollbar on the side */
            Scrollbar {
                flickableItem: addMeetingWithPersonPageFlickable
                align: Qt.AlignTrailing
            }
        }


        //----------------- SEARCH MEETINGS with ANY People ---------------------

        Page {
                id: searchAnyMeetingPage

                header: PageHeader {
                   title: i18n.tr("Search for meetings wiht any people")
                }

                ListModel {
                    id: allPeopleMeetingFoundModel
                }

                /* Component that display the Meetings found in the database */
                Component {
                    id: allPeopleMeetingFoundDelegate
                    AllPeopleMeetingFoundDelegate{}
                }

                UbuntuListView {
                    id: allPeopleMeetingSearchResultList
                    /* necessary, otherwise hide the search criteria row */
                    anchors.topMargin: units.gu(36) //units.gu(searchReloadRow.height + expenseFoundTitle.height + searchCriteriaRow.height + dateFilterRow.height + categoryFilterRow.height)
                    anchors.fill: parent
                    focus: true
                    /* nececessary otherwise the list scroll under the  */
                    clip: true
                    model: allPeopleMeetingFoundModel
                    boundsBehavior: Flickable.StopAtBounds
                    highlight: HighlightComponent{}
                    delegate: allPeopleMeetingFoundDelegate
                }

                /* Show a form to add a new contact */
                Layouts {
                    id: agendaLayouts
                    width: parent.width
                    height: parent.height
                    layouts:[

                        ConditionalLayout {
                            name: "addContactLayout"
                            when: root.width > units.gu(80)
                            SearchMeetingGlobalTablet{}
                        }
                    ]
                    //else
                    SearchMeetingGlobalPhone{}
                }


            /* To show a scrolbar on the side */
            Scrollbar {
                flickableItem: allPeopleMeetingSearchResultList
                align: Qt.AlignTrailing
            }
        }


        //------------ Edit an existing Meeting planned with a specific Person -------------

        Page{

            id: editMeetingPage
            anchors.fill: parent

            /* meeting info to edit */
            property string id; /* meetingId not editable, used for update uery */
            property string name;
            property string surname;
            property string subject;
            property string date;
            property string place;
            property string status; /* TODO, ARCHIVED */
            property string note;

            header: PageHeader {
                id: headerEditExpensePage
                title: i18n.tr("Edit meeting with: ") + "<b>" +editMeetingPage.name +" "+ editMeetingPage.surname+"</b>"
            }


            Flickable {
                id: editMeetingPageFlickable
                clip: true
                contentHeight: Utility.getContentHeight()
                anchors {
                    top: parent.top
                    left: parent.left
                    right: parent.right
                    bottom: editMeetingPage.bottom
                    bottomMargin: units.gu(2)
                }

                /* Show the details of the selected meeting */
                Layouts {
                    id: layoutEditExpensePage
                    width: parent.width
                    height: parent.height
                    layouts:[

                        ConditionalLayout {
                            name: "editMeetingLayout"
                            when: root.width > units.gu(80)
                            EditMeetingTablet{ meetingStatus:editMeetingPage.status}
                        }
                    ]
                    //else
                    EditMeetingPhone{ meetingStatus:editMeetingPage.status }
                }
            }

            /* To show a scrolbar on the side */
            Scrollbar {
                flickableItem: editMeetingPageFlickable
                align: Qt.AlignTrailing
            }
        }


        //------------- ADD NEW PERSON PAGE --------------------
        Page {
            id: addPersonPage

            header: PageHeader {
                title: i18n.tr("Add new person")
            }

            Flickable {
                id: newPersonPageFlickable
                clip: true
                contentHeight: Utility.getContentHeight()
                anchors {
                    top: parent.top
                    left: parent.left
                    right: parent.right
                    bottom: addPersonPage.bottom
                    bottomMargin: units.gu(2)
                }

                /* Show a form to add a new contact */
                Layouts {
                    id: layouts
                    width: parent.width
                    height: parent.height
                    layouts:[

                        ConditionalLayout {
                            name: "addContactLayout"
                            when: root.width > units.gu(80)
                            InsertPersonFormTablet{}
                        }
                    ]
                    //else
                    InsertPersonFormPhone{}
                }
            }

            /* To show a scrolbar on the side */
            Scrollbar {
                flickableItem: newPersonPageFlickable
                align: Qt.AlignTrailing
            }
        }


       //----------------- Application Configuration page -----------------
       Page {
            id: configurationPage

            header: PageHeader {
                title: i18n.tr("Application Configuration")
            }

            Layouts {
                id: layoutConfigurationPage
                width: parent.width
                height: parent.height
                layouts:[

                    ConditionalLayout {
                        name: "layoutsConfiguration"
                        when: root.width > units.gu(50)
                        AppConfigurationTablet{}
                    }
                ]
                //else
                AppConfigurationPhone{}
            }
        }

       //-------------------------------------------------------


    }


    /*
      U1DB Databases "connetcors" to MyPeole 1.0 and 1.1 Databases. Used only to import old contacts into new Mypeople 1.2 database
      MyPeople 1.2 (and futere release) uses QT LocalStorage API instead of QML U1DB, so that the Database  will be located
      in a fixed folder independent from thre application version and NO import was necessary.
    */


    /* For MyPepole version 1.0 importing data */

    U1db.Database {
        id: mypeopleDb1_0
        /* create an empty db in: ~phablet/.local/share/mypeople.fulvio999/1.1/
           the user will replace it his with his one about MyPeople1.0  */
         path: "1.0/MyPeople_db";
     }

    U1db.Index{
        database: mypeopleDb1_0
        id: all_field_index1_0
        expression: ["name","surname","email","job","birthday","vatNumber","taxCode","address","phone","mobilePhone","note"]
    }

    U1db.Query {
        id: allPeopleQuery1_0
        index: all_field_index1_0
        query: [{"name":"*"},{"surname":"*"},{"email":"*"},{"job":"*"},{"birthday":"*"},{"vatNumber":"*"},{"taxCode":"*"},{"address":"*"},{"phone":"*"},{"mobilePhone":"*"},{"note":"*"}]
    }


    /* For MyPeole version 1.1 importing data */

    U1db.Database {
        id: mypeopleDb1_1
        /* create an empty db in: ~phablet/.local/share/mypeople.fulvio999/1.1/
           the user will replace it his with his one about MyPeople1.0*/
        path: "1.1/MyPeople_db";
    }

    U1db.Index{
        database: mypeopleDb1_1
        id: all_field_index1_1
        expression: ["name","surname","email","job","birthday","vatNumber","taxCode","address","phone","mobilePhone","note"]
    }

    U1db.Query {
        id: allPeopleQuery1_1
        index: all_field_index1_1
        query: [{"name":"*"},{"surname":"*"},{"email":"*"},{"job":"*"},{"birthday":"*"},{"vatNumber":"*"},{"taxCode":"*"},{"address":"*"},{"phone":"*"},{"mobilePhone":"*"},{"note":"*"}]
    }

}
