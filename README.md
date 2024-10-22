# Gym Membership Tracking Application

## Overview
This project implements a gym membership tracking application using Flutter and AWS FaaS (Function as a Service) infrastructure. Users of the application can be either gym members or employees. Members have the ability to update their information and check their membership status. Employees can verify a member's status by scanning their QR code and can extend the membership as needed. Additionally, employees have access to data about all members and can view statistical information.

## Prerequisites
Before implementing the application, you need to have an AWS account. An IAM account with the necessary permissions for the services used is required. Furthermore, you need to install the AWS CLI, Node.js, and npm. The project was created in the Flutter development environment using Visual Studio Code.

## Technologies Used
- **Flutter**: For the client-side user interface.
- **AWS Amplify**: To connect the application with Amazon Cognito for user authentication.
- **API Gateway**: To send requests to AWS Lambda functions, which communicate with DynamoDB for user data storage.
- **DynamoDB**: To manage member data.
- **Amazon SES (Simple Email Service)**: For sending verification emails.

## Features
- **User Authentication**: Utilizes AWS Amplify for user registration and login, with email and password authentication.
- **Membership Management**: Employees can view and update member statuses, and members can manage their personal information.
- **QR Code Generation**: Each member has a unique QR code generated using the `qr_flutter` library for gym entry.
- **Statistics and Analytics**: Employees can view statistics related to memberships and generate reports based on member data.
- **Email Notifications**: Automated emails for account creation, password changes, and forgotten passwords are managed through Amazon SES.

## Application Structure
### Frontend
The Flutter app contains various screens for member and employee functionalities, including:
- **Home Screen**: Displays member information and QR code.
- **Profile Screen**: Allows members to update their personal information.
- **Login/Registration Screens**: For user authentication.

### Backend
- **DynamoDB Table**: The "Users" table contains attributes such as email, date of birth, first name, last name, membership status, expiration date, and user role.
- **AWS Lambda Functions**: Implemented for:
  - Adding users to the DynamoDB table upon registration.
  - Updating membership status at login.
  - Extending membership status when a payment is made.
- **API Gateway**: Configured with RESTful API endpoints for seamless interaction between the frontend and backend.

## Notes
- Ensure that you verify your sender and recipient email addresses in the AWS SES console for email functionality to work in sandbox mode.
- You can find the backend configurations in the `amplify` folder and the necessary configurations in the `amplifyconfiguration.json` file within the `src` folder.

