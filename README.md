# fantastic-enigma

This is a project so we can learn the following
* Golang
  * Http server
    * response codes!  
  * database acces
* AWS
  * lambda 
  * AmazonMQ
  * DynamoDB
  * API gateway

## Idea
API endpoint, recieves string and adds it to a queue (returns 202)
Queue triggers lambda which hashes the string and stores it (along side the string) in dynamo db
API endpoint, retrieves hash from db based on string 

