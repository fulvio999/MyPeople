import QtQuick 2.4
import Ubuntu.Components 1.3
import Ubuntu.Components.Popups 1.3

import QtQuick.LocalStorage 2.0
import "./storage.js" as Storage


/* Ask a confirmation before inserting a new Meeting */
Dialog {

    id: dialogue
    title: "Confirmation"
    modal:true

    Button {
       text: i18n.tr("Cancel")
       onClicked: PopupUtils.close(dialogue)
    }

    Button {
        text: i18n.tr("Execute")
        onClicked: {
            PopupUtils.close(dialogue)
            /* compose the full date because in the UI come from two different components */
            var meetingFullDate = newMeetingDateButton.text +" "+newMeetingTimeButton.text;

            Storage.insertMeeting(nameField.text,surnameField.text,meetingSubjectField.text,meetingPlaceField.text,meetingFullDate,newMeetingNote.text);

            PopupUtils.open(operationResultDialogue)

            adaptivePageLayout.removePages(addMeetingWithPersonPage)
        }
    }
}

