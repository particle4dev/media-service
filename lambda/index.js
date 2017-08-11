import reserse from './reverse';

exports.handler = (event, context, callback) => {
  console.log('Hello, logs!');
  console.log(reserse('hoang nam'));
  callback(null, {"Hello":"World"});  // SUCCESS with message
}
