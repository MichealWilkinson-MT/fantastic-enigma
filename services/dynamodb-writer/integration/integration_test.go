//go:build integration
// +build integration

// Hey folks, I've added a command line flag to add the stage to the function name it is tring to execute
// To run the tests you need go test ./... --tags integration --stage STAGE_NAME
package integration

import (
	"encoding/json"
	"flag"
	"fmt"
	"os"
	"testing"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/dynamodb"
	"github.com/aws/aws-sdk-go/service/dynamodb/dynamodbattribute"
	"github.com/aws/aws-sdk-go/service/lambda"
	"github.com/stretchr/testify/assert"
)

var stage string

var db = dynamodb.New(session.New(), aws.NewConfig().WithRegion("eu-west-2"))

type getItemResponse struct {
	InputString string `json:"InputString"`
	Sha         string `json:"Sha"`
}

func init() {
	flag.StringVar(&stage, "stage", "dev", "Specify the stage to test")
}

func TestInput(test *testing.T) {
	test.Run("Trigging lambda puts hash in db", func(test *testing.T) {
		sess := session.Must(session.NewSessionWithOptions(session.Options{
			SharedConfigState: session.SharedConfigEnable,
		}))

		client := lambda.New(sess, &aws.Config{Region: aws.String("eu-west-2")})

		request := events.SQSEvent{
			Records: []events.SQSMessage{
				{
					Body: "Alex is the best!",
				},
			},
		}

		payload, _ := json.Marshal(request)

		functionName := fmt.Sprintf("%s-%s-%s", "fantastic-enigma", stage, "dynamodb-writer")

		_, err := client.Invoke(&lambda.InvokeInput{
			FunctionName: aws.String(functionName),
			Payload:      payload,
		})

		if err != nil {
			fmt.Println("Its all gone wrong")
			os.Exit(1)
		}

		// check if result is in the database
		input := &dynamodb.GetItemInput{
			TableName: aws.String(fmt.Sprintf("fantastic-enigma-shas-%s", stage)),
			Key: map[string]*dynamodb.AttributeValue{
				"InputString": {
					S: aws.String("Alex is the best!"),
				},
			},
		}

		itemOutput, err := db.GetItem(input)
		if err != nil {
			fmt.Printf("ERROR: %s\n", err)
		}

		var resp getItemResponse
		err = dynamodbattribute.UnmarshalMap(itemOutput.Item, &resp)
		if err != nil {
			fmt.Println("Error unmarshalling MyGetItemsFunction response")
			os.Exit(0)
		}
		assert.Equal(test, "Alex is the best!", resp.InputString)
	})
}
