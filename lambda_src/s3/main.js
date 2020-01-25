const AWS = require('aws-sdk');

function getObject(s3, info) {
    return new Promise((resolve, reject) => {
        s3.getObject(info, function(err, data) {
            if (err) return reject(err);
            resolve(data);
        });
    });
}

exports.handler = function(event, context, callback) {
    console.log('S3 Lambda Invocation');
    console.log(JSON.stringify(event));

    function abortWithError(e) {
        console.log('ERROR: ', e);
        callback(null, 'ERROR');
    }

    var csvFiles = event.Records
        .filter(r => r.eventName === 'ObjectCreated:Put')
        .map(r => r.s3)
        .map(b => {
            return {
                Bucket: b.bucket.name,
                Key: b.object.key
            }
        });

    var processedCount = 0;

    var s3 = new AWS.S3();

    csvFiles.forEach((csvInfo) => {
        console.log('Downloading', csvInfo);

        getObject(s3, csvInfo)
            .then((data) => {
                console.log(JSON.stringify(data));

                // data.Body

                callback(null, 'DONE');
            })
            .catch(abortWithError);
    });
};