exports.handler = function(event, context, callback){
    console.log('Athena Schedule Lambda Invocation');
    callback(null, 'DONE');
}
