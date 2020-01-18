const AWS = require('aws-sdk');

function listNamedQueries(athena, workGroup){
    return new Promise((resolve, reject) => {
        var params = {
            MaxResults: '20',
            WorkGroup: workGroup
        };
        athena.listNamedQueries(params, function(err, data) {
            if (err) return reject(err);
            resolve(data);
        });
    });
}

function getNamedQueries(athena, queryIds = []) {
    return new Promise((resolve, reject) => {
        var params = {
            NamedQueryIds: queryIds
        };
        athena.batchGetNamedQuery(params, function(err, data) {
            if (err) return reject(err);
            resolve(data);
        });
    });
}

exports.handler = function(event, context, callback){
    console.log('Athena Schedule Lambda Invocation');

    function abortWithError(e) {
        console.log('ERROR: ', e);
        callback(null, 'ERROR');
    }

    var athenaWorkgroup = process.env.ATHENA_WORKGROUP;
    var athena = new AWS.Athena();

    listNamedQueries(athena, athenaWorkgroup)
        .then((data) => {
            console.log(data);
            getNamedQueries(athena, data.NamedQueryIds)
                .then((data) => {
                    console.log(data);

                    data.NamedQueries.forEach((query) => {
                        console.log(`Executing Query: ${query.Name} on DB ${query.Database} Workgroup ${query.WorkGroup}`);

                        
                    });

                    callback(null, 'DONE');
                })
                .catch(abortWithError);
        })
        .catch(abortWithError);
}
