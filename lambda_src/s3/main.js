const AWS = require('aws-sdk');

exports.handler = function(event, context, callback) {
    console.log('S3 Lambda Invocation');
    console.log(JSON.stringify(event));

    // event.Records.forEach(er => console.log(er.s3));

    var csvFiles = event.Records
        .filter(r => r.eventName === 'ObjectCreated:Put')
        .map(r => r.s3)
        .map(b => {
            return {
                bucket: b.bucket.name,
                key: b.object.key
            }
        });

    csvFiles.forEach((csvInfo) => {
        console.log(csvInfo);
    });

    callback(null, 'DONE');
};