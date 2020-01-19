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

function startQuery(athena, queryInfo) {
    return new Promise((resolve, reject) => {
        var params = {
            QueryString: queryInfo.QueryString,
            QueryExecutionContext: {
                Database: queryInfo.Database
            },
            ResultConfiguration: {
                OutputLocation: process.env.ATHENA_QUERY_OUTPUT_LOCATION
            },
            WorkGroup: queryInfo.WorkGroup
        };
        athena.startQueryExecution(params, function(err, data) {
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

                    var queriesLength = data.NamedQueries.length;

                    data.NamedQueries.forEach((query, index) => {
                        console.log(`Executing Query: ${query.Name} on DB ${query.Database} Workgroup ${query.WorkGroup}`);

                        startQuery(athena, query)
                            .then((data) => {
                                console.log(`Execution Id: ${data.QueryExecutionId}`);

                                if (index + 1 === queriesLength){
                                    callback(null, 'DONE');
                                }
                            })
                            .catch(abortWithError);
                    });

                })
                .catch(abortWithError);
        })
        .catch(abortWithError);
}
