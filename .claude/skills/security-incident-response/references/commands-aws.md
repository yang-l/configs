# AWS commands

This file holds AWS CLI commands for detection, scoping, evidence, and containment in an AWS account. It covers CloudTrail, Athena, GuardDuty, Security Hub, IAM, Cognito, S3, VPC, load balancers, CloudFront, EC2, and Organizations.
Labels and the approval rules are in `../SKILL.md`. Read them before you run any command from this file.

## Contents

- [Before you start](#before-you-start)
- [CloudTrail event history](#cloudtrail-event-history)
  - [AWS-01 Search recent management events in CloudTrail](#aws-01-search-recent-management-events-in-cloudtrail)
- [CloudTrail Lake queries](#cloudtrail-lake-queries)
  - [AWS-02 List CloudTrail Lake event data stores](#aws-02-list-cloudtrail-lake-event-data-stores)
  - [AWS-03 Query access key activity in CloudTrail Lake](#aws-03-query-access-key-activity-in-cloudtrail-lake)
  - [AWS-04 Query failed console sign-ins in CloudTrail Lake](#aws-04-query-failed-console-sign-ins-in-cloudtrail-lake)
  - [AWS-05 Query AccessDenied bursts in CloudTrail Lake](#aws-05-query-accessdenied-bursts-in-cloudtrail-lake)
  - [AWS-06 Check the status of a CloudTrail Lake query](#aws-06-check-the-status-of-a-cloudtrail-lake-query)
  - [AWS-07 Read the results of a CloudTrail Lake query](#aws-07-read-the-results-of-a-cloudtrail-lake-query)
- [Athena queries on CloudTrail logs](#athena-queries-on-cloudtrail-logs)
  - [AWS-08 Query access key activity in Athena](#aws-08-query-access-key-activity-in-athena)
  - [AWS-09 Query failed console sign-ins in Athena](#aws-09-query-failed-console-sign-ins-in-athena)
  - [AWS-10 Query AccessDenied bursts in Athena](#aws-10-query-accessdenied-bursts-in-athena)
  - [AWS-11 Check the status of an Athena query](#aws-11-check-the-status-of-an-athena-query)
  - [AWS-12 Read the results of an Athena query](#aws-12-read-the-results-of-an-athena-query)
- [Athena queries on S3, ALB, and CloudFront logs](#athena-queries-on-s3-alb-and-cloudfront-logs)
  - [AWS-58 Query S3 server access logs for reads by caller and address](#aws-58-query-s3-server-access-logs-for-reads-by-caller-and-address)
  - [AWS-59 Query ALB access logs for one client address](#aws-59-query-alb-access-logs-for-one-client-address)
  - [AWS-60 Query CloudFront standard logs for one client address](#aws-60-query-cloudfront-standard-logs-for-one-client-address)
- [Threat detection findings](#threat-detection-findings)
  - [AWS-13 List GuardDuty detectors](#aws-13-list-guardduty-detectors)
  - [AWS-14 List GuardDuty finding IDs by criteria](#aws-14-list-guardduty-finding-ids-by-criteria)
  - [AWS-15 Read GuardDuty findings](#aws-15-read-guardduty-findings)
  - [AWS-16 Read Security Hub findings](#aws-16-read-security-hub-findings)
  - [AWS-17 List IAM Access Analyzer analyzers](#aws-17-list-iam-access-analyzer-analyzers)
  - [AWS-18 List IAM Access Analyzer findings](#aws-18-list-iam-access-analyzer-findings)
- [IAM credentials and roles](#iam-credentials-and-roles)
  - [AWS-19 Read the stored IAM credential report](#aws-19-read-the-stored-iam-credential-report)
  - [AWS-20 Generate a new IAM credential report](#aws-20-generate-a-new-iam-credential-report)
  - [AWS-21 Check when an access key was last used](#aws-21-check-when-an-access-key-was-last-used)
  - [AWS-22 List the access keys of an IAM user](#aws-22-list-the-access-keys-of-an-iam-user)
  - [AWS-23 Read the trust policy of an IAM role](#aws-23-read-the-trust-policy-of-an-iam-role)
  - [AWS-24 Search role trust policies for a principal](#aws-24-search-role-trust-policies-for-a-principal)
  - [AWS-25 List the inline policies of an IAM role](#aws-25-list-the-inline-policies-of-an-iam-role)
- [Cognito user pools](#cognito-user-pools)
  - [AWS-26 Check the Cognito self sign-up setting](#aws-26-check-the-cognito-self-sign-up-setting)
  - [AWS-27 Save the full Cognito user pool configuration](#aws-27-save-the-full-cognito-user-pool-configuration)
  - [AWS-28 List Cognito app clients](#aws-28-list-cognito-app-clients)
  - [AWS-29 List Cognito users by status](#aws-29-list-cognito-users-by-status)
- [S3 logging and public access](#s3-logging-and-public-access)
  - [AWS-30 Check S3 server access logging for a bucket](#aws-30-check-s3-server-access-logging-for-a-bucket)
  - [AWS-31 Check the public access block of a bucket](#aws-31-check-the-public-access-block-of-a-bucket)
  - [AWS-32 Check whether a bucket policy makes the bucket public](#aws-32-check-whether-a-bucket-policy-makes-the-bucket-public)
  - [AWS-33 Read the ACL of a bucket](#aws-33-read-the-acl-of-a-bucket)
  - [AWS-34 Check the public access block of the account](#aws-34-check-the-public-access-block-of-the-account)
- [Network logs and exposure](#network-logs-and-exposure)
  - [AWS-35 Find VPC flow logs for a resource](#aws-35-find-vpc-flow-logs-for-a-resource)
  - [AWS-36 Query VPC flow logs with Logs Insights](#aws-36-query-vpc-flow-logs-with-logs-insights)
  - [AWS-37 Read the results of a Logs Insights query](#aws-37-read-the-results-of-a-logs-insights-query)
  - [AWS-38 List load balancers](#aws-38-list-load-balancers)
  - [AWS-39 Check ALB access log settings](#aws-39-check-alb-access-log-settings)
  - [AWS-40 List ALB listeners](#aws-40-list-alb-listeners)
  - [AWS-41 List ALB listener rules](#aws-41-list-alb-listener-rules)
  - [AWS-42 Read CloudFront distribution logging settings](#aws-42-read-cloudfront-distribution-logging-settings)
  - [AWS-43 List CloudFront standard logging v2 delivery sources](#aws-43-list-cloudfront-standard-logging-v2-delivery-sources)
  - [AWS-44 List CloudFront standard logging v2 deliveries](#aws-44-list-cloudfront-standard-logging-v2-deliveries)
  - [AWS-45 Find security groups that allow inbound traffic from the internet](#aws-45-find-security-groups-that-allow-inbound-traffic-from-the-internet)
  - [AWS-46 List inbound rules of a security group that allow the internet](#aws-46-list-inbound-rules-of-a-security-group-that-allow-the-internet)
  - [AWS-47 Check the IMDSv2 setting of instances](#aws-47-check-the-imdsv2-setting-of-instances)
- [Organizations policies](#organizations-policies)
  - [AWS-48 List service control policies](#aws-48-list-service-control-policies)
  - [AWS-49 Read a service control policy](#aws-49-read-a-service-control-policy)
  - [AWS-50 List the targets of a service control policy](#aws-50-list-the-targets-of-a-service-control-policy)
- [Containment actions](#containment-actions)
  - [AWS-51 Revoke all active sessions of an IAM role](#aws-51-revoke-all-active-sessions-of-an-iam-role)
  - [AWS-52 Deactivate an IAM access key](#aws-52-deactivate-an-iam-access-key)
  - [AWS-53 Require IMDSv2 on an instance](#aws-53-require-imdsv2-on-an-instance)
  - [AWS-54 Record the security groups of an instance](#aws-54-record-the-security-groups-of-an-instance)
  - [AWS-55 Isolate an instance with a security group](#aws-55-isolate-an-instance-with-a-security-group)
  - [AWS-56 Snapshot an EBS volume for evidence](#aws-56-snapshot-an-ebs-volume-for-evidence)
  - [AWS-57 Disable Cognito self sign-up](#aws-57-disable-cognito-self-sign-up)
  - [AWS-61 Block public access on one bucket](#aws-61-block-public-access-on-one-bucket)

## Before you start

- Replace every `<placeholder>` before you run a command. Never run a command that still holds angle brackets.
- Add `--profile <profile> --region <region> --no-cli-pager` to every command. Each command below already has them.
- A human creates the AWS profile. The agent never reads, prints, or stores the credentials behind it.
- A profile or the environment can send AWS CLI requests to a custom endpoint. The sources are `AWS_ENDPOINT_URL`, `AWS_ENDPOINT_URL_<SERVICE>`, and `endpoint_url` in the profile or in a `services` section of the config file ([AWS CLI endpoints](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-endpoints.html)). Before the first command, ask the human to set `AWS_IGNORE_CONFIGURED_ENDPOINT_URLS=true` in the shell. The CLI then ignores those settings and uses the default endpoints. Check it with `printenv AWS_IGNORE_CONFIGURED_ENDPOINT_URLS`, which must print `true`. Do this again before each WRITE command. A `--endpoint-url` option on the command line still takes priority, so never add one.
- A profile name does not prove which account it reaches. Before the first command with a profile, check the account with the read below. Run it again before each WRITE command. It is READ-ONLY, SENSITIVE, because the ARN can name a person. It needs no permission. Ask the human first. Save the output.

  ```bash
  aws sts get-caller-identity \
    --query '{Account:Account,Arn:Arn}' \
    --profile <profile> --region <region> --no-cli-pager
  ```

  Compare `Account` with the account ID that the human named for the incident. When they differ, stop and tell the human. Doc: https://docs.aws.amazon.com/cli/latest/reference/sts/get-caller-identity.html (checked 2026-11-12). Local help: checked with aws-cli (`aws sts get-caller-identity help`, fields `Account` and `Arn`).

- Most commands return JSON. The AWS CLI default output format is JSON. Add `--output json` when the profile sets another format.
- Save output to a file in the case folder. Add this redirect to the end of the command:

  ```bash
  > "<evidence-dir>/<entry-id>-<short-name>-$(date -u +%Y%m%dT%H%M%SZ).json"
  ```

- The file name holds a UTC timestamp. The redirect writes a local file and changes nothing in AWS.
- Output files can hold SENSITIVE data. Keep them in the case folder.
- Write all times in UTC. Use ISO 8601, for example `<start-time-iso8601>`. Each entry names the format that it needs.
- CloudTrail Lake is closed to new customers from 2026-05-31. An account without an event data store uses the CloudTrail trail with Athena, or event history (AWS-01).

## CloudTrail event history

### AWS-01 Search recent management events in CloudTrail

- Purpose: find management events for one access key in the last 90 days. Phase: scoping.
- Label: READ-ONLY, SENSITIVE
- Permission: `cloudtrail:LookupEvents`
- Command:

  ```bash
  aws cloudtrail lookup-events \
    --lookup-attributes AttributeKey=AccessKeyId,AttributeValue=<access-key-id> \
    --start-time <start-time-iso8601> \
    --end-time <end-time-iso8601> \
    --profile <profile> --region <region> --no-cli-pager
  ```

- Output: a list of events. Each event holds `EventName`, `EventTime`, `Username`, and a `CloudTrailEvent` JSON string. Look for: unknown `sourceIPAddress` values, `errorCode` values, and IAM, STS, or S3 write calls. The command reads one Region. Repeat it for each Region. The API allows two requests per second per account per Region.
- Approval: ask the human first.
- Doc: https://docs.aws.amazon.com/awscloudtrail/latest/userguide/view-cloudtrail-events-cli.html (checked 2026-11-12)
- Local help: checked with aws-cli (`aws cloudtrail lookup-events help`). The command takes one lookup attribute. Other keys are `EventName`, `Username`, `EventSource`, `ResourceName`, `ReadOnly`, `ResourceType`, and `EventId`. It returns management events only.

## CloudTrail Lake queries

CloudTrail Lake queries run on an event data store. The `FROM` value in the SQL is the ID part of the event data store ARN. Charges depend on the data scanned. Always add an `eventTime` range. Before AWS-03, AWS-04, or AWS-05, run the coverage read in AWS-03 for the event data store. It needs `cloudtrail:GetEventDataStore`. Record each excluded event type, account, Region, and period as a scoping gap. No row can mean that the store never collected the event.

### AWS-02 List CloudTrail Lake event data stores

- Purpose: find the event data store ID for the SQL `FROM` clause. Phase: scoping.
- Label: READ-ONLY, SENSITIVE
- Permission: `cloudtrail:ListEventDataStores`
- Command:

  ```bash
  aws cloudtrail list-event-data-stores \
    --query '{EventDataStores: EventDataStores[].[Name,EventDataStoreArn,Status,RetentionPeriod], NextToken: NextToken}' \
    --profile <profile> --region <region> --no-cli-pager
  ```

- Output: `EventDataStores` rows with name, ARN, status, and retention in days, and a `NextToken` value. The ID is the last part of the ARN. Look for: a retention period shorter than the incident window, and a status other than `ENABLED`. The command returns one page. Read every page:
  1. Check the output for a `NextToken` value other than `null`.
  2. When there is one, run the same command again with `--next-token <next-token>` and the exact token from the output.
  3. Ask the human before each page, because each page is a separate SENSITIVE command. Save each page.
  4. Repeat until `NextToken` is `null`. Only then is the list complete.
- Approval: ask the human first.
- Doc: https://docs.aws.amazon.com/awscloudtrail/latest/APIReference/API_ListEventDataStores.html and https://docs.aws.amazon.com/awscloudtrail/latest/userguide/cloudtrail-lake-service-availability-change.html (checked 2026-11-12)
- Local help: checked with aws-cli (`aws cloudtrail list-event-data-stores help`). The command has `--next-token` and `--max-results`. It has no `--max-items` or `--starting-token`. The response holds `NextToken`, "a token you can use to get the next page of results". The `--query` hash that keeps `NextToken` was not run.

### AWS-03 Query access key activity in CloudTrail Lake

- Purpose: list the recorded events of one access key. Phase: scoping.
- Label: READ-ONLY, SENSITIVE
- Permission: `cloudtrail:StartQuery`. The coverage read needs `cloudtrail:GetEventDataStore`.
- Command:

  ```bash
  aws cloudtrail start-query \
    --query-statement "SELECT eventTime, eventSource, eventName, awsRegion, sourceIPAddress, userAgent, errorCode FROM <event-data-store-id> WHERE userIdentity.accessKeyId = '<access-key-id>' AND eventTime > '<start-time-utc>' AND eventTime < '<end-time-utc>' ORDER BY eventTime" \
    --profile <profile> --region <region> --no-cli-pager
  ```

- Output: a `QueryId`. Read the rows with AWS-06 and AWS-07. Look for: a new `sourceIPAddress`, an unusual `userAgent`, calls in unused Regions, and IAM or STS calls.
- Coverage: the store holds only the events that its selectors select. By default, an event data store logs no data events, such as S3 `GetObject`. Read the coverage of the store with this command. It is READ-ONLY, SENSITIVE. Ask the human first.

  ```bash
  aws cloudtrail get-event-data-store \
    --event-data-store <event-data-store-id> \
    --query '{Status:Status,Created:CreatedTimestamp,Updated:UpdatedTimestamp,Selectors:AdvancedEventSelectors,MultiRegion:MultiRegionEnabled,Organization:OrganizationEnabled,RetentionDays:RetentionPeriod}' \
    --profile <profile> --region <region> --no-cli-pager
  ```

  The read shows the current settings only. The store holds no events from before `Created`, unless a human copied them in. When `Updated` is later than the start of the incident window, the coverage before that time is unknown. A `Status` other than `ENABLED` can mean that the store does not take new events. Compare each condition in `Selectors` with the principal, the resource, and the action of the incident, as in step 2 of the Athena section intro. Record each event type, Region, account, time range, and condition that can exclude the incident activity as a scoping gap. No row for an action does not prove that the key did not do it.

- Cost note: CloudTrail charges for the bytes scanned. Write `<start-time-utc>` and `<end-time-utc>` as `YYYY-MM-DD HH:MM:SS`. The command has no `--delivery-s3-uri`, so no result file goes to S3.
- Approval: ask the human first.
- Doc: https://docs.aws.amazon.com/awscloudtrail/latest/userguide/lake-queries-cli.html, https://docs.aws.amazon.com/awscloudtrail/latest/APIReference/API_GetEventDataStore.html, and https://docs.aws.amazon.com/awscloudtrail/latest/userguide/logging-data-events-with-cloudtrail.html (checked 2026-11-12)
- Local help: checked with aws-cli (`aws cloudtrail start-query help`).

### AWS-04 Query failed console sign-ins in CloudTrail Lake

- Purpose: list failed console sign-ins in a time range. Phase: detection.
- Label: READ-ONLY, SENSITIVE
- Permission: `cloudtrail:StartQuery`
- Command:

  ```bash
  aws cloudtrail start-query \
    --query-statement "SELECT eventTime, userIdentity.type, userIdentity.userName, sourceIPAddress, userAgent, errorMessage FROM <event-data-store-id> WHERE eventName = 'ConsoleLogin' AND element_at(responseElements, 'ConsoleLogin') = 'Failure' AND eventTime > '<start-time-utc>' AND eventTime < '<end-time-utc>' ORDER BY eventTime" \
    --profile <profile> --region <region> --no-cli-pager
  ```

- Output: a `QueryId`. Read the rows with AWS-06 and AWS-07. Look for: many failures from one `sourceIPAddress`, and many user names from one address. The query returns failures only. To find a success after the failures, ask the human to approve the same query with `'Success'` in place of `'Failure'`. Compare the times of the two results.
- Cost note: CloudTrail charges for the bytes scanned. Write the times as `YYYY-MM-DD HH:MM:SS`. No result file goes to S3.
- Approval: ask the human first.
- Doc: https://docs.aws.amazon.com/awscloudtrail/latest/userguide/lake-queries-optimization.html (checked 2026-11-12)
- Local help: checked with aws-cli (`aws cloudtrail start-query help`). The docs show `element_at` on map fields such as `requestParameters`. The docs did not confirm that `responseElements` is also a map. If the query fails, check the type of `responseElements` in your event data store.

### AWS-05 Query AccessDenied bursts in CloudTrail Lake

- Purpose: count denied API calls by caller and source address. Phase: detection.
- Label: READ-ONLY, SENSITIVE
- Permission: `cloudtrail:StartQuery`
- Command:

  ```bash
  aws cloudtrail start-query \
    --query-statement "SELECT userIdentity.arn, sourceIPAddress, count(*) AS denied_count FROM <event-data-store-id> WHERE (errorCode LIKE 'AccessDenied%' OR errorCode LIKE '%Unauthorized%') AND eventTime > '<start-time-utc>' AND eventTime < '<end-time-utc>' GROUP BY userIdentity.arn, sourceIPAddress ORDER BY denied_count DESC LIMIT 50" \
    --profile <profile> --region <region> --no-cli-pager
  ```

- Output: a `QueryId`. Read the rows with AWS-06 and AWS-07. Look for: a caller with a high `denied_count`. A burst of denials often means an attacker is testing permissions.
- Cost note: CloudTrail charges for the bytes scanned. Write the times as `YYYY-MM-DD HH:MM:SS`. No result file goes to S3.
- Approval: ask the human first.
- Doc: https://docs.aws.amazon.com/awscloudtrail/latest/userguide/lake-queries-optimization.html (checked 2026-11-12)
- Local help: checked with aws-cli (`aws cloudtrail start-query help`).

### AWS-06 Check the status of a CloudTrail Lake query

- Purpose: read the state and the scanned bytes of a Lake query. Phase: scoping.
- Label: READ-ONLY, SENSITIVE
- Permission: `cloudtrail:DescribeQuery`
- Command:

  ```bash
  aws cloudtrail describe-query \
    --query-id <query-id> \
    --profile <profile> --region <region> --no-cli-pager
  ```

- Output: `QueryStatus`, `QueryString`, and `QueryStatistics`. Look for: `FINISHED` before you read results. Queries that run longer than one hour can time out. Partial results are still available.
- Cost note: `BytesScanned` is the billed amount when the query is no longer running.
- Approval: ask the human first.
- Doc: https://docs.aws.amazon.com/awscloudtrail/latest/userguide/lake-queries-cli.html (checked 2026-11-12)
- Local help: checked with aws-cli (`aws cloudtrail describe-query help`).

### AWS-07 Read the results of a CloudTrail Lake query

- Purpose: read the rows of a finished Lake query. Phase: scoping.
- Label: READ-ONLY, SENSITIVE
- Permission: `cloudtrail:GetQueryResults`
- Command:

  ```bash
  aws cloudtrail get-query-results \
    --query-id <query-id> \
    --profile <profile> --region <region> --no-cli-pager
  ```

- Output: `QueryResultRows` rows and a `NextToken` when more pages exist. Look for: the fields named in the query. Save the output to a file. The command returns one page. Read every page:
  1. Check the output for a `NextToken` value.
  2. When there is one, run the same command again with `--next-token <next-token>` and the exact token from the output.
  3. Ask the human before each page, because each page is a separate SENSITIVE command. Save each page in its own file.
  4. Repeat until the output has no `NextToken`. Only then are the results complete.
- Approval: ask the human first.
- Doc: https://docs.aws.amazon.com/awscloudtrail/latest/userguide/lake-queries-cli.html and https://docs.aws.amazon.com/awscloudtrail/latest/APIReference/API_GetQueryResults.html (checked 2026-11-12)
- Local help: checked with aws-cli (`aws cloudtrail get-query-results help`). The command has `--next-token` and `--max-query-results`. It has no `--max-items` or `--starting-token`. The response holds `QueryResultRows` and `NextToken`, "a token you can use to get the next page of query results".

## Athena queries on CloudTrail logs

These queries assume a CloudTrail table made with partition projection, as in the Doc line of AWS-08. The table has a `timestamp` partition in `yyyy/MM/dd` format. Change the partition filter when the table differs.
A human creates the Athena database, the work group, and the results bucket. Athena keeps a record of each query string.

Before each query, read the work group settings. A work group can override the result location in the command, and it can keep results in Athena managed storage for 24 hours. This read is READ-ONLY, SENSITIVE. Ask the human first. It needs `athena:GetWorkGroup`.

```bash
aws athena get-work-group \
  --work-group <athena-workgroup> \
  --query 'WorkGroup.Configuration.{Enforce:EnforceWorkGroupConfiguration,OutputLocation:ResultConfiguration.OutputLocation,Managed:ManagedQueryResultsConfiguration.Enabled,ManagedKmsKey:ManagedQueryResultsConfiguration.EncryptionConfiguration.KmsKey}' \
  --profile <profile> --region <region> --no-cli-pager
```

When `Enforce` is `true`, the query uses the work group `OutputLocation`, not the one in the command. When `Managed` is `true`, the work group stores results in Athena managed storage, without an S3 bucket:

- Remove the `--result-configuration` line from the query command. The query then needs no S3 write on a results location.
- Athena keeps the results for 24 hours and then deletes them. Save them with AWS-12 inside that time.
- AWS-12 then needs no S3 read permission.

Each query entry in this file needs these permissions:

- `athena:StartQueryExecution` on the work group.
- Read access to the AWS Glue Data Catalog: `glue:GetDatabase` and `glue:GetTable` on the catalog, the database, and the table. For a partitioned table, add `glue:GetPartitions` on the same three resources ([Glue access for Athena](https://docs.aws.amazon.com/athena/latest/ug/fine-grained-access-to-glue-resources.html)).
- S3 read on the log bucket.
- For S3 results: S3 write on the results location.
- For managed results: no S3 access for results. When `ManagedKmsKey` names a customer managed key, add `kms:Decrypt`, `kms:GenerateDataKey`, and `kms:DescribeKey` on that key. AWS-12 needs the same key access ([encrypt managed query results](https://docs.aws.amazon.com/athena/latest/ug/encrypting-managed-results.html)).
- When the log bucket uses a customer managed KMS key, add `kms:Decrypt` on that key.
- When the S3 results use a KMS key, add `kms:GenerateDataKey` and `kms:Decrypt` on that key. AWS-12 needs the same key access.
- When the Data Catalog metadata is encrypted, add `kms:GenerateDataKey`, `kms:Decrypt`, and `kms:Encrypt` ([Athena encryption at rest](https://docs.aws.amazon.com/athena/latest/ug/encryption.html)).

Ask the human which keys apply. A denied KMS call can stop the query.

Before each query, tell the human the effective result destination, and ask for approval:

- When `Managed` is `true`: Athena managed storage, kept for 24 hours.
- When `Enforce` is `true`: the work group `OutputLocation`.
- Otherwise: the `--result-configuration` location in the command. Athena uses the settings in the query when the work group does not override them ([override client-side settings](https://docs.aws.amazon.com/athena/latest/ug/workgroups-settings-override.html)).

AWS-11 then checks the result against that approved destination. After each query, check the result in AWS-11. A failed or cancelled query can leave partial results under the S3 prefix. Athena does not delete them.

A trail records only the events that its selectors select. By default, trails do not log data events, such as S3 `GetObject` ([data events](https://docs.aws.amazon.com/awscloudtrail/latest/userguide/logging-data-events-with-cloudtrail.html)). Before the first query, check which events the logs hold and which logs the table reads. Run the four reads below. They are READ-ONLY, SENSITIVE. Ask the human first for each read. They need `cloudtrail:DescribeTrails`, `cloudtrail:GetEventSelectors`, `cloudtrail:GetTrailStatus`, and `glue:GetTable`.

1. List the trails in each Region in scope. Run the read once for each Region. The list holds the trails of `<region>` and the shadow trails of multi-Region and organization trails. It does not hold a single-Region trail of another Region.

   ```bash
   aws cloudtrail describe-trails \
     --query 'trailList[].{Name:Name,TrailARN:TrailARN,HomeRegion:HomeRegion,Bucket:S3BucketName,Prefix:S3KeyPrefix,MultiRegion:IsMultiRegionTrail,Organization:IsOrganizationTrail,GlobalServices:IncludeGlobalServiceEvents}' \
     --profile <profile> --region <region> --no-cli-pager
   ```

   Ask the human which trail writes to the log bucket. Record its `TrailARN` as `<trail-arn>` and its `HomeRegion` as `<trail-home-region>`. Use the ARN in the next reads. A member account of an organization trail must use the full ARN, not the name. When `GlobalServices` is `false`, the trail does not record calls to global services such as IAM. When it is `true`, the trail gets those calls only when `MultiRegion` is `true` or `HomeRegion` is the partition leader Region, for example `us-east-1` ([CreateTrail](https://docs.aws.amazon.com/awscloudtrail/latest/APIReference/API_CreateTrail.html)). Otherwise, record global service calls as a scoping gap. Then ask the human for a trail that covers them.

2. Read the event selectors in the home Region of the trail.

   ```bash
   aws cloudtrail get-event-selectors --trail-name '<trail-arn>' \
     --profile <profile> --region <trail-home-region> --no-cli-pager
   ```

   First check that the trail records management events, such as IAM, STS, and console sign-in calls. For basic selectors, `IncludeManagementEvents` must be `true`. For advanced selectors, one selector must have `eventCategory` equal to `Management`. Otherwise, record management events as not covered. Then compare each condition of each selector with the principal, the resource, and the action of the incident. A condition can name `eventName`, `eventSource`, `resources.ARN`, `userIdentity.arn`, `readOnly`, `ReadWriteType`, or `ExcludeManagementEventSources`. Record each condition that can exclude the incident activity as a scoping gap.

3. Read the trail status in each Region in scope. Each read covers one Region only.

   ```bash
   aws cloudtrail get-trail-status --name '<trail-arn>' \
     --profile <profile> --region <region> --no-cli-pager
   ```

   Look for: `IsLogging`, `StartLoggingTime`, `StopLoggingTime`, `LatestDeliveryTime`, and `LatestDeliveryError`. `IsLogging` shows only the current state. A `LatestDeliveryError`, or a `LatestDeliveryTime` before the end of the window, means a delivery gap ([GetTrailStatus](https://docs.aws.amazon.com/awscloudtrail/latest/APIReference/API_GetTrailStatus.html)).

4. Read the table definition.

   ```bash
   aws glue get-table --database-name <athena-database> --name <cloudtrail-table> \
     --query 'Table.{Location:StorageDescriptor.Location,Template:Parameters."storage.location.template",Enabled:Parameters."projection.enabled",Type:Parameters."projection.timestamp.type",Format:Parameters."projection.timestamp.format",Range:Parameters."projection.timestamp.range"}' \
     --profile <profile> --region <region> --no-cli-pager
   ```

   The example table on the AWS-08 Doc page reads one account and one Region. Check that the bucket, the prefix, the account, and the Region in `Location` and `Template` match the trail and the scope. Check that `Enabled` is `true`, `Type` is `date`, and `Format` is `yyyy/MM/dd`, as the queries in this file expect. Otherwise, stop and tell the human, because partition projection can be off ([set up partition projection](https://docs.aws.amazon.com/athena/latest/ug/partition-projection-setting-up.html)). Check that `Range` includes every partition date from `<start-partition-date>` to `<end-partition-date>`. A query outside the range returns zero rows and no error ([partition projection](https://docs.aws.amazon.com/athena/latest/ug/partition-projection.html)). For each other account or Region, query a table for it, or record a gap.

These reads show the current settings only. Record each Region, account, event type, and period that you cannot confirm as a scoping gap. An empty result does not prove that the key took no action. Local help: checked with aws-cli (`aws cloudtrail describe-trails help`, `get-event-selectors help`, `get-trail-status help`, `aws glue get-table help`). The JMESPath queries were not tested. The quoted keys follow the [JMESPath specification](https://jmespath.org/specification.html).

The log files are in folders named by the day of delivery, not the day of the event. CloudTrail delivers a file about 5 minutes after the call on average, and AWS does not guarantee that time. A late file can therefore be in any later folder. Set `<end-partition-date>` to the UTC date of the query run. Keep the filter on the event time. This scans more data than the window. When the cost is too high, the human can choose an earlier end date. Then record the days after that date as a gap. For a recent window, run the query again later, because more files can arrive.

### AWS-08 Query access key activity in Athena

- Purpose: list the API calls that the trail recorded for one access key. Phase: scoping.
- Label: READ-ONLY, SENSITIVE
- Permission: the query permissions in the intro of the CloudTrail Athena section.
- Command:

  ```bash
  aws athena start-query-execution \
    --query-string "SELECT eventtime, eventsource, eventname, awsregion, sourceipaddress, useragent, errorcode FROM <athena-database>.<cloudtrail-table> WHERE useridentity.accesskeyid = '<access-key-id>' AND \"timestamp\" >= '<start-partition-date>' AND \"timestamp\" <= '<end-partition-date>' AND eventtime >= '<start-time-iso8601>' AND eventtime <= '<end-time-iso8601>' ORDER BY eventtime" \
    --query-execution-context Database=<athena-database> \
    --work-group <athena-workgroup> \
    --result-configuration OutputLocation=s3://<athena-results-bucket>/<athena-results-prefix>/ \
    --profile <profile> --region <region> --no-cli-pager
  ```

- Output: a `QueryExecutionId`. Read the rows with AWS-11 and AWS-12. Look for: a new `sourceipaddress`, an unusual `useragent`, calls in unused Regions, and IAM or STS calls. Write `<start-partition-date>` as `yyyy/MM/dd`. Set `<end-partition-date>` as the section intro says.
- Cost note: Athena charges for the data scanned. The partition filter limits the scan. Results go to the effective destination that the human approved (see the section intro).
- Approval: ask the human first.
- Doc: https://docs.aws.amazon.com/athena/latest/ug/create-cloudtrail-table-partition-projection.html (checked 2026-11-12)
- Local help: checked with aws-cli (`aws athena start-query-execution help`).

### AWS-09 Query failed console sign-ins in Athena

- Purpose: list failed console sign-ins in a time range. Phase: detection.
- Label: READ-ONLY, SENSITIVE
- Permission: the query permissions in the intro of the CloudTrail Athena section.
- Command:

  ```bash
  aws athena start-query-execution \
    --query-string "SELECT eventtime, useridentity.type, useridentity.username, sourceipaddress, useragent, errormessage FROM <athena-database>.<cloudtrail-table> WHERE eventname = 'ConsoleLogin' AND json_extract_scalar(responseelements, '$.ConsoleLogin') = 'Failure' AND \"timestamp\" >= '<start-partition-date>' AND \"timestamp\" <= '<end-partition-date>' AND eventtime >= '<start-time-iso8601>' AND eventtime <= '<end-time-iso8601>' ORDER BY eventtime" \
    --query-execution-context Database=<athena-database> \
    --work-group <athena-workgroup> \
    --result-configuration OutputLocation=s3://<athena-results-bucket>/<athena-results-prefix>/ \
    --profile <profile> --region <region> --no-cli-pager
  ```

- Output: a `QueryExecutionId`. Read the rows with AWS-11 and AWS-12. Look for: many failures from one `sourceipaddress`, and many user names from one address. The query returns failures only. To find a success after the failures, ask the human to approve the same query with `'Success'` in place of `'Failure'`. Compare the times of the two results.
- Cost note: Athena charges for the data scanned. Results go to the effective destination that the human approved (see the section intro).
- Approval: ask the human first.
- Doc: https://docs.aws.amazon.com/athena/latest/ug/create-cloudtrail-table-partition-projection.html (checked 2026-11-12)
- Local help: checked with aws-cli (`aws athena start-query-execution help`). The table in the Doc stores `responseelements` as a string. The query reads it as JSON.

### AWS-10 Query AccessDenied bursts in Athena

- Purpose: count denied API calls by caller and source address. Phase: detection.
- Label: READ-ONLY, SENSITIVE
- Permission: the query permissions in the intro of the CloudTrail Athena section.
- Command:

  ```bash
  aws athena start-query-execution \
    --query-string "SELECT useridentity.arn, sourceipaddress, count(*) AS denied_count FROM <athena-database>.<cloudtrail-table> WHERE (errorcode LIKE 'AccessDenied%' OR errorcode LIKE '%Unauthorized%') AND \"timestamp\" >= '<start-partition-date>' AND \"timestamp\" <= '<end-partition-date>' AND eventtime >= '<start-time-iso8601>' AND eventtime <= '<end-time-iso8601>' GROUP BY useridentity.arn, sourceipaddress ORDER BY denied_count DESC LIMIT 50" \
    --query-execution-context Database=<athena-database> \
    --work-group <athena-workgroup> \
    --result-configuration OutputLocation=s3://<athena-results-bucket>/<athena-results-prefix>/ \
    --profile <profile> --region <region> --no-cli-pager
  ```

- Output: a `QueryExecutionId`. Read the rows with AWS-11 and AWS-12. Look for: a caller with a high `denied_count`. A burst of denials often means an attacker is testing permissions.
- Cost note: Athena charges for the data scanned. Results go to the effective destination that the human approved (see the section intro).
- Approval: ask the human first.
- Doc: https://docs.aws.amazon.com/athena/latest/ug/query-examples-cloudtrail-logs.html (checked 2026-11-12)
- Local help: checked with aws-cli (`aws athena start-query-execution help`).

### AWS-11 Check the status of an Athena query

- Purpose: read the state and the scanned bytes of an Athena query. Phase: scoping.
- Label: READ-ONLY, SENSITIVE
- Permission: `athena:GetQueryExecution`
- Command:

  ```bash
  aws athena get-query-execution \
    --query-execution-id <query-execution-id> \
    --profile <profile> --region <region> --no-cli-pager
  ```

- Output: `Status.State`, the query string, the result location, and statistics. Look for: `SUCCEEDED` before you read results. Then check where the results are. Read `QueryExecution.ManagedQueryResultsConfiguration.Enabled` first:
  - `true`: Athena keeps the results in managed storage, and the query has no S3 `OutputLocation`. Skip the prefix check. Read the results with AWS-12 within 24 hours.
  - `false` or missing: `QueryExecution.ResultConfiguration.OutputLocation` names the result object, such as `s3://<athena-results-bucket>/<athena-results-prefix>/<query-execution-id>.csv`. Check that it starts with the prefix that the human approved.

  When the result does not match the destination that the human approved before the query, stop and tell the human. `FAILED` shows a reason in `StateChangeReason`.

- Approval: ask the human first.
- Doc: https://docs.aws.amazon.com/athena/latest/APIReference/API_GetQueryExecution.html, https://docs.aws.amazon.com/athena/latest/APIReference/API_ResultConfiguration.html, https://docs.aws.amazon.com/athena/latest/ug/managed-results.html, https://docs.aws.amazon.com/athena/latest/ug/querying.html, and https://docs.aws.amazon.com/awscloudtrail/latest/userguide/get-and-view-cloudtrail-log-files.html (checked 2026-11-12). The last page says that the folder date is the day the file was published.
- Local help: checked with aws-cli (`aws athena get-query-execution help` with fields `QueryExecution.ResultConfiguration.OutputLocation` and `QueryExecution.ManagedQueryResultsConfiguration.Enabled`, `aws athena get-work-group help`, fields `WorkGroup.Configuration.EnforceWorkGroupConfiguration`, `ResultConfiguration.OutputLocation`, `ManagedQueryResultsConfiguration.Enabled`, and `ManagedQueryResultsConfiguration.EncryptionConfiguration.KmsKey`).

### AWS-12 Read the results of an Athena query

- Purpose: read the rows of a finished Athena query. Phase: scoping.
- Label: READ-ONLY, SENSITIVE
- Permission: `athena:GetQueryResults`. For S3 results, also S3 read on the results location. When those results use a KMS key, also `kms:GenerateDataKey` and `kms:Decrypt` on that key. For managed results, the caller needs `athena:GetQueryResults` on the work group and no S3 read. When managed results use a customer managed KMS key, the caller also needs `kms:Decrypt`, `kms:GenerateDataKey`, and `kms:DescribeKey` on that key ([managed query results](https://docs.aws.amazon.com/athena/latest/ug/managed-results.html)).
- Command:

  ```bash
  aws athena get-query-results \
    --query-execution-id <query-execution-id> \
    --profile <profile> --region <region> --no-cli-pager
  ```

- Output: `ResultSet` rows. Look for: the fields named in the query. Save the output to a file.
- Approval: ask the human first.
- Doc: https://docs.aws.amazon.com/athena/latest/APIReference/API_GetQueryResults.html (checked 2026-11-12)
- Local help: checked with aws-cli (`aws athena get-query-results help`).

## Athena queries on S3, ALB, and CloudFront logs

These queries read the content of the logs that AWS-30, AWS-39, and AWS-42 to AWS-44 check. A human creates each table with the `CREATE EXTERNAL TABLE` statement on the Doc page of the entry. The column names below come from those statements. Change them when the table differs. Read the rows with AWS-11 and AWS-12. The setup notes of the CloudTrail Athena section also apply, including the work group read. ALB log folders use the delivery date. S3 log folders use the event date or the delivery date, depending on the logging setting. For both, set `<end-partition-date>` as the CloudTrail section intro says. The time filter in the query keeps the window exact. Write `<start-time-utc>` and `<end-time-utc>` as `yyyy-MM-dd:HH:mm:ss` in UTC.

### AWS-58 Query S3 server access logs for reads by caller and address

- Purpose: find the recorded reads of objects in a bucket, and the bytes sent to each caller in those records. Phase: scoping.
- Label: READ-ONLY, SENSITIVE
- Permission: the query permissions in the intro of the CloudTrail Athena section.
- Command:

  ```bash
  aws athena start-query-execution \
    --query-string "SELECT requester, remoteip, operation, count(*) AS requests, coalesce(sum(bytessent), 0) AS bytes_sent FROM <athena-database>.<s3-access-log-table> WHERE \"timestamp\" >= '<start-partition-date>' AND \"timestamp\" <= '<end-partition-date>' AND parse_datetime(requestdatetime, 'dd/MMM/yyyy:HH:mm:ss Z') BETWEEN parse_datetime('<start-time-utc>', 'yyyy-MM-dd:HH:mm:ss') AND parse_datetime('<end-time-utc>', 'yyyy-MM-dd:HH:mm:ss') AND (operation LIKE '%GET%' OR operation LIKE '%SELECT%') GROUP BY requester, remoteip, operation ORDER BY bytes_sent DESC" \
    --query-execution-context Database=<athena-database> \
    --work-group <athena-workgroup> \
    --result-configuration OutputLocation=s3://<athena-results-bucket>/<athena-results-prefix>/ \
    --profile <profile> --region <region> --no-cli-pager
  ```

- Output: a `QueryExecutionId`. The rows give each `requester`, `remoteip`, and `operation` with the request count and the bytes sent. The `%GET%` filter includes object reads and bucket listings. The `%SELECT%` filter adds S3 Select reads, which AWS names in data exfiltration checks. Look for: a requester or an address that you do not know, a high `bytes_sent`, and `-` as the requester, which means an anonymous request. Write `<start-partition-date>` as `yyyy/MM/dd`. To see single requests, select `requestdatetime`, `operation`, `key`, `httpstatus`, and `useragent` and filter on one `remoteip`. The query has no row limit, so the result can be large. This table reads only the legacy log files in an S3 bucket. Logs from CloudWatch Logs delivery (AWS-30) need another query. S3 delivers log records on a best-effort basis. A record can arrive hours late or never arrive. An empty result does not prove that no read happened.
- Cost note: Athena charges for the data scanned. The `timestamp` partition filter limits the scan. Results go to the effective destination that the human approved (see the section intro).
- Approval: ask the human first.
- Doc: https://docs.aws.amazon.com/AmazonS3/latest/userguide/using-s3-access-logs-to-identify-requests.html (checked 2026-11-12). The table on that page uses date-based partition projection on `timestamp`. AWS recommends CloudTrail data events over server access logs when they are on. https://docs.aws.amazon.com/AmazonS3/latest/userguide/LogFormat.html (checked 2026-11-12) says that `requester` is `-` for unauthenticated requests. https://docs.aws.amazon.com/AmazonS3/latest/userguide/ServerLogs.html (checked 2026-11-12) says that delivery is best effort. https://docs.aws.amazon.com/awscloudtrail/latest/userguide/logging-s3-data-events-governance.html (checked 2026-11-12) names `SelectObjectContent` in exfiltration checks.
- Local help: checked with aws-cli (`aws athena start-query-execution help`).

### AWS-59 Query ALB access logs for one client address

- Purpose: list the recorded requests that one client address sent through a load balancer. Phase: scoping.
- Label: READ-ONLY, SENSITIVE
- Permission: the query permissions in the intro of the CloudTrail Athena section.
- Command:

  ```bash
  aws athena start-query-execution \
    --query-string "SELECT request_creation_time, time, client_ip, request_verb, request_url, elb_status_code, target_status_code, user_agent, domain_name, actions_executed FROM <athena-database>.<alb-access-log-table> WHERE day >= '<start-partition-date>' AND day <= '<end-partition-date>' AND parse_datetime(request_creation_time, 'yyyy-MM-dd''T''HH:mm:ss.SSSSSS''Z') BETWEEN parse_datetime('<start-time-utc>', 'yyyy-MM-dd:HH:mm:ss') AND parse_datetime('<end-time-utc>', 'yyyy-MM-dd:HH:mm:ss') AND client_ip = '<ip-address>' ORDER BY request_creation_time" \
    --query-execution-context Database=<athena-database> \
    --work-group <athena-workgroup> \
    --result-configuration OutputLocation=s3://<athena-results-bucket>/<athena-results-prefix>/ \
    --profile <profile> --region <region> --no-cli-pager
  ```

- Output: a `QueryExecutionId`. The rows give each request with its times, URL, status codes, user agent, and the actions that the load balancer ran. `request_creation_time` is when the load balancer got the request. `time` is when it sent the response, or when a WebSocket closed. The filter uses `request_creation_time`. A WebSocket that is still open has no log entry yet. Record it as a gap. Look for: paths such as admin pages or `.env` files, and a 200 status where you expect a block. Also look for a burst of 4xx codes, and a `domain_name` that the organisation does not serve. Write `<start-partition-date>` as `yyyy/MM/dd`. To find addresses instead, group by `client_ip` and filter on `request_url`. The query has no row limit, so the result can be large. The load balancer logs requests on a best-effort basis. An empty result does not prove that the address sent no request. When a proxy or a CDN sits in front of the load balancer, `client_ip` is the proxy address. The ALB access log has no field for the viewer address. In that case, search the proxy logs for the viewer address first, for example AWS-60 or `commands-cloudflare.md`. Match those requests to ALB rows by time and path.
- Cost note: Athena charges for the data scanned. The `day` partition filter limits the scan. Results go to the effective destination that the human approved (see the section intro).
- Approval: ask the human first.
- Doc: https://docs.aws.amazon.com/athena/latest/ug/create-alb-access-logs-table-partition-projection.html, https://docs.aws.amazon.com/athena/latest/ug/query-alb-access-logs-examples.html, and https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-access-logs.html (checked 2026-11-12)
- Local help: checked with aws-cli (`aws athena start-query-execution help`).

### AWS-60 Query CloudFront standard logs for one client address

- Purpose: list the recorded requests that one client address sent to a CloudFront distribution. Phase: scoping.
- Label: READ-ONLY, SENSITIVE
- Permission: the query permissions in the intro of the CloudTrail Athena section.
- Command:

  ```bash
  aws athena start-query-execution \
    --query-string "SELECT \"date\", time, c_ip, x_forwarded_for, cs_method, cs_host, cs_uri_stem, sc_status, x_edge_result_type, cs_user_agent FROM <athena-database>.<cloudfront-log-table> WHERE \"date\" BETWEEN DATE '<start-date>' AND DATE '<end-date>' AND (c_ip = '<ip-address>' OR contains(transform(split(x_forwarded_for, ','), x -> trim(x)), '<ip-address>')) ORDER BY \"date\", time" \
    --query-execution-context Database=<athena-database> \
    --work-group <athena-workgroup> \
    --result-configuration OutputLocation=s3://<athena-results-bucket>/<athena-results-prefix>/ \
    --profile <profile> --region <region> --no-cli-pager
  ```

- Output: a `QueryExecutionId`. The rows give each request with its host, path, status, edge result, and user agent. Look for: paths that the site does not serve, a 200 status where you expect a block, and an `x_edge_result_type` of `Error` in bursts. Write `<start-date>` as `yyyy-MM-dd`. The `date` and `time` fields give the time when CloudFront finished the response, or when a WebSocket closed. To include long requests, set `<end-date>` at least one day after the window. Then drop rows outside the window by hand. A connection that is still open has no log entry yet. Record it as a gap. The `cs_user_agent` value is URL-encoded. When a proxy sent the request, `c_ip` is the proxy, and the `x_forwarded_for` column holds the viewer address. The query matches the address in either field. `x_forwarded_for` can hold a comma-separated list. Its values come from a request header, so the client can set them (inferred). Treat a match there as a lead. Confirm it with other logs. The query has no row limit, so the result can be large. CloudFront can deliver some entries up to 24 hours late. After 24 hours pass, run the query again for the last 24 hours of the window. CloudFront does not log a request with headers over 20 KB or a URL over 8192 bytes. An empty result does not prove that the address sent no request.
- Cost note: the legacy table on the Doc page has no partitions, so Athena scans every file under the table location. The `date` filter does not limit the scan. Ask the human to point the table at a narrow prefix first. Results go to the effective destination that the human approved (see the section intro).
- Approval: ask the human first.
- Doc: https://docs.aws.amazon.com/athena/latest/ug/create-cloudfront-table-standard-logs.html (checked 2026-11-12). This table is for legacy standard logs. Standard logging (v2) in JSON or Parquet uses other tables, which https://docs.aws.amazon.com/athena/latest/ug/cloudfront-logs.html lists. Their column names were not checked. The field meanings are on https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/standard-logs-reference.html (checked 2026-11-12).
- Local help: checked with aws-cli (`aws athena start-query-execution help`).

## Threat detection findings

### AWS-13 List GuardDuty detectors

- Purpose: find the detector ID for the Region. Phase: detection.
- Label: READ-ONLY, SENSITIVE
- Permission: `guardduty:ListDetectors`
- Command:

  ```bash
  aws guardduty list-detectors \
    --profile <profile> --region <region> --no-cli-pager
  ```

- Output: `DetectorIds`. Look for: an empty list. It means GuardDuty is off in this Region.
- Approval: ask the human first.
- Doc: https://docs.aws.amazon.com/guardduty/latest/APIReference/API_ListDetectors.html (checked 2026-11-12)
- Local help: checked with aws-cli (`aws guardduty list-detectors help`).

### AWS-14 List GuardDuty finding IDs by criteria

- Purpose: list active findings that name one access key. Phase: detection.
- Label: READ-ONLY, SENSITIVE
- Permission: `guardduty:ListFindings`
- Command:

  ```bash
  aws guardduty list-findings \
    --detector-id <detector-id> \
    --finding-criteria '{"Criterion":{"resource.accessKeyDetails.accessKeyId":{"Eq":["<access-key-id>"]},"service.archived":{"Eq":["false"]}}}' \
    --sort-criteria '{"AttributeName":"severity","OrderBy":"DESC"}' \
    --profile <profile> --region <region> --no-cli-pager
  ```

- Output: `FindingIds` only. Read the details with AWS-15. Look for: any ID. Other criteria keys include `severity` (use `{"Gte":7}`), `type`, and `resource.instanceDetails.instanceId`.
- Approval: ask the human first.
- Doc: https://docs.aws.amazon.com/guardduty/latest/APIReference/API_ListFindings.html (checked 2026-11-12)
- Local help: checked with aws-cli (`aws guardduty list-findings help`).

### AWS-15 Read GuardDuty findings

- Purpose: read the full detail of findings by ID. Phase: triage.
- Label: READ-ONLY, SENSITIVE
- Permission: `guardduty:GetFindings`
- Command:

  ```bash
  aws guardduty get-findings \
    --detector-id <detector-id> \
    --finding-ids <finding-id> <second-finding-id> \
    --profile <profile> --region <region> --no-cli-pager
  ```

- Output: findings with `Type`, `Severity`, `Resource`, and `Service.Action` details. Look for: the remote IP address, the API name, the caller type, and the first and last event times.
- Approval: ask the human first.
- Doc: https://docs.aws.amazon.com/guardduty/latest/APIReference/API_GetFindings.html (checked 2026-11-12)
- Local help: checked with aws-cli (`aws guardduty get-findings help`).

### AWS-16 Read Security Hub findings

- Purpose: list active critical findings for one resource. Phase: detection.
- Label: READ-ONLY, SENSITIVE
- Permission: `securityhub:GetFindings`
- Command:

  ```bash
  aws securityhub get-findings \
    --filters '{"RecordState":[{"Value":"ACTIVE","Comparison":"EQUALS"}],"SeverityLabel":[{"Value":"CRITICAL","Comparison":"EQUALS"}],"ResourceId":[{"Value":"<resource-id>","Comparison":"EQUALS"}]}' \
    --query 'Findings[].[Id,Title,Severity.Label,Resources[0].Id,UpdatedAt]' \
    --profile <profile> --region <region> --no-cli-pager
  ```

- Output: one row per finding with ID, title, severity, resource, and update time. Look for: findings on the affected resource and findings from several products at the same time. The output can be large. By default, the CLI retrieves all available items. With JSON output, the CLI runs `--query` once on the whole result.
- Approval: ask the human first.
- Doc: https://docs.aws.amazon.com/securityhub/1.0/APIReference/API_AwsSecurityFindingFilters.html, https://docs.aws.amazon.com/cli/latest/userguide/cli-usage-pagination.html, and https://docs.aws.amazon.com/cli/latest/userguide/cli-usage-filter.html (checked 2026-11-12)
- Local help: checked with aws-cli (`aws securityhub get-findings help`). The help says "get-findings is a paginated operation. Multiple API calls may be issued in order to retrieve the entire data set of results." `--max-items` is the only cap, so the command has none now. Remove a filter key to widen the search. `WorkflowStatus` is another valid key.

### AWS-17 List IAM Access Analyzer analyzers

- Purpose: find the analyzer ARN for the Region. Phase: scoping.
- Label: READ-ONLY, SENSITIVE
- Permission: `access-analyzer:ListAnalyzers`
- Command:

  ```bash
  aws accessanalyzer list-analyzers \
    --query 'analyzers[].[name,arn,type,status]' \
    --profile <profile> --region <region> --no-cli-pager
  ```

- Output: analyzer name, ARN, type, and status. Look for: no analyzer, a status other than `ACTIVE`, and the analyzer types that you have (external, internal, unused).
- Approval: ask the human first.
- Doc: https://docs.aws.amazon.com/access-analyzer/latest/APIReference/API_ListAnalyzers.html (checked 2026-11-12)
- Local help: checked with aws-cli (`aws accessanalyzer list-analyzers help`).

### AWS-18 List IAM Access Analyzer findings

- Purpose: list active findings about resources shared outside the zone of trust. Phase: scoping.
- Label: READ-ONLY, SENSITIVE
- Permission: `access-analyzer:ListFindings`
- Command:

  ```bash
  aws accessanalyzer list-findings-v2 \
    --analyzer-arn <analyzer-arn> \
    --filter '{"status":{"eq":["ACTIVE"]}}' \
    --profile <profile> --region <region> --no-cli-pager
  ```

- Output: findings with `resource`, `resourceType`, `findingType`, `status`, and `resourceOwnerAccount`. Look for: new findings for S3 buckets, IAM roles, KMS keys, and snapshots near the incident time.
- Approval: ask the human first.
- Doc: https://docs.aws.amazon.com/access-analyzer/latest/APIReference/API_ListFindingsV2.html (checked 2026-11-12)
- Local help: checked with aws-cli (`aws accessanalyzer list-findings-v2 help`). The docs say `list-findings` works only for external access analyzers. Use `list-findings-v2` for all analyzer types. Both calls need the IAM action `access-analyzer:ListFindings`.

## IAM credentials and roles

### AWS-19 Read the stored IAM credential report

- Purpose: read the credential report and decode it to CSV. Phase: scoping.
- Label: READ-ONLY, SENSITIVE
- Permission: `iam:GetCredentialReport`
- Command:

  ```bash
  f="<evidence-dir>/AWS-19-credential-report-$(date -u +%Y%m%dT%H%M%SZ)"
  aws iam get-credential-report --output json \
    --profile <profile> --region <region> --no-cli-pager > "$f.json" \
    && jq -er '.GeneratedTime' "$f.json" \
    && (set -o pipefail; jq -er '.Content' "$f.json" | base64 --decode > "$f.csv")
  ```

- Output: the `GeneratedTime` of the report, and a CSV file with one row per user. The JSON file keeps the full response. Record `GeneratedTime` in the notes. IAM returns a stored report. A new request within four hours of the last report gets the same report. The report shows nothing after `GeneratedTime`. For current state, use AWS-21 and AWS-22. Otherwise, record the time from `GeneratedTime` to now as a gap. A non-zero exit status, any error message, or an empty file means that the report is missing or incomplete. Do not use that file. Tell the human. Run AWS-20, then run AWS-19 again. Each run writes a new file name. Look for: `password_last_used`, `mfa_active` set to `false`, `access_key_1_active` or `access_key_2_active` set to `true`, and recent `access_key_*_last_used_date` values.
- Approval: ask the human first.
- Doc: https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_getting-report.html and https://docs.aws.amazon.com/IAM/latest/APIReference/API_GetCredentialReport.html (checked 2026-11-12)
- Local help: checked with aws-cli (`aws iam get-credential-report help`, fields `Content`, `ReportFormat`, `GeneratedTime`). The `Content` field is Base64. An error `ReportNotPresent` means no report exists. The report lists only the first two access keys per user. Use AWS-22 for all keys.

### AWS-20 Generate a new IAM credential report

- Purpose: make a current credential report for AWS-19. Phase: scoping.
- Label: WRITE
- Permission: `iam:GenerateCredentialReport`
- Command:

  ```bash
  aws iam generate-credential-report \
    --profile <profile> --region <region> --no-cli-pager
  ```

- Output: `State` as `STARTED` or `COMPLETE`. Look for: `COMPLETE`. Run AWS-19 when the state is `COMPLETE`. Compare the new `GeneratedTime` with the one from the earlier AWS-19 run. The same value means that IAM kept the old report. In that case, use AWS-21 and AWS-22 for current state, or record the gap.
- Side effect: AWS stores one report per account. A new report replaces the old one. IAM reuses a report that is less than four hours old.
- Rollback: None. The old report is gone. Run AWS-19 first. Save the old report to the case folder.
- Approval: human approval required.
- Doc: https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_getting-report.html (checked 2026-11-12)
- Local help: checked with aws-cli (`aws iam generate-credential-report help`).

### AWS-21 Check when an access key was last used

- Purpose: read the last use of one access key. Phase: triage.
- Label: READ-ONLY, SENSITIVE
- Permission: `iam:GetAccessKeyLastUsed`
- Command:

  ```bash
  aws iam get-access-key-last-used \
    --access-key-id <access-key-id> \
    --profile <profile> --region <region> --no-cli-pager
  ```

- Output: `UserName` and `AccessKeyLastUsed` with `LastUsedDate`, `ServiceName`, and `Region`. Look for: a use after the suspected leak time, and an unexpected service or Region. When IAM has no sign-in data for the key, `ServiceName` and `Region` show `N/A`, and `LastUsedDate` is null.
- Approval: ask the human first.
- Doc: https://docs.aws.amazon.com/IAM/latest/APIReference/API_GetAccessKeyLastUsed.html (checked 2026-11-12)
- Local help: checked with aws-cli (`aws iam get-access-key-last-used help`). IAM records only the first use in each 15-minute span. The report page states this for the credential report.

### AWS-22 List the access keys of an IAM user

- Purpose: list all keys of one user with their status. Phase: scoping.
- Label: READ-ONLY, SENSITIVE
- Permission: `iam:ListAccessKeys`
- Command:

  ```bash
  aws iam list-access-keys \
    --user-name <user-name> \
    --profile <profile> --region <region> --no-cli-pager
  ```

- Output: each key with `AccessKeyId`, `Status`, and `CreateDate`. Look for: an unknown key, a key created near the incident time, and an `Active` key that the owner does not use.
- Approval: ask the human first.
- Doc: https://docs.aws.amazon.com/IAM/latest/APIReference/API_ListAccessKeys.html (checked 2026-11-12)
- Local help: checked with aws-cli (`aws iam list-access-keys help`). Run AWS-21 for each key ID.

### AWS-23 Read the trust policy of an IAM role

- Purpose: read who can assume one role. Phase: scoping.
- Label: READ-ONLY, SENSITIVE
- Permission: `iam:GetRole`
- Command:

  ```bash
  aws iam get-role \
    --role-name <role-name> \
    --query 'Role.{Arn:Arn,CreateDate:CreateDate,TrustPolicy:AssumeRolePolicyDocument,LastUsed:RoleLastUsed}' \
    --profile <profile> --region <region> --no-cli-pager
  ```

- Output: the role ARN, the trust policy, and the last use. Look for: a `Principal` from an unknown account, `"AWS": "*"`, a missing `Condition` such as `sts:ExternalId`, and a recent `LastUsed` date.
- Approval: ask the human first.
- Doc: https://docs.aws.amazon.com/IAM/latest/APIReference/API_GetRole.html (checked 2026-11-12)
- Local help: checked with aws-cli (`aws iam get-role help`). The API returns the policy URL-encoded. The AWS CLI shows it as JSON.

### AWS-24 Search role trust policies for a principal

- Purpose: find every role whose trust policy names a given principal. Phase: scoping.
- Label: READ-ONLY, SENSITIVE
- Permission: `iam:ListRoles`
- Command:

  ```bash
  aws iam list-roles \
    --query 'Roles[?contains(to_string(AssumeRolePolicyDocument), `"<principal-fragment>"`)].[RoleName,Arn,CreateDate]' \
    --profile <profile> --region <region> --no-cli-pager
  ```

- Output: role name, ARN, and creation date for each match. Set `<principal-fragment>` to an account ID, a role ARN part, or a user ARN part. Look for: roles that trust an account you do not know, and roles made near the incident time.
- Approval: ask the human first.
- Doc: https://docs.aws.amazon.com/IAM/latest/APIReference/API_ListRoles.html (checked 2026-11-12)
- Local help: checked with aws-cli (`aws iam list-roles help`). The `--query` filter runs on the client after the CLI reads all pages.

### AWS-25 List the inline policies of an IAM role

- Purpose: check for an inline policy name clash before AWS-51. Phase: containment.
- Label: READ-ONLY, SENSITIVE
- Permission: `iam:ListRolePolicies`
- Command:

  ```bash
  aws iam list-role-policies \
    --role-name <role-name> \
    --profile <profile> --region <region> --no-cli-pager
  ```

- Output: `PolicyNames`. Look for: the names that exist. AWS-51 needs a name that this list does not show. An existing `AWSRevokeOlderSessions` policy from an earlier revocation stays in place. An inline policy that you do not know can be the work of an attacker. Save one policy with the command below:

  ```bash
  aws iam get-role-policy \
    --role-name <role-name> \
    --policy-name <policy-name> \
    --query PolicyDocument --output json \
    --profile <profile> --region <region> --no-cli-pager > '<policy-file>'
  ```

  This second command is also READ-ONLY, SENSITIVE. It needs `iam:GetRolePolicy`. Ask the human first. Use a `<policy-file>` path that does not exist yet, because the `>` redirect replaces an existing file.

- Approval: ask the human first.
- Doc: https://docs.aws.amazon.com/IAM/latest/APIReference/API_ListRolePolicies.html (checked 2026-11-12)
- Local help: checked with aws-cli (`aws iam list-role-policies help`, `aws iam get-role-policy help`). The help says the API returns the policy URL-encoded. The CLI example output shows a decoded JSON object.

## Cognito user pools

### AWS-26 Check the Cognito self sign-up setting

- Purpose: read whether users can create their own accounts. Phase: triage.
- Label: READ-ONLY, SENSITIVE
- Permission: `cognito-idp:DescribeUserPool`
- Command:

  ```bash
  aws cognito-idp describe-user-pool \
    --user-pool-id <user-pool-id> \
    --query 'UserPool.{Id:Id,Name:Name,AllowAdminCreateUserOnly:AdminCreateUserConfig.AllowAdminCreateUserOnly,MfaConfiguration:MfaConfiguration,DeletionProtection:DeletionProtection}' \
    --profile <profile> --region <region> --no-cli-pager
  ```

- Output: pool ID, name, `AllowAdminCreateUserOnly`, `MfaConfiguration`, and `DeletionProtection`. Look for: `AllowAdminCreateUserOnly` set to `false`. In that case, anyone can create a profile with the `SignUp` operation. Also look for `MfaConfiguration` set to `OFF`.
- Approval: ask the human first.
- Doc: https://docs.aws.amazon.com/cognito-user-identity-pools/latest/APIReference/API_DescribeUserPool.html (checked 2026-11-12)
- Local help: checked with aws-cli (`aws cognito-idp describe-user-pool help`). The help states that `true` means only administrators create new user profiles.

### AWS-27 Save the full Cognito user pool configuration

- Purpose: keep the current pool settings for AWS-57 and for rollback. Phase: evidence.
- Label: READ-ONLY, SENSITIVE
- Permission: `cognito-idp:DescribeUserPool`
- Command:

  ```bash
  aws cognito-idp describe-user-pool \
    --user-pool-id <user-pool-id> \
    --profile <profile> --region <region> --no-cli-pager \
    > "<evidence-dir>/AWS-27-user-pool-<stage>-$(date -u +%Y%m%dT%H%M%SZ).json"
  ```

- Output: a JSON file with all pool settings. Set `<stage>` to `original` before AWS-57, `after-change` after AWS-57, and `before-rollback` before its rollback. Look for: lambda triggers, email and SMS settings, password policy, and `AdminCreateUserConfig`. Keep this file unchanged. Make a copy for AWS-57.
- Approval: ask the human first.
- Doc: https://docs.aws.amazon.com/cognito-user-identity-pools/latest/APIReference/API_DescribeUserPool.html (checked 2026-11-12)
- Local help: checked with aws-cli (`aws cognito-idp describe-user-pool help`).

### AWS-28 List Cognito app clients

- Purpose: list the app clients of one pool. Phase: scoping.
- Label: READ-ONLY, SENSITIVE
- Permission: `cognito-idp:ListUserPoolClients`
- Command:

  ```bash
  aws cognito-idp list-user-pool-clients \
    --user-pool-id <user-pool-id> \
    --query 'UserPoolClients[].[ClientId,ClientName]' \
    --profile <profile> --region <region> --no-cli-pager
  ```

- Output: client ID and name for each app client. Look for: a client that the team does not know, and clients made near the incident time.
- Approval: ask the human first.
- Doc: https://docs.aws.amazon.com/cognito-user-identity-pools/latest/APIReference/API_ListUserPoolClients.html (checked 2026-11-12)
- Local help: checked with aws-cli (`aws cognito-idp list-user-pool-clients help`).

### AWS-29 List Cognito users by status

- Purpose: list users that have a given status. Phase: scoping.
- Label: READ-ONLY, SENSITIVE
- Permission: `cognito-idp:ListUsers`
- Command:

  ```bash
  aws cognito-idp list-users \
    --user-pool-id <user-pool-id> \
    --filter 'cognito:user_status = "UNCONFIRMED"' \
    --query 'Users[].[Username,UserStatus,Enabled,UserCreateDate]' \
    --profile <profile> --region <region> --no-cli-pager
  ```

- Output: user name, status, enabled flag, and creation date. The output holds personal data. Look for: many `UNCONFIRMED` users created in a short time, and user names that follow a pattern.
- Approval: ask the human first.
- Doc: https://docs.aws.amazon.com/cognito-user-identity-pools/latest/APIReference/API_ListUsers.html (checked 2026-11-12)
- Local help: checked with aws-cli (`aws cognito-idp list-users help`). The server filter accepts one attribute. The attributes are `username`, `email`, `phone_number`, `name`, `given_name`, `family_name`, `preferred_username`, `cognito:user_status`, `status`, and `sub`. An empty page can appear before a page with results.

## S3 logging and public access

### AWS-30 Check S3 server access logging for a bucket

- Purpose: check whether a bucket writes server access logs and where. Phase: scoping.
- Label: READ-ONLY, SENSITIVE
- Permission: `s3:GetBucketLogging`, and `logs:DescribeDeliverySources` for the second command
- Command:

  ```bash
  aws s3api get-bucket-logging \
    --bucket <bucket-name> \
    --profile <profile> --region <region> --no-cli-pager
  ```

- Output: `LoggingEnabled` with `TargetBucket` and `TargetPrefix`. This shows only the legacy delivery to an S3 bucket. Empty output means that the legacy delivery is off. Look for: a target bucket that someone else can write to or read. A bucket can also send server access logs through CloudWatch Logs delivery. `get-bucket-logging` does not show that delivery. Check it with the command below, in the Region of the bucket. It is READ-ONLY, SENSITIVE. Ask the human first.

  ```bash
  aws logs describe-delivery-sources \
    --query 'deliverySources[?logType==`"S3_SERVER_ACCESS_LOGS"`].[name,resourceArns,logType]' \
    --profile <profile> --region <region> --no-cli-pager
  ```

  Look for `arn:aws:s3:::<bucket-name>` in `resourceArns`. Then use AWS-44 with that source name to find the destinations. Record logging as off only when both checks show no delivery. Logs from an earlier time when logging was on can still exist.

- Approval: ask the human first.
- Doc: https://docs.aws.amazon.com/AmazonS3/latest/userguide/enable-server-access-logging.html, https://docs.aws.amazon.com/AmazonS3/latest/userguide/sal-cw-enabling.html, and https://docs.aws.amazon.com/AmazonCloudWatchLogs/latest/APIReference/API_PutDeliverySource.html (checked 2026-11-12)
- Local help: checked with aws-cli (`aws s3api get-bucket-logging help`, `aws logs describe-delivery-sources help`). The Doc says delivery of logs can take a few hours. It also says logging is off by default.

### AWS-31 Check the public access block of a bucket

- Purpose: read the four public access block settings of one bucket. Phase: triage.
- Label: READ-ONLY, SENSITIVE
- Permission: `s3:GetBucketPublicAccessBlock`
- Command:

  ```bash
  aws s3api get-public-access-block \
    --bucket <bucket-name> \
    --expected-bucket-owner <bucket-owner-account-id> \
    --profile <profile> --region <region> --no-cli-pager
  ```

- Output: `BlockPublicAcls`, `IgnorePublicAcls`, `BlockPublicPolicy`, and `RestrictPublicBuckets`. Set `<bucket-owner-account-id>` to the account ID that the human approved for the bucket. When another account owns the bucket, the call fails with `403 Forbidden` (local help). Then stop and tell the human. Look for: any value `false`. An error that says no configuration exists may mean the bucket has no block. This call shows the bucket setting only. Run AWS-34 for the account setting. Save the output before AWS-61. The AWS-61 rollback needs it.
- Approval: ask the human first.
- Doc: https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetPublicAccessBlock.html (checked 2026-11-12)
- Local help: checked with aws-cli (`aws s3api get-public-access-block help`). The Doc page states that S3 uses the most restrictive mix of the bucket and account settings. The page does not name the error for a bucket with no block.

### AWS-32 Check whether a bucket policy makes the bucket public

- Purpose: read the public status of one bucket from its policy. Phase: triage.
- Label: READ-ONLY, SENSITIVE
- Permission: `s3:GetBucketPolicyStatus`
- Command:

  ```bash
  aws s3api get-bucket-policy-status \
    --bucket <bucket-name> \
    --profile <profile> --region <region> --no-cli-pager
  ```

- Output: `PolicyStatus.IsPublic`. Look for: `true`. It means S3 treats the bucket as public.
- Approval: ask the human first.
- Doc: https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetBucketPolicyStatus.html (checked 2026-11-12)
- Local help: checked with aws-cli (`aws s3api get-bucket-policy-status help`). The docs do not support directory buckets for this call.

### AWS-33 Read the ACL of a bucket

- Purpose: read who holds ACL grants on one bucket. Phase: triage.
- Label: READ-ONLY, SENSITIVE
- Permission: `s3:GetBucketAcl`
- Command:

  ```bash
  aws s3api get-bucket-acl \
    --bucket <bucket-name> \
    --profile <profile> --region <region> --no-cli-pager
  ```

- Output: `Owner` and `Grants`. Look for: a grantee with a `URI` that ends in `AllUsers` or `AuthenticatedUsers`, and a `WRITE` or `FULL_CONTROL` permission for an unknown account.
- Approval: ask the human first.
- Doc: https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetBucketAcl.html (checked 2026-11-12)
- Local help: checked with aws-cli (`aws s3api get-bucket-acl help`). The Doc page states that the call needs `READ_ACP` access to the bucket. For a bucket with the bucket owner enforced setting, the call returns the `bucket-owner-full-control` ACL. Directory buckets do not support this call.

### AWS-34 Check the public access block of the account

- Purpose: read the account-wide public access block settings. Phase: triage.
- Label: READ-ONLY, SENSITIVE
- Permission: `s3:GetAccountPublicAccessBlock`
- Command:

  ```bash
  aws s3control get-public-access-block \
    --account-id <account-id> \
    --profile <profile> --region <region> --no-cli-pager
  ```

- Output: the four block settings for the account. Look for: any value `false`, and the error `NoSuchPublicAccessBlockConfiguration`. The Doc page states that the result is the effective account setting and can inherit from organization policies.
- Approval: ask the human first.
- Doc: https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_GetPublicAccessBlock.html (checked 2026-11-12)
- Local help: checked with aws-cli (`aws s3control get-public-access-block help`).

## Network logs and exposure

### AWS-35 Find VPC flow logs for a resource

- Purpose: check whether flow logs exist for a VPC, subnet, or network interface and where they go. Phase: scoping.
- Label: READ-ONLY, SENSITIVE
- Permission: `ec2:DescribeFlowLogs`. The interface read needs `ec2:DescribeNetworkInterfaces`.
- Command: a flow log on a subnet or a VPC covers each network interface in it. For a network interface, first read its subnet and VPC. This read is READ-ONLY, SENSITIVE. Ask the human first.

  ```bash
  aws ec2 describe-network-interfaces \
    --network-interface-ids <network-interface-id> \
    --query 'NetworkInterfaces[].[NetworkInterfaceId,SubnetId,VpcId]' \
    --profile <profile> --region <region> --no-cli-pager
  ```

  Then search for flow logs on all three IDs. For a subnet, use the subnet ID and its VPC ID. For a VPC, use the VPC ID only.

  ```bash
  aws ec2 describe-flow-logs \
    --filter Name=resource-id,Values=<network-interface-id>,<subnet-id>,<vpc-id> \
    --query 'FlowLogs[].[FlowLogId,ResourceId,TrafficType,LogDestinationType,LogDestination,LogGroupName,FlowLogStatus,DeliverLogsStatus]' \
    --profile <profile> --region <region> --no-cli-pager
  ```

- Output: flow log ID, resource, traffic type, destination type, destination, and status. Look for: no rows for all three IDs, `TrafficType` set to `ACCEPT` only, and `DeliverLogsStatus` set to `FAILED`.
- Shared VPC: each account sees only some flow logs. A participant cannot describe flow logs on a shared subnet, or on interfaces that it does not own. The VPC owner cannot describe flow logs that a participant created. Ask the human to run this entry in the owner account and in each participant account that matters. Record each account that you cannot read as a coverage gap.
- Approval: ask the human first.
- Doc: https://docs.aws.amazon.com/athena/latest/ug/vpc-flow-logs.html, https://docs.aws.amazon.com/vpc/latest/userguide/flow-logs-basics.html, and https://docs.aws.amazon.com/vpc/latest/userguide/vpc-share-limitations.html (checked 2026-11-12)
- Local help: checked with aws-cli (`aws ec2 describe-flow-logs help`, `aws ec2 describe-network-interfaces help`). A destination in S3 can be queried with Athena. The Doc page explains how to make the table. A destination in CloudWatch Logs can be queried with AWS-36.

### AWS-36 Query VPC flow logs with Logs Insights

- Purpose: sum the traffic to and from one IP address in a flow log group. Phase: scoping.
- Label: READ-ONLY, SENSITIVE
- Permission: `logs:StartQuery`
- Command:

  ```bash
  aws logs start-query \
    --log-group-name <flow-log-group-name> \
    --start-time <start-time-epoch-seconds> \
    --end-time <end-time-epoch-seconds> \
    --query-string 'filter srcAddr = "<ip-address>" or dstAddr = "<ip-address>" | stats sum(bytes) as bytesTransferred by srcAddr, dstAddr, dstPort | sort bytesTransferred desc | limit 20' \
    --profile <profile> --region <region> --no-cli-pager
  ```

- Output: a `queryId`. Read the rows with AWS-37. Look for: large transfers to unknown external addresses, and unusual destination ports.
- Cost note: Logs Insights charges for the data scanned. Keep the time range short. Results stay in CloudWatch Logs.
- Approval: ask the human first.
- Doc: https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/CWL_QuerySyntax-examples.html (checked 2026-11-12)
- Local help: checked with aws-cli (`aws logs start-query help`). Times are epoch seconds. The fields `srcAddr`, `dstAddr`, `dstPort`, and `bytes` appear in the Doc examples.

### AWS-37 Read the results of a Logs Insights query

- Purpose: read the rows of a Logs Insights query. Phase: scoping.
- Label: READ-ONLY, SENSITIVE
- Permission: `logs:GetQueryResults`
- Command:

  ```bash
  aws logs get-query-results \
    --query-id <query-id> \
    --profile <profile> --region <region> --no-cli-pager
  ```

- Output: `status`, `results`, and `statistics`. Look for: `status` set to `Complete` before you read the rows.
- Approval: ask the human first.
- Doc: https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/CWL_QuerySyntax-examples.html (checked 2026-11-12)
- Local help: checked with aws-cli (`aws logs get-query-results help`).

### AWS-38 List load balancers

- Purpose: find the load balancer ARN for AWS-39 and AWS-40. Phase: scoping.
- Label: READ-ONLY, SENSITIVE
- Permission: `elasticloadbalancing:DescribeLoadBalancers`
- Command:

  ```bash
  aws elbv2 describe-load-balancers \
    --query 'LoadBalancers[].[LoadBalancerName,LoadBalancerArn,Scheme,Type,SecurityGroups]' \
    --profile <profile> --region <region> --no-cli-pager
  ```

- Output: name, ARN, scheme, type, and security groups. Look for: `internet-facing` load balancers and security groups that allow the internet (see AWS-45).
- Approval: ask the human first.
- Doc: https://docs.aws.amazon.com/elasticloadbalancing/latest/APIReference/API_DescribeLoadBalancers.html (checked 2026-11-12)
- Local help: checked with aws-cli (`aws elbv2 describe-load-balancers help`).

### AWS-39 Check ALB access log settings

- Purpose: check whether a load balancer writes access logs and where. Phase: scoping.
- Label: READ-ONLY, SENSITIVE
- Permission: `elasticloadbalancing:DescribeLoadBalancerAttributes`
- Command:

  ```bash
  aws elbv2 describe-load-balancer-attributes \
    --load-balancer-arn <load-balancer-arn> \
    --query 'Attributes[?starts_with(Key, `"access_logs.s3"`)]' \
    --profile <profile> --region <region> --no-cli-pager
  ```

- Output: the keys `access_logs.s3.enabled`, `access_logs.s3.bucket`, and `access_logs.s3.prefix` with their values. These keys show the current setting of the legacy S3 access logs only. Look for: `access_logs.s3.enabled` set to `false`. That value does not prove that no logs exist for the incident window:
  - Logs from an earlier time when logging was on stay in the bucket until someone deletes them. Ask the human to check the bucket for objects from the incident window.
  - A load balancer can also send access logs through CloudWatch Logs delivery, to CloudWatch Logs, Firehose, or S3. Check that with the command below, in the Region of the load balancer. It is READ-ONLY, SENSITIVE. Ask the human first. It needs `logs:DescribeDeliverySources`. Look for the load balancer ARN in `resourceArns`. Then use AWS-44 with that source name to find the destinations.

  ```bash
  aws logs describe-delivery-sources \
    --query 'deliverySources[?logType==`"ALB_ACCESS_LOGS"`].[name,service,logType,resourceArns]' \
    --profile <profile> --region <region> --no-cli-pager
  ```

- Approval: ask the human first.
- Doc: https://docs.aws.amazon.com/elasticloadbalancing/latest/application/enable-access-logging.html, https://docs.aws.amazon.com/elasticloadbalancing/latest/application/disable-access-logging.html, https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-cloudwatch-logs.html, and https://docs.aws.amazon.com/AmazonCloudWatchLogs/latest/APIReference/API_PutDeliverySource.html (checked 2026-11-12). The access log type is `ALB_ACCESS_LOGS`.
- Local help: checked with aws-cli (`aws elbv2 describe-load-balancer-attributes help`, `aws logs describe-delivery-sources help`). The logs go to the S3 path `<prefix>/AWSLogs/<account-id>/`.

### AWS-40 List ALB listeners

- Purpose: list the ports, protocols, and default actions of a load balancer. Phase: scoping.
- Label: READ-ONLY, SENSITIVE
- Permission: `elasticloadbalancing:DescribeListeners`
- Command:

  ```bash
  aws elbv2 describe-listeners \
    --load-balancer-arn <load-balancer-arn> \
    --profile <profile> --region <region> --no-cli-pager
  ```

- Output: each listener with `ListenerArn`, `Port`, `Protocol`, `DefaultActions`, and certificates. Look for: a plain `HTTP` listener that forwards without a redirect, and a default action that sends traffic to an unknown target group.
- Approval: ask the human first.
- Doc: https://docs.aws.amazon.com/elasticloadbalancing/latest/APIReference/API_DescribeListeners.html (checked 2026-11-12)
- Local help: checked with aws-cli (`aws elbv2 describe-listeners help`).

### AWS-41 List ALB listener rules

- Purpose: list the routing rules of one listener. Phase: scoping.
- Label: READ-ONLY, SENSITIVE
- Permission: `elasticloadbalancing:DescribeRules`
- Command:

  ```bash
  aws elbv2 describe-rules \
    --listener-arn <listener-arn> \
    --profile <profile> --region <region> --no-cli-pager
  ```

- Output: each rule with `Priority`, `Conditions`, and `Actions`. The output includes the default rule, which has `IsDefault` set to `true`. Look for: a rule that you do not know, or a rule that forwards a path to an unknown target group. Also look for a `fixed-response` or `redirect` action that someone added. A header condition can hold a shared secret value, for example an origin check header. When one appears, follow safety rule 15 in `../SKILL.md`.
- Approval: ask the human first.
- Doc: https://docs.aws.amazon.com/elasticloadbalancing/latest/APIReference/API_DescribeRules.html (checked 2026-11-12)
- Local help: checked with aws-cli (`aws elbv2 describe-rules help`).

### AWS-42 Read CloudFront distribution logging settings

- Purpose: read the legacy logging block and the origins of one distribution. Phase: scoping.
- Label: READ-ONLY, SENSITIVE
- Permission: `cloudfront:GetDistributionConfig`
- Command:

  ```bash
  aws cloudfront get-distribution-config \
    --id <distribution-id> \
    --query 'DistributionConfig.{Enabled:Enabled,Aliases:Aliases.Items,Origins:Origins.Items[].DomainName,WebACLId:WebACLId,Logging:Logging}' \
    --profile <profile> --region <region> --no-cli-pager
  ```

- Output: the `Logging` block with `Enabled`, `IncludeCookies`, `Bucket`, and `Prefix`. Look for: `Logging.Enabled` set to `false`, an empty `WebACLId`, and an origin that you do not know.
- Approval: ask the human first.
- Doc: https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/standard-logging.html (checked 2026-11-12)
- Local help: checked with aws-cli (`aws cloudfront get-distribution-config help`). Standard logging (v2) does not appear in this block. The Doc says v2 uses CloudWatch vended log delivery. Use AWS-43 and AWS-44 to check it.

### AWS-43 List CloudFront standard logging v2 delivery sources

- Purpose: find which distributions send standard logging (v2) logs. Phase: scoping.
- Label: READ-ONLY, SENSITIVE
- Permission: `logs:DescribeDeliverySources`
- Command:

  ```bash
  aws logs describe-delivery-sources \
    --query 'deliverySources[?service==`"cloudfront"` && logType==`"ACCESS_LOGS"`].[name,resourceArns[0],logType]' \
    --profile <profile> --region <region> --no-cli-pager
  ```

- Output: the delivery source name, the distribution ARN, and the log type. Look for: a distribution that you expect but do not see. Run the command in `us-east-1`. The Doc says to use the CloudWatch API in `us-east-1` for CloudFront standard logging. The only log type for CloudFront is `ACCESS_LOGS`. Use each source name with AWS-44.
- Approval: ask the human first.
- Doc: https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/standard-logging.html and https://docs.aws.amazon.com/AmazonCloudWatchLogs/latest/APIReference/API_PutDeliverySource.html (checked 2026-11-12)
- Local help: checked with aws-cli (`aws logs describe-delivery-sources help`).

### AWS-44 List CloudFront standard logging v2 deliveries

- Purpose: find where a delivery source sends the logs. The source can come from AWS-30, AWS-39, or AWS-43. Phase: scoping.
- Label: READ-ONLY, SENSITIVE
- Permission: `logs:DescribeDeliveries`
- Command:

  ```bash
  aws logs describe-deliveries \
    --query 'deliveries[].[id,deliverySourceName,deliveryDestinationType,deliveryDestinationArn]' \
    --profile <profile> --region <region> --no-cli-pager
  ```

- Output: delivery ID, source name, destination type (S3, CloudWatch Logs, or Firehose), and the ARN of the delivery destination. Run the command in the Region of the delivery source. That is `us-east-1` for CloudFront, and the Region of the bucket or load balancer for AWS-30 and AWS-39. Keep only the deliveries whose `deliverySourceName` matches a source name from that entry. No match means that the source has no delivery. The ARN of the delivery destination names a logical object, not the bucket or log group. To find the resource that receives the logs, run this second command. It needs `logs:DescribeDeliveryDestinations`. Ask the human first.

  ```bash
  aws logs describe-delivery-destinations \
    --query 'deliveryDestinations[].[name,arn,deliveryDestinationType,deliveryDestinationConfiguration.destinationResourceArn]' \
    --profile <profile> --region <region> --no-cli-pager
  ```

  Run the second command in the Region that the `deliveryDestinationArn` names. Match each `deliveryDestinationArn` to an `arn`. The last field is the bucket, log group, or delivery stream. The second command lists only the destinations in this account and Region. Compare the account ID in each `deliveryDestinationArn` with the ID of this account. When it differs, the destination is in another account. Ask the human for read access to that account, or record the destination as unresolved. Look for: a receiving resource in an unknown account. Ask the human to confirm who owns each S3 bucket.

- Approval: ask the human first.
- Doc: https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/standard-logging.html and https://docs.aws.amazon.com/AmazonCloudWatchLogs/latest/APIReference/API_DeliveryDestination.html (checked 2026-11-12)
- Local help: checked with aws-cli (`aws logs describe-deliveries help`, `aws logs describe-delivery-destinations help`, fields `deliveryDestinations` and `deliveryDestinationConfiguration.destinationResourceArn`).

### AWS-45 Find security groups that allow inbound traffic from the internet

- Purpose: list security groups with an inbound rule open to the whole internet. Phase: scoping.
- Label: READ-ONLY, SENSITIVE
- Permission: `ec2:DescribeSecurityGroups`
- Command:

  ```bash
  aws ec2 describe-security-groups \
    --filters Name=ip-permission.cidr,Values='0.0.0.0/0' \
    --query 'SecurityGroups[].[GroupId,GroupName,VpcId]' \
    --profile <profile> --region <region> --no-cli-pager
  ```

  The same check for IPv6:

  ```bash
  aws ec2 describe-security-groups \
    --filters Name=ip-permission.ipv6-cidr,Values='::/0' \
    --query 'SecurityGroups[].[GroupId,GroupName,VpcId]' \
    --profile <profile> --region <region> --no-cli-pager
  ```

- Output: group ID, name, and VPC. Look for: groups on instances or load balancers that should not receive public traffic. Run both commands. A group can appear in both results. Add `Name=ip-permission.from-port,Values=<port-number>` to narrow the result to one port. With two rule filters, a group matches when any combination of its rules matches all filters. Run AWS-46 on each group to see the exact rule.
- Approval: ask the human first.
- Doc: https://docs.aws.amazon.com/AWSEC2/latest/APIReference/API_DescribeSecurityGroups.html (checked 2026-11-12)
- Local help: checked with aws-cli (`aws ec2 describe-security-groups help`). The help example uses the same filter name with the value `0.0.0.0/0`. The Doc page lists `ip-permission.cidr` as the IPv4 filter and `ip-permission.ipv6-cidr` as the IPv6 filter. The Doc page shows `::/0` as the IPv6 form of an open range.

### AWS-46 List inbound rules of a security group that allow the internet

- Purpose: list the open inbound rules of one security group. Phase: scoping.
- Label: READ-ONLY, SENSITIVE
- Permission: `ec2:DescribeSecurityGroupRules`
- Command:

  ```bash
  aws ec2 describe-security-group-rules \
    --filters Name=group-id,Values=<security-group-id> \
    --query 'SecurityGroupRules[?IsEgress==`false` && (CidrIpv4==`"0.0.0.0/0"` || CidrIpv6==`"::/0"`)].[SecurityGroupRuleId,IpProtocol,FromPort,ToPort,CidrIpv4,CidrIpv6,Description]' \
    --profile <profile> --region <region> --no-cli-pager
  ```

- Output: rule ID, protocol, port range, the open IPv4 or IPv6 range, and description. Look for: ports 22, 3389, and database ports, and a rule with no description.
- Approval: ask the human first.
- Doc: https://docs.aws.amazon.com/AWSEC2/latest/APIReference/API_DescribeSecurityGroupRules.html (checked 2026-11-12)
- Local help: checked with aws-cli (`aws ec2 describe-security-group-rules help`). The filter `group-id` is listed in the help. The help output lists the fields `IsEgress`, `CidrIpv4`, and `CidrIpv6`. The Doc page (SecurityGroupRule) lists the same fields in lower camel case, `cidrIpv4` and `cidrIpv6`. The AWS CLI prints them in Pascal case.

### AWS-47 Check the IMDSv2 setting of instances

- Purpose: list instances that still accept IMDSv1. Phase: scoping.
- Label: READ-ONLY, SENSITIVE
- Permission: `ec2:DescribeInstances`
- Command:

  ```bash
  aws ec2 describe-instances \
    --filters Name=metadata-options.http-tokens,Values=optional \
    --query 'Reservations[].Instances[].[InstanceId,MetadataOptions.HttpTokens,MetadataOptions.HttpEndpoint,MetadataOptions.HttpPutResponseHopLimit,State.Name]' \
    --profile <profile> --region <region> --no-cli-pager
  ```

- Output: instance ID, `HttpTokens`, `HttpEndpoint`, hop limit, and state. Look for: `HttpTokens` set to `optional` and `HttpEndpoint` set to `enabled`. IMDSv1 is then available. When `HttpEndpoint` is `disabled`, the instance serves no metadata. The help says the value `required` means IMDSv2 only.
- Approval: ask the human first.
- Doc: https://docs.aws.amazon.com/AWSEC2/latest/APIReference/API_DescribeInstances.html (checked 2026-11-12)
- Local help: checked with aws-cli (`aws ec2 describe-instances help`, `aws ec2 modify-instance-metadata-options help`). The Doc page lists the filter `metadata-options.http-tokens` with the values `optional` and `required`. Use AWS-53 to change one instance.

## Organizations policies

Run these commands with a profile for the management account or a delegated administrator account. Organizations accepts CLI calls in `us-east-1` from commercial Regions outside China, and in `cn-northwest-1` from China Regions. The commands use `us-east-1`. Use `cn-northwest-1` in China. For other partitions, check the Organizations CLI reference first. Doc: https://docs.aws.amazon.com/cli/latest/reference/organizations/ (checked 2026-11-12).

### AWS-48 List service control policies

- Purpose: list all service control policies (SCPs) in the organization. Phase: scoping.
- Label: READ-ONLY, SENSITIVE
- Permission: `organizations:ListPolicies`
- Command:

  ```bash
  aws organizations list-policies \
    --filter SERVICE_CONTROL_POLICY \
    --query 'Policies[].[Id,Name,AwsManaged]' \
    --profile <profile> --region us-east-1 --no-cli-pager
  ```

- Output: policy ID, name, and whether AWS manages it. Look for: a policy that an attacker could have added or changed, and no SCP other than `FullAWSAccess`.
- Approval: ask the human first.
- Doc: https://docs.aws.amazon.com/organizations/latest/APIReference/API_ListPolicies.html (checked 2026-11-12)
- Local help: checked with aws-cli (`aws organizations list-policies help`). The `--filter` option is required.

### AWS-49 Read a service control policy

- Purpose: read the content of one SCP. Phase: scoping.
- Label: READ-ONLY, SENSITIVE
- Permission: `organizations:DescribePolicy`
- Command:

  ```bash
  aws organizations describe-policy \
    --policy-id <policy-id> \
    --query 'Policy.{Summary:PolicySummary,Content:Content}' \
    --profile <profile> --region us-east-1 --no-cli-pager
  ```

- Output: the policy summary and the policy JSON as a string. Look for: a missing `Deny` for actions that you expect to be blocked, and a recent change.
- Approval: ask the human first.
- Doc: https://docs.aws.amazon.com/organizations/latest/APIReference/API_DescribePolicy.html (checked 2026-11-12)
- Local help: checked with aws-cli (`aws organizations describe-policy help`).

### AWS-50 List the targets of a service control policy

- Purpose: find the roots, organizational units, and accounts that one SCP is attached to. Phase: scoping.
- Label: READ-ONLY, SENSITIVE
- Permission: `organizations:ListTargetsForPolicy`. The parent read needs `organizations:ListParents`.
- Command:

  ```bash
  aws organizations list-targets-for-policy \
    --policy-id <policy-id> \
    --query 'Targets[].[TargetId,Name,Type]' \
    --profile <profile> --region us-east-1 --no-cli-pager
  ```

- Output: target ID, name, and type (`ROOT`, `ORGANIZATIONAL_UNIT`, or `ACCOUNT`). The list shows direct attachments only. An account also gets each SCP that is attached to its root or to an organizational unit above it. Look for: the affected account, or one of its parents, in the list. To find the parents, run this read for the account. Run it again for each parent ID until the type is `ROOT`. It is READ-ONLY, SENSITIVE. Ask the human before each read.

  ```bash
  aws organizations list-parents \
    --child-id <account-or-ou-id> \
    --query 'Parents[].[Id,Type]' \
    --profile <profile> --region us-east-1 --no-cli-pager
  ```

  This read finds attachments only. An SCP is attached to the account only when the account or one of its parents is in the target list. An attached SCP has no effect on users or roles in the management account. It also has no effect on any service-linked role. Check the account and the principal type before you treat the SCP as a limit on a principal.

- Approval: ask the human first.
- Doc: https://docs.aws.amazon.com/organizations/latest/APIReference/API_ListTargetsForPolicy.html, https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_scps_syntax.html, and https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_scps.html (checked 2026-11-12)
- Local help: checked with aws-cli (`aws organizations list-targets-for-policy help`, `aws organizations list-parents help`).

## Containment actions

Each command in this section changes state. A human approves each command, one at a time. Collect the rollback data first.

### AWS-51 Revoke all active sessions of an IAM role

- Purpose: deny all actions to every session of a role that started before a set time. Phase: containment.
- Label: WRITE
- Permission: `iam:PutRolePolicy`. The checks need `iam:ListRolePolicies` and `iam:GetRolePolicy`. The rollback needs `iam:DeleteRolePolicy`. Check all four before the change.
- Command:

  Check the local clock first, because the cutoff comes from it. A slow clock sets a cutoff in the past, and recent sessions keep access. This check is READ-ONLY. It sends one request without credentials to a public AWS endpoint.

  ```bash
  date -u '+%a, %d %b %Y %H:%M:%S GMT'
  curl -q -sS --noproxy '*' -o /dev/null -I --max-time 10 -w '%header{date}\n' https://sts.amazonaws.com/
  ```

  The two lines must match within 5 seconds. Record both. When they differ by more, or the first command fails, stop and tell the human. Do not run the change.

  Run AWS-25 first. Pick a `<revoke-policy-name>` that AWS-25 does not list, for example `IncidentRevokeSessions-20261112T031400Z`. A new name leaves every existing policy unchanged, including an earlier deny.

  ```bash
  aws iam put-role-policy \
    --role-name <role-name> \
    --policy-name <revoke-policy-name> \
    --policy-document "$(jq -cn '{Version:"2012-10-17",Statement:{Effect:"Deny",Action:"*",Resource:"*",Condition:{DateLessThan:{"aws:TokenIssueTime":(now + 30 | strftime("%Y-%m-%dT%H:%M:%SZ"))}}}}')" \
    --profile <profile> --region <region> --no-cli-pager
  ```

  The `jq` part builds the policy from the AWS documentation. When the command runs, it sets the cutoff time to the current UTC time plus 30 seconds. The console uses about 30 seconds too. A cutoff that you write before the approval can be in the past when the command runs. Then sessions that started after the cutoff keep access.

- Output: no output on success. Look for: an error. Then save the installed policy with the AWS-25 `get-role-policy` command and `<revoke-policy-name>`. Use a new `<after-change-file>`. Check that it holds the deny statement, and that its `aws:TokenIssueTime` is later than the AWS `date` value from the clock check.
- Side effect: every session of this role issued before the cutoff time loses all access. This includes responders and automation that use the role. Users can lose unsaved work. A principal that assumes the role after the cutoff time keeps access. The new policy increases the size of the inline policies of the role. When the call fails with a limit error, stop and tell the human. The command cannot revoke a service-linked role. IAM Identity Center permission set roles cannot be edited. Revoke those sessions in IAM Identity Center. The AWS CLI caches credentials. For a CLI user to get new credentials, delete the folder `~/.aws/cli/cache`.
- Rollback: follow safety rule 16 in `../SKILL.md` first. Delete only the policy that this run created. Other policies stay.
  1. Save the policy again with the AWS-25 `get-role-policy` command. Use a new `<before-rollback-file>`.
  2. Check both files. `jq -e . '<after-change-file>' '<before-rollback-file>'` must exit 0.
  3. Compare them. `diff <(jq -S . '<after-change-file>') <(jq -S . '<before-rollback-file>')` must print nothing. Otherwise, another person changed the policy. Stop and tell the human.
  4. Delete the policy:

  ```bash
  aws iam delete-role-policy \
    --role-name <role-name> \
    --policy-name <revoke-policy-name> \
    --profile <profile> --region <region> --no-cli-pager
  ```

  Old sessions, including attacker sessions, work again after the rollback, unless another deny policy still covers them. Run it only on a human decision.

- Approval: human approval required.
- Doc: https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use_revoke-sessions.html and https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_evaluation-logic.html (checked 2026-11-12). https://curl.se/docs/manpage.html (checked 2026-11-12) lists the `%header{name}` write-out variable.
- Local help: checked with aws-cli (`aws iam put-role-policy help`, `aws iam delete-role-policy help`). The help gives the name pattern `[\w+=,.@-]+`, with 128 characters at most. The `jq` part was tested with jq. The clock check was tested with curl against `https://sts.amazonaws.com/`. It printed a `date` header that matched `date -u` to the second.

### AWS-52 Deactivate an IAM access key

- Purpose: stop one access key from signing requests and keep the key for evidence. Phase: containment.
- Label: WRITE
- Permission: `iam:UpdateAccessKey`
- Command:

  ```bash
  aws iam update-access-key \
    --user-name <user-name> \
    --access-key-id <access-key-id> \
    --status Inactive \
    --profile <profile> --region <region> --no-cli-pager
  ```

- Output: no output on success. Look for: `Inactive` in AWS-22.
- Side effect: every application that uses this key fails at once. The key stays in the account. Temporary credentials that the key already created may stay valid until they expire. No AWS page that we checked states this. Treat it as unconfirmed. Use AWS-51 for a role.
- Rollback: follow safety rule 16 in `../SKILL.md` first. Run it only when AWS-22 showed the key as `Active` before the change. When the key was already `Inactive`, do nothing.

  ```bash
  aws iam update-access-key \
    --user-name <user-name> \
    --access-key-id <access-key-id> \
    --status Active \
    --profile <profile> --region <region> --no-cli-pager
  ```

- Approval: human approval required.
- Doc: https://docs.aws.amazon.com/IAM/latest/APIReference/API_UpdateAccessKey.html (checked 2026-11-12)
- Local help: checked with aws-cli (`aws iam update-access-key help`). Always pass `--user-name`. The help and the Doc page say the user name is otherwise taken from the key that signs the request. The Doc page says `--user-name` is required when you sign with temporary credentials.

### AWS-53 Require IMDSv2 on an instance

- Purpose: stop one instance from giving role credentials to IMDSv1 requests. Phase: containment.
- Label: WRITE
- Permission: `ec2:ModifyInstanceMetadataOptions`. The check before and after the change needs `ec2:DescribeInstances`. When the check is denied, stop and tell the human.
- Command:

  ```bash
  aws ec2 modify-instance-metadata-options \
    --instance-id <instance-id> \
    --http-tokens required \
    --http-endpoint enabled \
    --profile <profile> --region <region> --no-cli-pager
  ```

- Output: `InstanceMetadataOptions` with `State` set to `pending`, then `applied`. Check the instance with this command before and after the change. AWS-47 does not show the instance after the change, because its filter selects only `optional`.

  ```bash
  aws ec2 describe-instances \
    --instance-ids <instance-id> \
    --query 'Reservations[].Instances[].MetadataOptions.[HttpTokens,HttpEndpoint,State]' \
    --profile <profile> --region <region> --no-cli-pager
  ```

  This check is READ-ONLY, SENSITIVE. Ask the human first. Look for: `required`, `enabled`, and `applied` after the change.

- Side effect: software that reads metadata without a session token stops working. This can break old SDKs and agents. The Doc page says to check the CloudWatch metric `MetadataNoToken` for IMDSv1 calls first. The command also enables the metadata endpoint. Read `HttpEndpoint` with the check in Output first. If it is `disabled`, do not run AWS-53. The instance serves no metadata, and AWS-53 would make it available. Tell the human. The change may not cancel credentials that an attacker already took. No AWS page that we checked states this. Use AWS-51 on the instance role.
- Rollback: follow safety rule 16 in `../SKILL.md` first.

  ```bash
  aws ec2 modify-instance-metadata-options \
    --instance-id <instance-id> \
    --http-tokens <recorded-http-tokens> \
    --http-endpoint enabled \
    --profile <profile> --region <region> --no-cli-pager
  ```

  Use the `HttpTokens` value that the check above recorded before the change. AWS-53 runs only when `HttpEndpoint` was `enabled`, so the rollback keeps it `enabled`.

- Approval: human approval required.
- Doc: https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/configuring-IMDS-existing-instances.html and https://docs.aws.amazon.com/AWSEC2/latest/APIReference/API_ModifyInstanceMetadataOptions.html (checked 2026-11-12). The API page says: "If you specify a value of `disabled`, you cannot access your instance metadata."
- Local help: checked with aws-cli (`aws ec2 modify-instance-metadata-options help`). On a running instance the change shows as `pending` until applied. The Doc page says to set `--http-endpoint enabled` when you set `--http-tokens`. The page also says that a declarative policy can block a direct change in the account.

### AWS-54 Record the security groups of an instance

- Purpose: save the current security groups of each network interface before AWS-55. Phase: containment.
- Label: READ-ONLY, SENSITIVE
- Permission: `ec2:DescribeInstances`
- Command:

  ```bash
  aws ec2 describe-instances \
    --instance-ids <instance-id> \
    --query 'Reservations[].Instances[].{VpcId:VpcId,Interfaces:NetworkInterfaces[].{Interface:NetworkInterfaceId,DeviceIndex:Attachment.DeviceIndex,Groups:Groups[].GroupId}}' \
    --profile <profile> --region <region> --no-cli-pager
  ```

- Output: the `VpcId` of the instance, then each network interface with its security group IDs. AWS-55 needs the `VpcId`. Look for: more than one interface. AWS-55 then changes each interface separately. Save the output to the case folder.
- Approval: ask the human first.
- Doc: https://docs.aws.amazon.com/AWSEC2/latest/APIReference/API_DescribeInstances.html (checked 2026-11-12)
- Local help: checked with aws-cli (`aws ec2 describe-instances help`).

### AWS-55 Isolate an instance with a security group

- Purpose: replace the security groups of an instance with one group that blocks traffic. Phase: containment.
- Label: WRITE
- Permission: `ec2:ModifyInstanceAttribute`. The per-interface command needs `ec2:ModifyNetworkInterfaceAttribute`. The group check needs `ec2:DescribeSecurityGroups`. AWS-54 needs `ec2:DescribeInstances` and gives the VPC of the instance.
- Command: first check the isolation group. This read is READ-ONLY, SENSITIVE. Ask the human first.

  ```bash
  aws ec2 describe-security-groups \
    --group-ids <isolation-security-group-id> \
    --query 'SecurityGroups[].[GroupId,VpcId,IpPermissions,IpPermissionsEgress]' \
    --profile <profile> --region <region> --no-cli-pager
  ```

  Continue only when both rule lists are empty and the `VpcId` is the `VpcId` that AWS-54 saved. Otherwise, stop and tell the human. When AWS-54 shows exactly one interface, replace the groups with the instance command:

  ```bash
  aws ec2 modify-instance-attribute \
    --instance-id <instance-id> \
    --groups <isolation-security-group-id> \
    --profile <profile> --region <region> --no-cli-pager
  ```

- Output: no output on success. Then run AWS-54 again. Look for: each interface holds only the isolation group ID. Then run the group check again. Both rule lists must still be empty.
- Side effect: the instance loses all traffic that the old groups allowed. This includes the traffic of the service it runs. A human prepares `<isolation-security-group-id>` before this step. The group needs no inbound rules and no outbound rules. A new group allows all outbound traffic by default, so a human removes that rule. A security group does not immediately end the connections that it already tracks. They stay open until they time out. A connection that the group does not track ends at once. A network ACL on the subnet ends tracked connections. Security groups and network ACLs cannot block DNS requests to the Route 53 Resolver. The instance can still send DNS queries, which an attacker can use to move data out. The instance is therefore not fully isolated. A human decides on DNS containment, for example with Route 53 Resolver DNS Firewall. The instance command changes only the groups of the primary network interface. When AWS-54 shows more than one interface, do not use the instance command. Use the command below for each interface instead. It needs `ec2:ModifyNetworkInterfaceAttribute`. Ask the human to approve each interface as a separate WRITE command. The instance is isolated only after every interface holds only the isolation group.

  ```bash
  aws ec2 modify-network-interface-attribute \
    --network-interface-id <network-interface-id> \
    --groups <isolation-security-group-id> \
    --profile <profile> --region <region> --no-cli-pager
  ```

- Rollback: follow safety rule 16 in `../SKILL.md` first. Replace `<original-security-group-ids>` with the group IDs that AWS-54 saved for that one interface, separated by spaces. Do not mix the groups of different interfaces. The list can hold one ID or more. For the instance command, use the groups of the single interface:

  ```bash
  aws ec2 modify-instance-attribute \
    --instance-id <instance-id> \
    --groups <original-security-group-ids> \
    --profile <profile> --region <region> --no-cli-pager
  ```

  For the interface command, restore each interface to the list that AWS-54 saved for it. Run AWS-54 again after the rollback. Compare the groups of each interface with its saved list.

  ```bash
  aws ec2 modify-network-interface-attribute \
    --network-interface-id <network-interface-id> \
    --groups <original-security-group-ids> \
    --profile <profile> --region <region> --no-cli-pager
  ```

- Approval: human approval required.
- Doc: https://docs.aws.amazon.com/AWSEC2/latest/APIReference/API_ModifyInstanceAttribute.html and https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/changing-security-group.html (checked 2026-11-12). The guide says that a change of the instance groups changes the groups of the primary network interface.
- Local help: checked with aws-cli (`aws ec2 modify-instance-attribute help`, `aws ec2 modify-network-interface-attribute help`). Both help pages say that the `--groups` list replaces the current groups. https://docs.aws.amazon.com/AWSEC2/latest/APIReference/API_ModifyNetworkInterfaceAttribute.html (checked 2026-11-12) says the same for one interface. The help and the Doc page say `--groups` replaces the groups of the instance. It needs at least one group ID. The statements on tracked connections and on the default outbound rule come from https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/security-group-connection-tracking.html and https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/security-group-rules.html (both checked 2026-11-12). The DNS limit comes from https://docs.aws.amazon.com/vpc/latest/userguide/security-group-rules.html and https://docs.aws.amazon.com/vpc/latest/userguide/vpc-network-acls.html. DNS Firewall is described at https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/resolver-dns-firewall.html (all checked 2026-11-12).

### AWS-56 Snapshot an EBS volume for evidence

- Purpose: copy the data of one EBS volume to a tagged snapshot. Phase: evidence.
- Label: WRITE
- Permission: `ec2:CreateSnapshot`, `ec2:CreateTags`. The checks need `ec2:DescribeSnapshots` and `ec2:DescribeSnapshotAttribute`. The rollback needs `ec2:DeleteSnapshot`. Confirm with the human that the role has all five before the create.
- Command:

  ```bash
  aws ec2 create-snapshot \
    --volume-id <volume-id> \
    --description "<case-id> evidence snapshot" \
    --tag-specifications 'ResourceType=snapshot,Tags=[{Key=case,Value=<case-id>},{Key=purpose,Value=incident-evidence}]' \
    --profile <profile> --region <region> --no-cli-pager
  ```

- Output: `SnapshotId`, `State` set to `pending`, `Encrypted`, and `StartTime`. Look for: the `completed` state later. Check the state with this command. It is READ-ONLY, SENSITIVE. Ask the human first.

  ```bash
  aws ec2 describe-snapshots \
    --snapshot-ids <snapshot-id> \
    --query 'Snapshots[].[SnapshotId,State,Progress,VolumeId,Encrypted]' \
    --profile <profile> --region <region> --no-cli-pager
  ```

- Side effect: creates a snapshot that adds storage cost. The snapshot holds only data already written to the volume. Data in memory or in file system caches is not in it. For a root volume, the Doc page recommends stopping the instance first. A stop erases the data on instance store volumes. The Stop and start page names hibernation as the way to save the contents of memory. If you need it, capture memory before a stop. A snapshot of an encrypted volume is encrypted.
- Rollback: follow safety rule 16 in `../SKILL.md` first. Run these two reads first. Both are READ-ONLY, SENSITIVE. Ask the human before each read.

  ```bash
  aws ec2 describe-snapshots \
    --snapshot-ids <snapshot-id> \
    --query 'Snapshots[].[SnapshotId,State,VolumeId,Description,Tags]' \
    --profile <profile> --region <region> --no-cli-pager
  aws ec2 describe-snapshot-attribute \
    --snapshot-id <snapshot-id> \
    --attribute createVolumePermission \
    --profile <profile> --region <region> --no-cli-pager
  ```

  Continue only when all of these are true. Otherwise, another person can use the snapshot. Stop and tell the incident commander.
  - The description is `<case-id> evidence snapshot`.
  - The tags are exactly `case` = `<case-id>` and `purpose` = `incident-evidence`.
  - `CreateVolumePermissions` is empty, so the snapshot is not shared.
  - The state is `pending` or `completed`. A change from `pending` to `completed` is expected.

  ```bash
  aws ec2 delete-snapshot \
    --snapshot-id <snapshot-id> \
    --profile <profile> --region <region> --no-cli-pager
  ```

  This deletes the evidence copy. Run it only after the incident commander approves.

- Approval: human approval required.
- Doc: https://docs.aws.amazon.com/AWSEC2/latest/APIReference/API_CreateSnapshot.html (checked 2026-11-12)
- Local help: checked with aws-cli (`aws ec2 create-snapshot help`, `aws ec2 delete-snapshot help`, `aws ec2 describe-snapshot-attribute help`). The tag syntax comes from the help example. The statement on instance store data and hibernation comes from https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/Stop_Start.html (checked 2026-11-12).

### AWS-57 Disable Cognito self sign-up

- Purpose: allow only administrators to create user profiles in one pool. Phase: containment.
- Label: WRITE
- Permission: `cognito-idp:UpdateUserPool`. The AWS-27 checks need `cognito-idp:DescribeUserPool`.
- Command:

  ```bash
  aws cognito-idp update-user-pool \
    --cli-input-json file://<user-pool-update-file> \
    --profile <profile> --region <region> --no-cli-pager
  ```

  A human builds `<user-pool-update-file>` from the file that AWS-27 saved. The file holds `UserPoolId` and every setting that the pool uses today, in the input names of `update-user-pool`. Two names differ: `Name` in the output is `PoolName` in the input, and `Id` is `UserPoolId`. Set `AdminCreateUserConfig.AllowAdminCreateUserOnly` to `true`. The command `aws cognito-idp update-user-pool --generate-cli-skeleton` prints the accepted input names. It makes no API call.

- Output: no output on success. Look for: `AllowAdminCreateUserOnly` set to `true` in AWS-26. Run AWS-27 again with `<stage>` set to `after-change`. Compare it with the `original` file. Only `AllowAdminCreateUserOnly` and `LastModifiedDate` should differ. When another setting differs, tell the human.
- Side effect: users can no longer sign themselves up. The help states that `update-user-pool` sets each attribute that you omit to its default value. A missing setting can remove a trigger, an email setting, or the MFA setting. The help says that this action might generate an SMS text message. A sent message cannot be recalled, and the rollback cannot undo it. Name this in the approval request.
- Rollback: follow safety rule 16 in `../SKILL.md` first.

  ```bash
  aws cognito-idp update-user-pool \
    --cli-input-json file://<user-pool-original-file> \
    --profile <profile> --region <region> --no-cli-pager
  ```

  `<user-pool-original-file>` holds the same fields with the original values from AWS-27. Before the rollback, run AWS-27 again with `<stage>` set to `before-rollback`. Compare it with the `after-change` file:

  ```bash
  diff <(jq -S . '<after-change-file>') <(jq -S . '<before-rollback-file>')
  ```

  A `jq` error inside `<(...)` does not fail `diff`, so first check both files:

  ```bash
  jq -e '.UserPool.Id' '<after-change-file>' '<before-rollback-file>'
  ```

  Continue only when it prints the pool ID twice and exits 0. Run the rollback only when `diff` prints nothing. Any difference is a later change, such as a new MFA setting or trigger. A new `LastModifiedDate` alone also means a later change, even when the settings look the same. The rollback file would overwrite it. Then stop and tell the human.

- Approval: human approval required.
- Doc: https://docs.aws.amazon.com/cognito-user-identity-pools/latest/APIReference/API_UpdateUserPool.html (checked 2026-11-12)
- Local help: checked with aws-cli (`aws cognito-idp update-user-pool help`). The help also notes that this call can send an SMS message.

### AWS-61 Block public access on one bucket

- Purpose: stop public access to one S3 bucket through its ACLs and its bucket policy. Phase: containment.
- Label: WRITE
- Permission: `s3:PutBucketPublicAccessBlock`. The rollback with a delete needs the same permission. AWS-31 needs `s3:GetBucketPublicAccessBlock`.
- Command: run AWS-31 first. Continue only when AWS-31 returned the four values, or the error that says that no configuration exists. Save that output. Use the same `<bucket-owner-account-id>` as AWS-31 on every call in this entry. For any other error, such as access denied, stop and tell the human, because the rollback then cannot restore the old state.

  ```bash
  aws s3api put-public-access-block \
    --bucket <bucket-name> \
    --expected-bucket-owner <bucket-owner-account-id> \
    --public-access-block-configuration BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true \
    --profile <profile> --region <region> --no-cli-pager
  ```

- Output: no output on success. Look for: all four values `true` in AWS-31. Then check the exposure again from outside the account.
- Side effect: S3 ignores all public ACLs on the bucket and its objects. A public bucket policy then allows only AWS service principals and authorized users in the account. A reader without credentials loses access through ACLs and the bucket policy. This includes a website or an app that reads the bucket this way. Some access paths stay open. A presigned URL still works, because it uses the credentials of an authorized user. A CDN such as CloudFront that reads the bucket with its own access can still serve objects. Record these paths in the incident log. Check each path before you call the bucket contained. The stored ACLs and policy stay unchanged. No object is deleted or changed.
- Rollback: follow safety rule 16 in `../SKILL.md` first. When AWS-31 returned a configuration, put back its four saved values:

  ```bash
  aws s3api put-public-access-block \
    --bucket <bucket-name> \
    --expected-bucket-owner <bucket-owner-account-id> \
    --public-access-block-configuration BlockPublicAcls=<saved-value>,IgnorePublicAcls=<saved-value>,BlockPublicPolicy=<saved-value>,RestrictPublicBuckets=<saved-value> \
    --profile <profile> --region <region> --no-cli-pager
  ```

  When AWS-31 returned an error because no configuration existed, remove the configuration:

  ```bash
  aws s3api delete-public-access-block \
    --bucket <bucket-name> \
    --expected-bucket-owner <bucket-owner-account-id> \
    --profile <profile> --region <region> --no-cli-pager
  ```

  The data can be public again after the rollback. Run it only on a human decision.

- Approval: human approval required.
- Doc: https://docs.aws.amazon.com/AmazonS3/latest/API/API_PutPublicAccessBlock.html and https://docs.aws.amazon.com/AmazonS3/latest/API/API_DeletePublicAccessBlock.html (checked 2026-11-12)
- Local help: checked with aws-cli (`aws s3api put-public-access-block help`, `aws s3api delete-public-access-block help`). The help lists the four boolean fields in the shorthand form above. The delete help says it removes the bucket-level configuration only. The Doc pages say both calls need `s3:PutBucketPublicAccessBlock`. The get, put, and delete help pages list `--expected-bucket-owner`. The put help says a call with a wrong owner fails with `403 Forbidden`.
