const { Kafka } = require('kafkajs')
const http = require("http");
const { CompressionTypes } = require('kafkajs')

// This creates a client instance that is configured to connect to the Kafka broker provided by
// the environment variable KAFKA_BOOTSTRAP_SERVER
const kafka = new Kafka({
  clientId: 'qa-topic',
  brokers: ['localhost:9092'],
  ssl: false,
  logLevel: 2
//  sasl: {
//    mechanism: 'plain',
//    username: 'admin',
//    password: 'password'
//  }
})


const producer = kafka.producer()
producer.on('producer.connect', () => {
  console.log(`KafkaProvider: connected`);
});
producer.on('producer.disconnect', () => {
  console.log(`KafkaProvider: could not connect`);
});
producer.on('producer.network.request_timeout', (payload) => {
  console.log(`KafkaProvider: request timeout ${payload.clientId}`);
});
const run = async () => {
  // Producing
  await producer.connect()
}

const host = 'localhost';
const port = 8000;


const requestListener = async function (req, res) {

    res.setHeader('Access-Control-Allow-Origin', '*');
	res.setHeader('Access-Control-Request-Method', '*');
	res.setHeader('Access-Control-Allow-Methods', 'OPTIONS, POST');
	res.setHeader('Access-Control-Allow-Headers', '*');
	if ( req.method === 'OPTIONS' ) {
		res.writeHead(200);
		res.end();
		return;
	}

//    console.log(req)
    var body = "";
      req.on('data', function (chunk) {
        body += chunk;
      });
      req.on('end', function () {
//        console.log('\n\n\n***body: ' + body);
//        var jsonObj = JSON.parse(body);
//      console.log(jsonObj.test);
        producer.send({
        topic: 'video-stream',
        compression: CompressionTypes.GZIP,
        messages: [
          {
            value: Buffer.from(body)
          },
        ],
      });
              console.log('message posted');
      res.writeHead(200)
      res.end();

      })

    //not prod ready code

};

run().catch(console.error)


const server = http.createServer(requestListener);
server.listen(port, host, () => {
    console.log(`Server is running on http://${host}:${port}`);
});


