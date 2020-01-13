exports.handler = function(event, context, callback){
    console.log('Guardduty Lambda Invocation');
    callback(null, 'DONE');
}