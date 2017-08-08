exports.handler = (event, context, callback) => {
  console.log('event', JSON.stringify(event));
  console.log('context', JSON.stringify(context));
  console.log('callback', JSON.stringify(callback));
  callback(null, 'great success');
}