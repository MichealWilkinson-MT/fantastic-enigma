package main

import (
	"testing"

	"github.com/aws/aws-sdk-go/service/dynamodb"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/mock"
)

func TestHashInput(test *testing.T) {

	test.Run("Returns a hashed string", func (test *testing.T) {
		
		expected := "2582c03f8bbd94611a6d24df12b9ab218a2a3db9"
		actual := hashInput("Rishi is cool")

		assert.Equal(test, expected, actual)	
		
	})

}

type MockDyamodb struct {
	mock.Mock
}

func (db *MockDyamodb) PutItem(*dynamodb.PutItemInput) (*dynamodb.PutItemOutput, error) {
	return &dynamodb.PutItemOutput{}, nil
}

func TestPutHashDatabase(test *testing.T) {

	test.Run("Calls PutItem", func(test *testing.T) {
		db := &MockDyamodb{}
		initDatabase(db)

		putHashInDatabase("Rishi is cool", "2582c03f8bbd94611a6d24df12b9ab218a2a3db9")
	
		db.AssertCalled(test, "PutItem")
	})

	test.Run("Given a valid string dynamo-db does not throw an error", func(test *testing.T) {
		db := &MockDyamodb{}
		initDatabase(db)

		err := putHashInDatabase("Rishi is cool", "2582c03f8bbd94611a6d24df12b9ab218a2a3db9")

		assert.Equal(test, nil, err)
	})

}