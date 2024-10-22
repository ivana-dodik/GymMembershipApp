import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import {
  DynamoDBDocumentClient,
  GetCommand,
  PutCommand,
} from "@aws-sdk/lib-dynamodb";

const client = new DynamoDBClient({});
const dynamoDb = DynamoDBDocumentClient.from(client);

export const handler = async (event) => {
  const { email } = JSON.parse(event.body);
  
  if (!email) {
      return {
        statusCode: 400,
        body: JSON.stringify({ message: 'Email is required', statusCode: 400 }),
      };
    }

  const params = {
      TableName: 'Users',
      Key: { email }
  };

  try {
      const result = await dynamoDb.send(new GetCommand(params));
      const user = result.Item;

      if (!user) {
          return {
              statusCode: 404,
              body: JSON.stringify({ message: 'User not found', statusCode: 404 })
          };
      }

      return {
          statusCode: 200,
          body: JSON.stringify({ role: user.role, statusCode: 200 })
      };
  } catch (err) {
      return {
          statusCode: 500,
          body: JSON.stringify({ error: 'Could not fetch user role', statusCode: 500 })
      };
  }
}