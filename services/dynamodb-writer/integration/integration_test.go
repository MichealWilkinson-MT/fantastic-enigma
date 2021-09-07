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
	"github.com/aws/aws-sdk-go/service/lambda"
)

var stage string

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
					Body: "Rishi is the best!",
				},
			},
		}

		payload, _ := json.Marshal(request)

		functionName := fmt.Sprintf("%s-%s-%s", "fantastic-enigma", stage, "dynamodb-writer")

		// Need to figure out how to mutate based on "Stage"
		result, err := client.Invoke(&lambda.InvokeInput{
			FunctionName: aws.String(functionName),
			Payload:      payload,
		})

		if err != nil {
			fmt.Println("Its all gone wrong")
			os.Exit(1)
		}
	})
}
