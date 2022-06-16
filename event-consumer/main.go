package main

import (
	"fmt"
	"github.com/confluentinc/confluent-kafka-go/kafka"
	"os"
	"strconv"
)

func main() {

	topics := []string{"video-stream"}

	var kafkabroker = os.Getenv("KAFKA_BROKER")
	var groupid = os.Getenv("GROUP_ID")

	if kafkabroker == "" {
		kafkabroker = "localhost:9092"
	}

	sasalusername := os.Getenv("SASL_USERNAME")
	salpassword := os.Getenv("SASL_PASSWORD")

	c, err := kafka.NewConsumer(&kafka.ConfigMap{
		"bootstrap.servers": kafkabroker,
		"group.id":          groupid,
		"auto.offset.reset": "earliest",
		"sasl.mechanism":    "PLAIN",
		"security.protocol": "SASL_SSL",
		"sasl.username":     sasalusername,
		"sasl.password":     salpassword})

	if err != nil {
		fmt.Printf("Exitting .. Failed to creare consumer: %s\n", err)
		os.Exit(1)
	}

	err = c.SubscribeTopics(topics, nil)
	var data []byte
	parallelinference, _ := strconv.Atoi(os.Getenv("PARALLEL_INFERENCE"))
	semaphore := make(chan int, parallelinference)
	run := true
	for run == true {
		ev := c.Poll(0)
		switch e := ev.(type) {
		case *kafka.Message:
			data = e.Value
			semaphore <- 1
			go func() {
				PerformInference(data)
				<-semaphore
			}()
		case kafka.Error:
			fmt.Fprintf(os.Stderr, "%% Error: %v\n", e)
			run = false
		default:
			//fmt.Printf("Ignored %v\n", e)
		}
	}

}
