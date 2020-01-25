const AWS = require('aws-sdk');

function getObject(s3, info) {
    return new Promise((resolve, reject) => {
        s3.getObject(info, function(err, data) {
            if (err) return reject(err);
            resolve(data);
        });
    });
}

function publishSnsMessage(sns, topicArn, messageText) {
    return new Promise((resolve, reject) => {
        let params = {
            Message: messageText,
            TopicArn: topicArn
        };
        sns.publish(params, function (err, data) {
            if (err)  return reject(err);
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

    const EMPTY_CSV_LENGTH = 343;

    var csvFiles = event.Records
        .filter(r => r.eventName === 'ObjectCreated:Put')
        .map(r => r.s3)
        .filter(b => b.object.size > EMPTY_CSV_LENGTH)
        .map(b => {
            return {
                Bucket: b.bucket.name,
                Key: b.object.key
            }
        });

    var processedCount = 0;

    var s3 = new AWS.S3();
    let sns = new AWS.SNS();
    let snsAlertsTopicArn = process.env.ALERTS_SNS_TOPIC_ARN;

    csvFiles.forEach((csvInfo) => {
        console.log('Downloading', csvInfo);

        getObject(s3, csvInfo)
            .then((data) => {
                var csvContents = data.Body.toString();
                console.log('Publishing', csvContents);

                publishSnsMessage(sns, snsAlertsTopicArn, csvContents)
                    .then((result) => {
                        console.log('Publish result', JSON.stringify(result));

                        processedCount++;

                        if (processedCount === csvFiles.length){
                            console.log('Completed Successfully');
                            callback(null, 'DONE');
                        }
                    })
                    .catch(abortWithError);
            })
            .catch(abortWithError);
    });
};