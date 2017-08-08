exports.handler = (event, context, callback) => {
  console.log(event);
  console.log(context);
  console.log(callback.toString());
  console.log('Hello, logs!');
  callback(null, 'great success');
}