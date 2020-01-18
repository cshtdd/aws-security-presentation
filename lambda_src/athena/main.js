const AWS = require('aws-sdk');

function listNamedQueries(athena, workGroup){
    return new Promise((resolve, reject) => {
        var params = {
            MaxResults: '20',
            WorkGroup: workGroup
        };
        athena.listNamedQueries(params, function(err, data) {
            if (err) {
                return reject(err)
            }

            resolve(data);
        });
    });
}

exports.handler = function(event, context, callback){
    console.log('Athena Schedule Lambda Invocation');

    var athenaWorkgroup = process.env.ATHENA_WORKGROUP;
    var athena = new AWS.Athena();

    listNamedQueries(athena, athenaWorkgroup)
        .then((data) => {
            console.log(data);
            var namedQueryIds = data.NamedQueryIds;

            namedQueryIds.forEach( (id) => {
                console.log(`Executing Query: ${id}`);
            });

            callback(null, 'DONE');
        })
        .catch((e) => {
            console.log('ERROR: ', e);
            callback(null, 'ERROR');
        });
}
