const { Kafka } = require('kafkajs')
const http = require("http");
const { CompressionTypes } = require('kafkajs')

console.log(process.env.KAFKA_BROKER_URL)

const kafka = new Kafka({
  clientId: 'video-topic',
  // brokers: ['localhost:9092'],
    brokers: [process.env.KAFKA_BROKER_URL],
  ssl: true,
  logLevel: 2,
 sasl: {
   mechanism: 'plain',
   username: process.env.SASL_USERNAME,
   password: process.env.SASL_PASSWORD
 }
})

var isConnected = false

const producer = kafka.producer()
producer.on('producer.connect', () => {
  console.log(`KafkaProvider: connected`);
  isConnected = true
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

    if (!isConnected){
      console.log('message NOT posted becuase server is still connecting ' + new Date());
      res.writeHead(200)
      res.end();

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
              console.log('message posted at ' + new Date());
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


