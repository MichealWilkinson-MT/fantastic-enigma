package main

import (
	"context"
	"crypto/sha1"
	"encoding/hex"
	"fmt"
	"os"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/dynamodb"
)

var databaseRegion string = os.Getenv("DATABASE_REGION")
var dynamodbTableName string = os.Getenv("DYNAMODB_TABLE_NAME")
var db dynamoDBClient

type dynamoDBClient interface {
	PutItem(*dynamodb.PutItemInput) (*dynamodb.PutItemOutput, error)
}


// receives from queue
func handleRequest(ctx context.Context, sqsEvent events.SQSEvent) error {
	for _, message := range sqsEvent.Records {
		messageString := message.Body
		hashString := hashInput(messageString)
		putHashInDatabase(messageString, hashString)
	}
	return nil
}

// set databas

// init database


func hashInput(input string) string {
	hash := sha1.New()
	hash.Write([]byte(input))
	byteSlice := hash.Sum(nil)
	hashString := hex.EncodeToString(byteSlice)
	return hashString
}

func putHashInDatabase(messageString, hashedResult string) error {
	input := &dynamodb.PutItemInput {
		TableName: aws.String(dynamodbTableName),
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

func initDatabase(client *dynamoDBClient) {
	db = client
	fmt.Println(db)
}

func main() {
	// call init
	initDatabase(dynamodb.New(session.New(), aws.NewConfig().WithRegion(databaseRegion)))
	lambda.Start(handleRequest)
}
