'use strict';

exports.handler = (event, context, callback) => {
    console.log(JSON.stringify(event, null, 2));

    let eventDetails = event.detail;
    if (eventDetails.readOnly){
        callback(null, 'Ignore ReadOnly Event');
        return;
    }

    if (eventDetails.eventSource !== "iam.amazonaws.com"){
        callback(null, 'Ignore non IAM Event');
        return;
    }

    // TODO publish SNS Notification

    callback(null, 'IAM Modification');
};