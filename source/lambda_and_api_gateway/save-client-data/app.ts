import { APIGatewayProxyEvent, APIGatewayProxyResult } from 'aws-lambda';
import {DynamoDB} from 'aws-sdk';
import * as uuid from 'uuid';

var documentClient = new DynamoDB.DocumentClient(); 

/**
 *
 * Event doc: https://docs.aws.amazon.com/apigateway/latest/developerguide/set-up-lambda-proxy-integrations.html#api-gateway-simple-proxy-for-lambda-input-format
 * @param {Object} event - API Gateway Lambda Proxy Input Format
 *
 * Return doc: https://docs.aws.amazon.com/apigateway/latest/developerguide/set-up-lambda-proxy-integrations.html
 * @returns {Object} object - API Gateway Lambda Proxy Output Format
 *
 */

export const lambdaHandler = async (event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> => {
    let response: APIGatewayProxyResult;
    params = event.queryStringParameters
    if (params.suburb == null || params.suburb == "" || params.suburb == "undefined") {
        return {
            statusCode: 200,
            body: JSON.stringify({message:"parameters was not provided"})
        };
    }
    var params = {
		Item : {
			"Id" : uuid.v1(),
			"SearchState" : params.state.toLowerCase(),
            "SearchSuburb": params.suburb.toLowerCase()
		},
		TableName : "RawClientData"
	};
    try {
        await documentClient.put(params).promise()
        response = {
            statusCode: 200,
            body: JSON.stringify({message:"done"})
        };
    } catch (err) {
        console.log(err);
        response = {
            statusCode: 500,
            body: JSON.stringify({
                message: 'some error happened',
            }),
        };
    }

    return response;
};
