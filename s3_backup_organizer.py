#!/usr/bin/env python3
#Author: Praneeth_Perera

import boto3
import logging
import datetime

# Initialize logger
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Configuration - Change these as needed
DESTINATION_BUCKET = 'your-destination-bucket-name'   # ← Update this

s3 = boto3.resource('s3')


def lambda_handler(event, context):
    """
    AWS Lambda handler function
    Triggered by S3 upload events.
    """
    try:
        logger.info('Received event: %s', event)

        # Extract information from S3 event
        source_bucket = event['Records'][0]['s3']['bucket']['name']
        filename = event['Records'][0]['s3']['object']['key']
        
        logger.info('Processing file: %s from bucket: %s', filename, source_bucket)

        # Determine folder based on date
        today = datetime.datetime.today()
        day_of_month = today.day
        is_sunday = today.weekday() == 6  # Sunday = 6

        if day_of_month == 1:
            folder = 'monthly/'
        elif is_sunday:
            folder = 'weekly/'
        else:
            folder = 'daily/'

        # Create new key path
        new_key = f"{folder}{filename}"

        # Copy object to new location
        source = {
            'Bucket': source_bucket,
            'Key': filename
        }
        
        s3.meta.client.copy(source, DESTINATION_BUCKET, new_key)
        logger.info('Successfully copied to: %s/%s', DESTINATION_BUCKET, new_key)

        # Delete original file
        s3.Object(source_bucket, filename).delete()
        logger.info('Original file deleted: %s', filename)

        return {
            'statusCode': 200,
            'body': f'Successfully organized {filename}'
        }

    except Exception as e:
        logger.error('Error processing file: %s', str(e))
        raise


if __name__ == "__main__":
    # For local testing only
    print("This is an AWS Lambda function. Use lambda_handler for testing.")

