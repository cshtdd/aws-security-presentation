'use strict';

exports.handler = (event, context, callback) => {
    console.log('CloudTrailEvent');
    console.log('Received event:', JSON.stringify(event, null, 2));
    callback(null, 'Success');
};