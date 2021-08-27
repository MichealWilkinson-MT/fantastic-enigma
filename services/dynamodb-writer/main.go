package main

import (
	"context"
	"crypto/sha1"
	"encoding/hex"
	"fmt"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/dynamodb"
)

var db = dynamodb.New(session.New(), aws.NewConfig().WithRegion("eu-west-2"))

// receives from queue
func handleRequest(ctx context.Context, sqsEvent events.SQSEvent) error {
	for _, message := range sqsEvent.Records {
		messageString := message.Body
		fmt.Printf("INFO: Hashing %s\n", messageString)
		hash := sha1.New()
		hash.Write([]byte(messageString))
		byteSlice := hash.Sum(nil)
		hashString := hex.EncodeToString(byteSlice)
		fmt.Printf("INFO: Got hash %s\n", hashString)
		putHashInDatabase(messageString, hashString)
	}
	return nil
}

func putHashInDatabase(messageString, hashedResult string) error {
	fmt.Print("INFO: Writing to DB")
	input := &dynamodb.PutItemInput {
		TableName: aws.String("fantastic-enigma-shas"),
		Item: map[string]*dynamodb.AttributeValue {
			"InputString" : {
				S: aws.String(messageString),
			},
			"Sha" : {
				S: aws.String(hashedResult),
			},
		},
	}

	_, err := db.PutItem(input)
	if err != nil {
		fmt.Printf("ERROR: %s\n" , err)
	}
	return err
}

func main() {
	lambda.Start(handleRequest)
}
