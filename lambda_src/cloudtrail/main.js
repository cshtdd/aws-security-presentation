'use strict';
var AWS = require("aws-sdk");

exports.handler = (event, context, callback) => {
    let eventText = JSON.stringify(event, null, 2);
    console.log(eventText);

    let eventDetails = event.detail;
    if (eventDetails.readOnly){
        console.log('Ignore ReadOnly Event');
        callback(null, 'Ignore ReadOnly Event');
        return;
    }

    if (eventDetails.eventSource !== "iam.amazonaws.com"){
        console.log('Ignore non IAM Event');
        callback(null, 'Ignore non IAM Event');
        return;
    }

    console.log('Publish SNS Notification');
    let snsAlertsTopicArn = process.env.ALERTS_SNS_TOPIC_ARN;

    let sns = new AWS.SNS();
    let params = {
        Message: eventText,
        TopicArn: snsAlertsTopicArn
    };
    sns.publish(params, function (err, data) {
        if (err) {
            console.log(err, err.stack);
        }
        console.log('SNS Publish Completed');
        callback(null, 'IAM Modification');
    });
};