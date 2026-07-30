# Checkov S3 Event Notifications Requirement

Checkov says: "Ensure S3 buckets should have event notifications enabled"
This might be considered later - debatable for a state bucket?

Typical enterprise implementation:

S3 state bucket
       |
       |
Event Notification
       |
       |
CloudWatch / SNS / SQS
       |
       |
Security monitoring

Example: State file changed unexpectedly > Alert security team > Investigate

Event notifications introduce SNS/SQS resources, IAM permissions, and additional operational complexity. Since this is a bootstrap project, I'm documenting this as a potential future enhancement.
