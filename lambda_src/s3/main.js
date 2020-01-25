const AWS = require('aws-sdk');

exports.handler = function(event, context, callback) {
    console.log('S3 Lambda Invocation');
    console.log(JSON.stringify(event));

    if (event.eventName !== 'ObjectCreated:Put'){
        callback(null, 'Ignore');
        return;
    }

    callback(null, 'DONE');
};