import boto3
import json
import os
import time
import ast

# Replace with your queue URL
QUEUE_URL = os.environ["SQS_URL"]
#QUEUE_URL = "https://sqs.eu-west-1.amazonaws.com/779733023473/secure-queue"

sqs = boto3.client("sqs")

print("Polling for messages...")

retries = 0

while True:
    response = sqs.receive_message(
        QueueUrl=QUEUE_URL,
        MaxNumberOfMessages=1,      # Receive up to 10 at once
        WaitTimeSeconds=5,          # Long polling
        VisibilityTimeout=30,
        AttributeNames=["All"]
        #MessageSystemAttributeNames=["All"]
    )

    messages = response.get("Messages", [])

    if not messages:
        print("No messages available. Waiting...")
        time.sleep(.5)
        retries += 1
        print(f"Retries: {retries}")
        if retries < 3:
            continue
        else:
            break

    for message in messages:
        queue_attr = sqs.get_queue_attributes(
            QueueUrl=QUEUE_URL,
            AttributeNames=["SqsManagedSseEnabled", "KmsMasterKeyId"]
        )
        body = message["Body"]
        print(f"Encryption is Enabled: {queue_attr["Attributes"].get("SqsManagedSseEnabled")}")
        print(f"KMS Encryption is Enabled: {queue_attr["Attributes"].get("KmsMasterKeyId")}")
        # If you used str(dict) in producer
        try:
            parsed_body = ast.literal_eval(body)
        except Exception:
            parsed_body = json.loads(body)

        if parsed_body.get("sequence_number"):
            sequence_number = parsed_body.get("sequence_number")
        elif parsed_body.get("Message"):
            Message = ast.literal_eval(parsed_body["Message"])
            sequence_number = Message["sequence_number"]

        print(f"Received message with sequence_number: {sequence_number}")

        # Delete message after processing
        sqs.delete_message(
            QueueUrl=QUEUE_URL,
            ReceiptHandle=message["ReceiptHandle"]
        )
