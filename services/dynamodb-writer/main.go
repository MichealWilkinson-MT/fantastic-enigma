package main

import (
	"context"
	"crypto/sha1"
	"fmt"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
)

// receives from queue
func handleRequest(ctx context.Context, sqsEvent events.SQSEvent) (string, error) {
	
	for _, message := range sqsEvent.Records {
		messageString := message.Body
		hash := sha1.New()
		hash.Write([]byte(messageString))
		byteSlice := hash.Sum(nil)
		return fmt.Sprintf("%x\n", byteSlice), nil
	}

	return "", nil
}

func main() {
	lambda.Start(handleRequest)
}
