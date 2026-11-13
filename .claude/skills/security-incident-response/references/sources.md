# Sources

This file lists every public source that the skill cites, grouped by the file that cites it.
All sources were checked on 2026-11-12.
The skill uses only public vendor, standards, and tool documentation.

## Contents

- [references/commands-aws.md](#referencescommands-awsmd)
- [references/commands-azure.md](#referencescommands-azuremd)
- [references/commands-cloudflare.md](#referencescommands-cloudflaremd)
- [references/commands-gcp.md](#referencescommands-gcpmd)
- [references/commands-github.md](#referencescommands-githubmd)
- [references/commands-hosts.md](#referencescommands-hostsmd)
- [references/commands-identity.md](#referencescommands-identitymd)
- [references/commands-kubernetes.md](#referencescommands-kubernetesmd)
- [references/commands-logs.md](#referencescommands-logsmd)
- [references/commands-network.md](#referencescommands-networkmd)
- [references/process.md](#referencesprocessmd)
- [references/technique.md](#referencestechniquemd)

## references/commands-aws.md

| Title                                                                                | URL                                                                                                         |
| ------------------------------------------------------------------------------------ | ----------------------------------------------------------------------------------------------------------- |
| AWS CLI: Using endpoints in the AWS CLI                                              | https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-endpoints.html                               |
| AWS CLI reference: sts get-caller-identity                                           | https://docs.aws.amazon.com/cli/latest/reference/sts/get-caller-identity.html                               |
| Viewing recent management events with the AWS CLI                                    | https://docs.aws.amazon.com/awscloudtrail/latest/userguide/view-cloudtrail-events-cli.html                  |
| AWS CloudTrail API Reference: ListEventDataStores                                    | https://docs.aws.amazon.com/awscloudtrail/latest/APIReference/API_ListEventDataStores.html                  |
| CloudTrail Lake availability change                                                  | https://docs.aws.amazon.com/awscloudtrail/latest/userguide/cloudtrail-lake-service-availability-change.html |
| Run and manage CloudTrail Lake queries with the AWS CLI                              | https://docs.aws.amazon.com/awscloudtrail/latest/userguide/lake-queries-cli.html                            |
| AWS CloudTrail API Reference: GetEventDataStore                                      | https://docs.aws.amazon.com/awscloudtrail/latest/APIReference/API_GetEventDataStore.html                    |
| AWS CloudTrail User Guide: Logging data events                                       | https://docs.aws.amazon.com/awscloudtrail/latest/userguide/logging-data-events-with-cloudtrail.html         |
| Optimize CloudTrail Lake queries                                                     | https://docs.aws.amazon.com/awscloudtrail/latest/userguide/lake-queries-optimization.html                   |
| AWS CloudTrail API Reference: GetQueryResults                                        | https://docs.aws.amazon.com/awscloudtrail/latest/APIReference/API_GetQueryResults.html                      |
| Amazon Athena: Configure access to databases and tables in the AWS Glue Data Catalog | https://docs.aws.amazon.com/athena/latest/ug/fine-grained-access-to-glue-resources.html                     |
| Amazon Athena: Encrypt managed query results                                         | https://docs.aws.amazon.com/athena/latest/ug/encrypting-managed-results.html                                |
| Amazon Athena: Encryption at rest                                                    | https://docs.aws.amazon.com/athena/latest/ug/encryption.html                                                |
| Amazon Athena: Override client-side settings                                         | https://docs.aws.amazon.com/athena/latest/ug/workgroups-settings-override.html                              |
| CreateTrail (CloudTrail API Reference)                                               | https://docs.aws.amazon.com/awscloudtrail/latest/APIReference/API_CreateTrail.html                          |
| GetTrailStatus (CloudTrail API Reference)                                            | https://docs.aws.amazon.com/awscloudtrail/latest/APIReference/API_GetTrailStatus.html                       |
| Set up partition projection (Athena)                                                 | https://docs.aws.amazon.com/athena/latest/ug/partition-projection-setting-up.html                           |
| Use partition projection with Amazon Athena                                          | https://docs.aws.amazon.com/athena/latest/ug/partition-projection.html                                      |
| JMESPath Specification                                                               | https://jmespath.org/specification.html                                                                     |
| CloudTrail table with partition projection                                           | https://docs.aws.amazon.com/athena/latest/ug/create-cloudtrail-table-partition-projection.html              |
| Example CloudTrail log queries (Athena)                                              | https://docs.aws.amazon.com/athena/latest/ug/query-examples-cloudtrail-logs.html                            |
| Athena GetQueryExecution                                                             | https://docs.aws.amazon.com/athena/latest/APIReference/API_GetQueryExecution.html                           |
| Athena API Reference: ResultConfiguration                                            | https://docs.aws.amazon.com/athena/latest/APIReference/API_ResultConfiguration.html                         |
| Athena: Managed query results                                                        | https://docs.aws.amazon.com/athena/latest/ug/managed-results.html                                           |
| Athena: Work with query results and recent queries                                   | https://docs.aws.amazon.com/athena/latest/ug/querying.html                                                  |
| CloudTrail: Getting and viewing your CloudTrail log files                            | https://docs.aws.amazon.com/awscloudtrail/latest/userguide/get-and-view-cloudtrail-log-files.html           |
| Athena GetQueryResults                                                               | https://docs.aws.amazon.com/athena/latest/APIReference/API_GetQueryResults.html                             |
| S3 server access logs: identify requests with Athena                                 | https://docs.aws.amazon.com/AmazonS3/latest/userguide/using-s3-access-logs-to-identify-requests.html        |
| S3 server access log format                                                          | https://docs.aws.amazon.com/AmazonS3/latest/userguide/LogFormat.html                                        |
| Amazon S3: Logging requests with server access logging                               | https://docs.aws.amazon.com/AmazonS3/latest/userguide/ServerLogs.html                                       |
| CloudTrail: Logging S3 data events for data governance, security, and compliance     | https://docs.aws.amazon.com/awscloudtrail/latest/userguide/logging-s3-data-events-governance.html           |
| Athena: ALB access logs table with partition projection                              | https://docs.aws.amazon.com/athena/latest/ug/create-alb-access-logs-table-partition-projection.html         |
| Athena: example queries for ALB access logs                                          | https://docs.aws.amazon.com/athena/latest/ug/query-alb-access-logs-examples.html                            |
| ELB: Access logs for your Application Load Balancer                                  | https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-access-logs.html          |
| Athena: table for CloudFront standard logs (legacy)                                  | https://docs.aws.amazon.com/athena/latest/ug/create-cloudfront-table-standard-logs.html                     |
| Athena: query CloudFront logs                                                        | https://docs.aws.amazon.com/athena/latest/ug/cloudfront-logs.html                                           |
| CloudFront standard logging reference                                                | https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/standard-logs-reference.html             |
| GuardDuty ListDetectors                                                              | https://docs.aws.amazon.com/guardduty/latest/APIReference/API_ListDetectors.html                            |
| GuardDuty ListFindings                                                               | https://docs.aws.amazon.com/guardduty/latest/APIReference/API_ListFindings.html                             |
| GuardDuty GetFindings                                                                | https://docs.aws.amazon.com/guardduty/latest/APIReference/API_GetFindings.html                              |
| AwsSecurityFindingFilters                                                            | https://docs.aws.amazon.com/securityhub/1.0/APIReference/API_AwsSecurityFindingFilters.html                 |
| AWS CLI User Guide: Using the pagination options in the AWS CLI                      | https://docs.aws.amazon.com/cli/latest/userguide/cli-usage-pagination.html                                  |
| AWS CLI User Guide: Filtering output in the AWS CLI                                  | https://docs.aws.amazon.com/cli/latest/userguide/cli-usage-filter.html                                      |
| Access Analyzer ListAnalyzers                                                        | https://docs.aws.amazon.com/access-analyzer/latest/APIReference/API_ListAnalyzers.html                      |
| ListFindingsV2                                                                       | https://docs.aws.amazon.com/access-analyzer/latest/APIReference/API_ListFindingsV2.html                     |
| Generate credential reports                                                          | https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_getting-report.html                         |
| IAM API Reference: GetCredentialReport                                               | https://docs.aws.amazon.com/IAM/latest/APIReference/API_GetCredentialReport.html                            |
| IAM GetAccessKeyLastUsed                                                             | https://docs.aws.amazon.com/IAM/latest/APIReference/API_GetAccessKeyLastUsed.html                           |
| IAM ListAccessKeys                                                                   | https://docs.aws.amazon.com/IAM/latest/APIReference/API_ListAccessKeys.html                                 |
| GetRole                                                                              | https://docs.aws.amazon.com/IAM/latest/APIReference/API_GetRole.html                                        |
| IAM ListRoles                                                                        | https://docs.aws.amazon.com/IAM/latest/APIReference/API_ListRoles.html                                      |
| IAM ListRolePolicies                                                                 | https://docs.aws.amazon.com/IAM/latest/APIReference/API_ListRolePolicies.html                               |
| Cognito DescribeUserPool                                                             | https://docs.aws.amazon.com/cognito-user-identity-pools/latest/APIReference/API_DescribeUserPool.html       |
| Cognito ListUserPoolClients                                                          | https://docs.aws.amazon.com/cognito-user-identity-pools/latest/APIReference/API_ListUserPoolClients.html    |
| Cognito ListUsers                                                                    | https://docs.aws.amazon.com/cognito-user-identity-pools/latest/APIReference/API_ListUsers.html              |
| Enabling S3 server access logging                                                    | https://docs.aws.amazon.com/AmazonS3/latest/userguide/enable-server-access-logging.html                     |
| Amazon S3: Delivering server access logs to CloudWatch Logs                          | https://docs.aws.amazon.com/AmazonS3/latest/userguide/sal-cw-enabling.html                                  |
| CloudWatch Logs API Reference: PutDeliverySource                                     | https://docs.aws.amazon.com/AmazonCloudWatchLogs/latest/APIReference/API_PutDeliverySource.html             |
| S3 GetPublicAccessBlock                                                              | https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetPublicAccessBlock.html                               |
| GetBucketPolicyStatus                                                                | https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetBucketPolicyStatus.html                              |
| S3 GetBucketAcl                                                                      | https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetBucketAcl.html                                       |
| S3 Control GetPublicAccessBlock                                                      | https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_GetPublicAccessBlock.html                       |
| Query Amazon VPC flow logs (Athena)                                                  | https://docs.aws.amazon.com/athena/latest/ug/vpc-flow-logs.html                                             |
| Amazon VPC User Guide: Flow logs basics                                              | https://docs.aws.amazon.com/vpc/latest/userguide/flow-logs-basics.html                                      |
| Amazon VPC User Guide: Responsibilities and permissions for owners and participants  | https://docs.aws.amazon.com/vpc/latest/userguide/vpc-share-limitations.html                                 |
| CloudWatch Logs Insights sample queries                                              | https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/CWL_QuerySyntax-examples.html                      |
| ELBv2 DescribeLoadBalancers                                                          | https://docs.aws.amazon.com/elasticloadbalancing/latest/APIReference/API_DescribeLoadBalancers.html         |
| Enable access logs for ALB                                                           | https://docs.aws.amazon.com/elasticloadbalancing/latest/application/enable-access-logging.html              |
| Elastic Load Balancing: Disable access logs for your Application Load Balancer       | https://docs.aws.amazon.com/elasticloadbalancing/latest/application/disable-access-logging.html             |
| Elastic Load Balancing: CloudWatch Logs for your Application Load Balancer           | https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-cloudwatch-logs.html      |
| ELBv2 DescribeListeners                                                              | https://docs.aws.amazon.com/elasticloadbalancing/latest/APIReference/API_DescribeListeners.html             |
| ELBv2 DescribeRules                                                                  | https://docs.aws.amazon.com/elasticloadbalancing/latest/APIReference/API_DescribeRules.html                 |
| CloudFront standard logging (v2)                                                     | https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/standard-logging.html                    |
| Amazon CloudWatch Logs API Reference: DeliveryDestination                            | https://docs.aws.amazon.com/AmazonCloudWatchLogs/latest/APIReference/API_DeliveryDestination.html           |
| EC2 DescribeSecurityGroups                                                           | https://docs.aws.amazon.com/AWSEC2/latest/APIReference/API_DescribeSecurityGroups.html                      |
| EC2 DescribeSecurityGroupRules                                                       | https://docs.aws.amazon.com/AWSEC2/latest/APIReference/API_DescribeSecurityGroupRules.html                  |
| EC2 DescribeInstances                                                                | https://docs.aws.amazon.com/AWSEC2/latest/APIReference/API_DescribeInstances.html                           |
| AWS CLI reference: organizations                                                     | https://docs.aws.amazon.com/cli/latest/reference/organizations/                                             |
| Organizations ListPolicies                                                           | https://docs.aws.amazon.com/organizations/latest/APIReference/API_ListPolicies.html                         |
| Organizations DescribePolicy                                                         | https://docs.aws.amazon.com/organizations/latest/APIReference/API_DescribePolicy.html                       |
| Organizations ListTargetsForPolicy                                                   | https://docs.aws.amazon.com/organizations/latest/APIReference/API_ListTargetsForPolicy.html                 |
| AWS Organizations User Guide: SCP syntax                                             | https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_scps_syntax.html            |
| AWS Organizations: Service control policies (SCPs)                                   | https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_scps.html                   |
| AWS STS global endpoint (target of the AWS-51 clock check, not a doc page)           | https://sts.amazonaws.com/                                                                                  |
| Revoke IAM role temporary security credentials                                       | https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use_revoke-sessions.html                          |
| IAM User Guide: Policy evaluation logic                                              | https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_evaluation-logic.html                   |
| curl manual page                                                                     | https://curl.se/docs/manpage.html                                                                           |
| IAM UpdateAccessKey                                                                  | https://docs.aws.amazon.com/IAM/latest/APIReference/API_UpdateAccessKey.html                                |
| EC2 modify IMDS options on existing instances                                        | https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/configuring-IMDS-existing-instances.html                |
| Amazon EC2 API Reference: ModifyInstanceMetadataOptions                              | https://docs.aws.amazon.com/AWSEC2/latest/APIReference/API_ModifyInstanceMetadataOptions.html               |
| EC2 ModifyInstanceAttribute                                                          | https://docs.aws.amazon.com/AWSEC2/latest/APIReference/API_ModifyInstanceAttribute.html                     |
| Amazon EC2 User Guide: Change the security groups for your Amazon EC2 instance       | https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/changing-security-group.html                            |
| EC2 ModifyNetworkInterfaceAttribute                                                  | https://docs.aws.amazon.com/AWSEC2/latest/APIReference/API_ModifyNetworkInterfaceAttribute.html             |
| EC2 security group connection tracking                                               | https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/security-group-connection-tracking.html                 |
| EC2 security group rules                                                             | https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/security-group-rules.html                               |
| Amazon VPC User Guide: Security group rules                                          | https://docs.aws.amazon.com/vpc/latest/userguide/security-group-rules.html                                  |
| Amazon VPC User Guide: Control subnet traffic with network access control lists      | https://docs.aws.amazon.com/vpc/latest/userguide/vpc-network-acls.html                                      |
| Amazon Route 53 Developer Guide: Route 53 Resolver DNS Firewall                      | https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/resolver-dns-firewall.html                        |
| EC2 CreateSnapshot                                                                   | https://docs.aws.amazon.com/AWSEC2/latest/APIReference/API_CreateSnapshot.html                              |
| EC2 stop and start instances                                                         | https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/Stop_Start.html                                         |
| Cognito UpdateUserPool                                                               | https://docs.aws.amazon.com/cognito-user-identity-pools/latest/APIReference/API_UpdateUserPool.html         |
| Amazon S3 API Reference: PutPublicAccessBlock                                        | https://docs.aws.amazon.com/AmazonS3/latest/API/API_PutPublicAccessBlock.html                               |
| Amazon S3 API Reference: DeletePublicAccessBlock                                     | https://docs.aws.amazon.com/AmazonS3/latest/API/API_DeletePublicAccessBlock.html                            |

## references/commands-azure.md

| Title                                                                     | URL                                                                                                      |
| ------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------- |
| Azure CLI: Azure cloud management with the Azure CLI                      | https://learn.microsoft.com/en-us/cli/azure/manage-clouds-azure-cli                                      |
| az cloud (Azure CLI reference)                                            | https://learn.microsoft.com/en-us/cli/azure/cloud                                                        |
| az account                                                                | https://learn.microsoft.com/en-us/cli/azure/account                                                      |
| List signIns (Graph v1.0)                                                 | https://learn.microsoft.com/en-us/graph/api/signin-list?view=graph-rest-1.0                              |
| List directoryAudits                                                      | https://learn.microsoft.com/en-us/graph/api/directoryaudit-list?view=graph-rest-1.0                      |
| Azure Monitor: Activity Log in Azure Monitor                              | https://learn.microsoft.com/en-us/azure/azure-monitor/fundamentals/activity-log                          |
| az monitor activity-log                                                   | https://learn.microsoft.com/en-us/cli/azure/monitor/activity-log                                         |
| az ad app                                                                 | https://learn.microsoft.com/en-us/cli/azure/ad/app                                                       |
| az ad app credential                                                      | https://learn.microsoft.com/en-us/cli/azure/ad/app/credential                                            |
| az ad sp                                                                  | https://learn.microsoft.com/en-us/cli/azure/ad/sp                                                        |
| List oAuth2PermissionGrants                                               | https://learn.microsoft.com/en-us/graph/api/oauth2permissiongrant-list?view=graph-rest-1.0               |
| List appRoleAssignments                                                   | https://learn.microsoft.com/en-us/graph/api/serviceprincipal-list-approleassignments?view=graph-rest-1.0 |
| List appRoleAssignedTo                                                    | https://learn.microsoft.com/en-us/graph/api/serviceprincipal-list-approleassignedto?view=graph-rest-1.0  |
| user: revokeSignInSessions                                                | https://learn.microsoft.com/en-us/graph/api/user-revokesigninsessions?view=graph-rest-1.0                |
| Microsoft Entra ID: Revoke user access in an emergency                    | https://learn.microsoft.com/en-us/entra/identity/users/users-revoke-access                               |
| Update user                                                               | https://learn.microsoft.com/en-us/graph/api/user-update?view=graph-rest-1.0                              |
| Microsoft Entra Workload ID: Troubleshoot revoked application credentials | https://learn.microsoft.com/en-us/entra/workload-id/troubleshoot-revoked-credentials                     |

## references/commands-cloudflare.md

| Title                                                                         | URL                                                                                                                                          |
| ----------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------- |
| curl FAQ: How do I keep usernames and passwords secret in curl command lines? | https://curl.se/docs/faq.html                                                                                                                |
| curl man page: -H, --header                                                   | https://curl.se/docs/manpage.html#-H                                                                                                         |
| Cloudflare GraphQL Analytics API: Errors                                      | https://developers.cloudflare.com/analytics/graphql-api/errors/                                                                              |
| Querying firewall events with GraphQL                                         | https://developers.cloudflare.com/analytics/graphql-api/tutorials/querying-firewall-events/                                                  |
| Cloudflare GraphQL Analytics API: Pagination                                  | https://developers.cloudflare.com/analytics/graphql-api/features/pagination/                                                                 |
| Cloudflare GraphQL Analytics API: Sampling                                    | https://developers.cloudflare.com/analytics/graphql-api/sampling/                                                                            |
| GraphQL filtering                                                             | https://developers.cloudflare.com/analytics/graphql-api/features/filtering/                                                                  |
| Explore the GraphQL schema                                                    | https://developers.cloudflare.com/analytics/graphql-api/getting-started/explore-graphql-schema/                                              |
| API: list audit logs (v2)                                                     | https://developers.cloudflare.com/api/resources/accounts/subresources/logs/subresources/audit/methods/list/                                  |
| Audit logs v2                                                                 | https://developers.cloudflare.com/fundamentals/account/account-security/audit-logs/                                                          |
| API: list audit logs (v1)                                                     | https://developers.cloudflare.com/api/resources/audit_logs/methods/list/                                                                     |
| jq manual                                                                     | https://jqlang.github.io/jq/manual/                                                                                                          |
| API: list Access applications                                                 | https://developers.cloudflare.com/api/resources/zero_trust/subresources/access/subresources/applications/methods/list/                       |
| API: list application policies                                                | https://developers.cloudflare.com/api/resources/zero_trust/subresources/access/subresources/applications/subresources/policies/methods/list/ |
| API: list reusable policies                                                   | https://developers.cloudflare.com/api/resources/zero_trust/subresources/access/subresources/policies/methods/list/                           |
| Rulesets API: view                                                            | https://developers.cloudflare.com/ruleset-engine/rulesets-api/view/                                                                          |
| Troubleshooting (Cloudflare fundamentals)                                     | https://developers.cloudflare.com/fundamentals/reference/troubleshooting/                                                                    |
| Protect your origin server (Cloudflare)                                       | https://developers.cloudflare.com/fundamentals/security/protect-your-origin-server/                                                          |
| Rulesets API: add rule                                                        | https://developers.cloudflare.com/ruleset-engine/rulesets-api/add-rule/                                                                      |
| Rulesets API: delete rule                                                     | https://developers.cloudflare.com/ruleset-engine/rulesets-api/delete-rule/                                                                   |
| Cloudflare Ruleset Engine: JSON objects                                       | https://developers.cloudflare.com/ruleset-engine/rulesets-api/json-object/                                                                   |
| Custom lists                                                                  | https://developers.cloudflare.com/waf/tools/lists/custom-lists/                                                                              |
| Cloudflare Ruleset Engine: Create ruleset                                     | https://developers.cloudflare.com/ruleset-engine/rulesets-api/create/                                                                        |
| Cloudflare Ruleset Engine: Delete rulesets                                    | https://developers.cloudflare.com/ruleset-engine/rulesets-api/delete/                                                                        |
| Rule phases and interactions (Cloudflare WAF)                                 | https://developers.cloudflare.com/waf/troubleshooting/phase-interactions/                                                                    |
| List IP Access rules (Cloudflare API)                                         | https://developers.cloudflare.com/api/resources/firewall/subresources/access_rules/methods/list/                                             |
| Zone details (Cloudflare API)                                                 | https://developers.cloudflare.com/api/resources/zones/methods/get/                                                                           |
| Enforce DNS-only (Cloudflare DNS)                                             | https://developers.cloudflare.com/dns/proxy-status/enforce-dns-only/                                                                         |
| Proxy status (Cloudflare DNS)                                                 | https://developers.cloudflare.com/dns/proxy-status/                                                                                          |
| Show zone DNS settings (Cloudflare API)                                       | https://developers.cloudflare.com/api/resources/dns/subresources/settings/subresources/zone/methods/get/                                     |
| List DNS records (Cloudflare API)                                             | https://developers.cloudflare.com/api/resources/dns/subresources/records/methods/list/                                                       |
| API: list lists                                                               | https://developers.cloudflare.com/api/resources/rules/subresources/lists/methods/list/                                                       |
| API: list items                                                               | https://developers.cloudflare.com/api/resources/rules/subresources/lists/subresources/items/methods/list/                                    |
| API: create items                                                             | https://developers.cloudflare.com/api/resources/rules/subresources/lists/subresources/items/methods/create/                                  |
| API: delete items                                                             | https://developers.cloudflare.com/api/resources/rules/subresources/lists/subresources/items/methods/delete/                                  |
| API: bulk operation status                                                    | https://developers.cloudflare.com/api/resources/rules/subresources/lists/subresources/bulk_operations/methods/get/                           |
| curl manual page                                                              | https://curl.se/docs/manpage.html                                                                                                            |
| Route 53: Considerations when working with a private hosted zone              | https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/hosted-zone-private-considerations.html                                            |
| RFC 1918: Address Allocation for Private Internets                            | https://www.rfc-editor.org/rfc/rfc1918                                                                                                       |
| RFC 4193: Unique Local IPv6 Unicast Addresses                                 | https://www.rfc-editor.org/rfc/rfc4193                                                                                                       |

## references/commands-gcp.md

| Title                                                                          | URL                                                                                                             |
| ------------------------------------------------------------------------------ | --------------------------------------------------------------------------------------------------------------- |
| gcloud topic: endpoint-override                                                | https://docs.cloud.google.com/sdk/gcloud/reference/topic/endpoint-override                                      |
| gcloud config list                                                             | https://docs.cloud.google.com/sdk/gcloud/reference/config/list                                                  |
| gcloud CLI: Managing gcloud CLI configurations                                 | https://docs.cloud.google.com/sdk/docs/configurations                                                           |
| Authorize the gcloud CLI                                                       | https://docs.cloud.google.com/sdk/docs/authenticate                                                             |
| gcloud config get                                                              | https://docs.cloud.google.com/sdk/gcloud/reference/config/get                                                   |
| Cloud Logging: AuditLog type reference                                         | https://docs.cloud.google.com/logging/docs/reference/audit/auditlog/rest/Shared.Types/AuditLog                  |
| gcloud logging read                                                            | https://docs.cloud.google.com/sdk/gcloud/reference/logging/read                                                 |
| Logging query language                                                         | https://docs.cloud.google.com/logging/docs/view/logging-query-language                                          |
| Sample queries (Logging)                                                       | https://docs.cloud.google.com/logging/docs/view/query-library                                                   |
| Cloud Audit Logs overview                                                      | https://docs.cloud.google.com/logging/docs/audit                                                                |
| gcloud projects get-iam-policy                                                 | https://docs.cloud.google.com/sdk/gcloud/reference/projects/get-iam-policy                                      |
| gcloud organizations get-iam-policy                                            | https://docs.cloud.google.com/sdk/gcloud/reference/organizations/get-iam-policy                                 |
| gcloud resource-manager folders get-iam-policy                                 | https://docs.cloud.google.com/sdk/gcloud/reference/resource-manager/folders/get-iam-policy                      |
| gcloud topic filters                                                           | https://docs.cloud.google.com/sdk/gcloud/reference/topic/filters                                                |
| Google Cloud IAM: Overview of IAM Conditions                                   | https://docs.cloud.google.com/iam/docs/conditions-overview                                                      |
| Google Cloud IAM: Understanding allow policies                                 | https://docs.cloud.google.com/iam/docs/policies                                                                 |
| Google Cloud IAM: Allow policies                                               | https://docs.cloud.google.com/iam/docs/allow-policies                                                           |
| Google Cloud IAM: Principal identifiers                                        | https://docs.cloud.google.com/iam/docs/principal-identifiers                                                    |
| Google Cloud IAM: Troubleshoot IAM access                                      | https://docs.cloud.google.com/iam/docs/troubleshoot-policies                                                    |
| gcloud iam service-accounts list                                               | https://docs.cloud.google.com/sdk/gcloud/reference/iam/service-accounts/list                                    |
| gcloud iam service-accounts keys list                                          | https://docs.cloud.google.com/sdk/gcloud/reference/iam/service-accounts/keys/list                               |
| gcloud scc findings list                                                       | https://docs.cloud.google.com/sdk/gcloud/reference/scc/findings/list                                            |
| gcloud compute firewall-rules list                                             | https://docs.cloud.google.com/sdk/gcloud/reference/compute/firewall-rules/list                                  |
| Cloud NGFW: Policy and rule evaluation order                                   | https://docs.cloud.google.com/firewall/docs/firewall-policies-rule-eval-order                                   |
| VPC: Shared VPC                                                                | https://docs.cloud.google.com/vpc/docs/shared-vpc                                                               |
| gcloud reference: compute instances network-interfaces get-effective-firewalls | https://docs.cloud.google.com/sdk/gcloud/reference/compute/instances/network-interfaces/get-effective-firewalls |
| Cloud NGFW: Use global network firewall policies and rules                     | https://docs.cloud.google.com/firewall/docs/manage-global-firewall-policies                                     |
| gcloud storage buckets list                                                    | https://docs.cloud.google.com/sdk/gcloud/reference/storage/buckets/list                                         |
| Cloud Storage JSON API: Buckets resource                                       | https://docs.cloud.google.com/storage/docs/json_api/v1/buckets                                                  |
| gcloud storage buckets describe                                                | https://docs.cloud.google.com/sdk/gcloud/reference/storage/buckets/describe                                     |
| Use public access prevention                                                   | https://docs.cloud.google.com/storage/docs/using-public-access-prevention                                       |
| gcloud storage buckets get-iam-policy                                          | https://docs.cloud.google.com/sdk/gcloud/reference/storage/buckets/get-iam-policy                               |
| gcloud iam service-accounts keys disable                                       | https://docs.cloud.google.com/sdk/gcloud/reference/iam/service-accounts/keys/disable                            |
| Disable and enable service account keys                                        | https://docs.cloud.google.com/iam/docs/keys-disable-enable                                                      |
| gcloud iam service-accounts disable                                            | https://docs.cloud.google.com/sdk/gcloud/reference/iam/service-accounts/disable                                 |
| Disable and enable service accounts                                            | https://docs.cloud.google.com/iam/docs/service-accounts-disable-enable                                          |
| IAM REST API: projects.serviceAccounts.disable                                 | https://docs.cloud.google.com/iam/docs/reference/rest/v1/projects.serviceAccounts/disable                       |
| gcloud storage buckets update reference                                        | https://docs.cloud.google.com/sdk/gcloud/reference/storage/buckets/update                                       |
| Cloud Storage: Public access prevention                                        | https://docs.cloud.google.com/storage/docs/public-access-prevention                                             |

## references/commands-github.md

| Title                                                                         | URL                                                                                                                                                                                              |
| ----------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| GitHub CLI manual: gh help environment                                        | https://cli.github.com/manual/gh_help_environment                                                                                                                                                |
| GitHub REST API: Get the authenticated user                                   | https://docs.github.com/en/rest/users/users#get-the-authenticated-user                                                                                                                           |
| gh config (GitHub CLI manual)                                                 | https://cli.github.com/manual/gh_config                                                                                                                                                          |
| Get the audit log for an organization                                         | https://docs.github.com/en/enterprise-cloud@latest/rest/orgs/orgs#get-the-audit-log-for-an-organization                                                                                          |
| Reviewing the audit log for your organization                                 | https://docs.github.com/en/enterprise-cloud@latest/organizations/keeping-your-organization-secure/managing-security-settings-for-your-organization/reviewing-the-audit-log-for-your-organization |
| REST deploy keys                                                              | https://docs.github.com/en/rest/deploy-keys/deploy-keys                                                                                                                                          |
| gh repo deploy-key list                                                       | https://cli.github.com/manual/gh_repo_deploy-key_list                                                                                                                                            |
| REST Actions secrets                                                          | https://docs.github.com/en/rest/actions/secrets                                                                                                                                                  |
| gh secret list                                                                | https://cli.github.com/manual/gh_secret_list                                                                                                                                                     |
| REST secret scanning                                                          | https://docs.github.com/en/rest/secret-scanning/secret-scanning                                                                                                                                  |
| REST organization members                                                     | https://docs.github.com/en/rest/orgs/members                                                                                                                                                     |
| REST outside collaborators                                                    | https://docs.github.com/en/rest/orgs/outside-collaborators                                                                                                                                       |
| List app installations for an organization                                    | https://docs.github.com/en/rest/orgs/orgs#list-app-installations-for-an-organization                                                                                                             |
| GitHub REST API: Permissions required for fine-grained personal access tokens | https://docs.github.com/en/rest/authentication/permissions-required-for-fine-grained-personal-access-tokens                                                                                      |
| GitHub Docs: Disabling and enabling a workflow                                | https://docs.github.com/en/actions/how-tos/manage-workflow-runs/disable-and-enable-workflows                                                                                                     |
| GitHub REST API: Workflows                                                    | https://docs.github.com/en/rest/actions/workflows                                                                                                                                                |
| GitHub REST API: Branches                                                     | https://docs.github.com/en/rest/branches/branches                                                                                                                                                |
| GitHub Docs: Workflow syntax for GitHub Actions                               | https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax                                                                                                               |
| GitHub Docs: Secure use reference                                             | https://docs.github.com/en/actions/reference/security/secure-use                                                                                                                                 |
| GitHub Docs: Workflows                                                        | https://docs.github.com/en/actions/concepts/workflows-and-actions/workflows                                                                                                                      |

## references/commands-hosts.md

| Title                                                 | URL                                                                                                                           |
| ----------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------- |
| ps(1)                                                 | https://man7.org/linux/man-pages/man1/ps.1.html                                                                               |
| proc_pid_exe(5)                                       | https://man7.org/linux/man-pages/man5/proc_pid_exe.5.html                                                                     |
| proc_pid_cmdline(5)                                   | https://man7.org/linux/man-pages/man5/proc_pid_cmdline.5.html                                                                 |
| ss(8)                                                 | https://man7.org/linux/man-pages/man8/ss.8.html                                                                               |
| lsof manual page (lsof project)                       | https://lsof.readthedocs.io/en/latest/manpage/                                                                                |
| crontab(1)                                            | https://man7.org/linux/man-pages/man1/crontab.1.html                                                                          |
| systemctl(1)                                          | https://man7.org/linux/man-pages/man1/systemctl.1.html                                                                        |
| systemd.timer(5)                                      | https://man7.org/linux/man-pages/man5/systemd.timer.5.html                                                                    |
| systemd.unit(5)                                       | https://man7.org/linux/man-pages/man5/systemd.unit.5.html                                                                     |
| OpenSSH sshd(8): AUTHORIZED_KEYS FILE FORMAT          | https://man.openbsd.org/sshd.8#AUTHORIZED_KEYS_FILE_FORMAT                                                                    |
| ld.so(8)                                              | https://man7.org/linux/man-pages/man8/ld.so.8.html                                                                            |
| GNU Bash manual: Bash Startup Files                   | https://www.gnu.org/software/bash/manual/html_node/Bash-Startup-Files.html                                                    |
| Zsh manual: Files                                     | https://zsh.sourceforge.io/Doc/Release/Files.html                                                                             |
| POSIX (IEEE Std 1003.1-2024): awk                     | https://pubs.opengroup.org/onlinepubs/9799919799/utilities/awk.html                                                           |
| Open items automatically when you log in              | https://support.apple.com/guide/mac-help/open-items-automatically-when-you-log-in-mtusr003/mac                                |
| Creating Launch Daemons and Agents                    | https://developer.apple.com/library/archive/documentation/MacOSX/Conceptual/BPSystemStartup/Chapters/CreatingLaunchdJobs.html |
| Apple: manage login items and background tasks on Mac | https://support.apple.com/guide/deployment/manage-login-items-background-tasks-mac-depdca572563/web                           |
| last(1)                                               | https://man7.org/linux/man-pages/man1/last.1.html                                                                             |
| w(1) Linux manual page                                | https://man7.org/linux/man-pages/man1/w.1.html                                                                                |
| who(1) Linux manual page                              | https://man7.org/linux/man-pages/man1/who.1.html                                                                              |
| journalctl(1)                                         | https://man7.org/linux/man-pages/man1/journalctl.1.html                                                                       |
| systemd.time(7)                                       | https://man7.org/linux/man-pages/man7/systemd.time.7.html                                                                     |
| GNU grep manual                                       | https://www.gnu.org/software/grep/manual/grep.html                                                                            |
| man7.org: mount(8)                                    | https://man7.org/linux/man-pages/man8/mount.8.html                                                                            |
| sha256sum(1)                                          | https://man7.org/linux/man-pages/man1/sha256sum.1.html                                                                        |
| Perl documentation: shasum                            | https://perldoc.perl.org/shasum                                                                                               |
| Bash Reference Manual                                 | https://www.gnu.org/software/bash/manual/bash.html                                                                            |
| Zsh Documentation: Options                            | https://zsh.sourceforge.io/Doc/Release/Options.html                                                                           |
| AVML README                                           | https://github.com/microsoft/avml                                                                                             |
| LiME README                                           | https://github.com/504ensicsLabs/LiME                                                                                         |
| LiME source code: main.c                              | https://raw.githubusercontent.com/504ensicsLabs/LiME/master/src/main.c                                                        |
| kmod source: tools/opt.c (module option parser)       | https://github.com/kmod-project/kmod/blob/master/tools/opt.c                                                                  |
| About System Integrity Protection                     | https://support.apple.com/en-us/102149                                                                                        |
| dd(1)                                                 | https://man7.org/linux/man-pages/man1/dd.1.html                                                                               |
| RFC 3227                                              | https://www.rfc-editor.org/rfc/rfc3227                                                                                        |
| NIST SP 800-86                                        | https://csrc.nist.gov/pubs/sp/800/86/final                                                                                    |

## references/commands-identity.md

| Title                                                                         | URL                                                                                                                                         |
| ----------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------- |
| curl FAQ: How do I keep usernames and passwords secret in curl command lines? | https://curl.se/docs/faq.html                                                                                                               |
| curl man page: -H, --header                                                   | https://curl.se/docs/manpage.html#-H                                                                                                        |
| curl manual page                                                              | https://curl.se/docs/manpage.html                                                                                                           |
| System Log query                                                              | https://developer.okta.com/docs/reference/system-log-query/                                                                                 |
| Okta Management API: Retrieve a user                                          | https://developer.okta.com/docs/api/openapi/okta-management/management/tags/user/other/getuser                                              |
| List all users                                                                | https://developer.okta.com/docs/api/openapi/okta-management/management/tags/user/other/listusers                                            |
| List all System Log events                                                    | https://developer.okta.com/docs/api/openapi/okta-management/management/tags/systemlog/other/listlogevents                                   |
| Okta event types                                                              | https://developer.okta.com/docs/reference/api/event-types/                                                                                  |
| List all enrolled factors                                                     | https://developer.okta.com/docs/api/openapi/okta-management/management/tags/userfactor/other/listfactors                                    |
| Okta Management API: List all authenticator enrollments                       | https://developer.okta.com/docs/api/openapi/okta-management/management/tags/userauthenticatorenrollments/other/listauthenticatorenrollments |
| Revoke all user sessions                                                      | https://developer.okta.com/docs/api/openapi/okta-management/management/tags/usersessions/other/revokeusersessions                           |
| Suspend a user                                                                | https://developer.okta.com/docs/api/openapi/okta-management/management/tags/userlifecycle/other/suspenduser                                 |
| Unsuspend a user                                                              | https://developer.okta.com/docs/api/openapi/okta-management/management/tags/userlifecycle/other/unsuspenduser                               |
| Okta Help: Deactivate, suspend, or delete a user account                      | https://help.okta.com/en-us/Content/topics/users-groups-profiles/usgp-deactivate-user-account.htm                                           |
| Reports API activities.list                                                   | https://developers.google.com/workspace/admin/reports/v1/reference/activities/list                                                          |
| Login audit activity events                                                   | https://developers.google.com/workspace/admin/reports/v1/appendix/activity/login                                                            |
| Admin user settings events                                                    | https://developers.google.com/workspace/admin/reports/v1/appendix/activity/admin-user-settings                                              |
| Directory API users.get                                                       | https://developers.google.com/workspace/admin/directory/reference/rest/v1/users/get                                                         |
| Directory API users                                                           | https://developers.google.com/workspace/admin/directory/reference/rest/v1/users                                                             |
| Directory API users.list                                                      | https://developers.google.com/workspace/admin/directory/reference/rest/v1/users/list                                                        |
| Search for users                                                              | https://developers.google.com/workspace/admin/directory/v1/guides/search-users                                                              |
| Directory API users.signOut                                                   | https://developers.google.com/workspace/admin/directory/reference/rest/v1/users/signOut                                                     |
| Directory API tokens.list                                                     | https://developers.google.com/workspace/admin/directory/reference/rest/v1/tokens/list                                                       |
| Directory API tokens                                                          | https://developers.google.com/workspace/admin/directory/reference/rest/v1/tokens                                                            |
| Directory API tokens.delete                                                   | https://developers.google.com/workspace/admin/directory/reference/rest/v1/tokens/delete                                                     |

## references/commands-kubernetes.md

| Title                                                        | URL                                                                                                         |
| ------------------------------------------------------------ | ----------------------------------------------------------------------------------------------------------- |
| kubeconfig (v1)                                              | https://kubernetes.io/docs/reference/config-api/kubeconfig.v1/                                              |
| kubectl quick reference                                      | https://kubernetes.io/docs/reference/kubectl/quick-reference/                                               |
| Kubernetes: Organizing cluster access using kubeconfig files | https://kubernetes.io/docs/concepts/configuration/organize-cluster-access-kubeconfig/                       |
| RBAC                                                         | https://kubernetes.io/docs/reference/access-authn-authz/rbac/                                               |
| kubectl describe                                             | https://kubernetes.io/docs/reference/kubectl/generated/kubectl_describe/                                    |
| User impersonation                                           | https://kubernetes.io/docs/reference/access-authn-authz/user-impersonation/                                 |
| Kubernetes API: SelfSubjectRulesReview                       | https://kubernetes.io/docs/reference/kubernetes-api/definitions/self-subject-rules-review-v1-authorization/ |
| Kubernetes: Authenticating                                   | https://kubernetes.io/docs/reference/access-authn-authz/authentication/                                     |
| Configure service accounts                                   | https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/                         |
| Secrets                                                      | https://kubernetes.io/docs/concepts/configuration/secret/                                                   |
| Ingress                                                      | https://kubernetes.io/docs/concepts/services-networking/ingress/                                            |
| kubectl events                                               | https://kubernetes.io/docs/reference/kubectl/generated/kubectl_events/                                      |
| Auditing                                                     | https://kubernetes.io/docs/tasks/debug/debug-cluster/audit/                                                 |
| Audit API v1 reference                                       | https://kubernetes.io/docs/reference/config-api/apiserver-audit.v1/                                         |
| EKS control plane logs                                       | https://docs.aws.amazon.com/eks/latest/userguide/control-plane-logs.html                                    |
| GKE audit logging                                            | https://docs.cloud.google.com/kubernetes-engine/docs/how-to/audit-logging                                   |
| Monitor AKS                                                  | https://learn.microsoft.com/en-us/azure/aks/monitor-aks                                                     |
| kubectl get                                                  | https://kubernetes.io/docs/reference/kubectl/generated/kubectl_get/                                         |
| jq Manual                                                    | https://jqlang.org/manual/                                                                                  |
| Kubernetes: DaemonSet                                        | https://kubernetes.io/docs/concepts/workloads/controllers/daemonset/                                        |
| Kubernetes: Safely Drain a Node                              | https://kubernetes.io/docs/tasks/administer-cluster/safely-drain-node/                                      |
| Kubernetes: Assigning Pods to Nodes                          | https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/                                    |
| kubectl cordon                                               | https://kubernetes.io/docs/reference/kubectl/generated/kubectl_cordon/                                      |
| Field selectors                                              | https://kubernetes.io/docs/concepts/overview/working-with-objects/field-selectors/                          |
| Service (Kubernetes)                                         | https://kubernetes.io/docs/concepts/services-networking/service/                                            |
| EndpointSlices (Kubernetes)                                  | https://kubernetes.io/docs/concepts/services-networking/endpoint-slices/                                    |
| Kubernetes API: Deployment                                   | https://kubernetes.io/docs/reference/kubernetes-api/apps/deployment-v1/                                     |
| Kubernetes: Pod Lifecycle                                    | https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/                                           |
| Kubernetes: Network Policies                                 | https://kubernetes.io/docs/concepts/services-networking/network-policies/                                   |
| Kubernetes: Using NodeLocal DNSCache in Kubernetes Clusters  | https://kubernetes.io/docs/tasks/administer-cluster/nodelocaldns/                                           |
| Kubernetes API: NetworkPolicy                                | https://kubernetes.io/docs/reference/kubernetes-api/networking/network-policy-v1/                           |
| kubectl reference: kubectl delete                            | https://kubernetes.io/docs/reference/kubectl/generated/kubectl_delete/                                      |

## references/commands-logs.md

| Title                        | URL                                                                                                        |
| ---------------------------- | ---------------------------------------------------------------------------------------------------------- |
| jq Manual                    | https://jqlang.org/manual/                                                                                 |
| CloudTrail log file examples | https://docs.aws.amazon.com/awscloudtrail/latest/userguide/cloudtrail-log-file-examples.html               |
| Bash Reference Manual        | https://www.gnu.org/software/bash/manual/bash.html                                                         |
| Zsh Documentation: Options   | https://zsh.sourceforge.io/Doc/Release/Options.html                                                        |
| CloudTrail record contents   | https://docs.aws.amazon.com/awscloudtrail/latest/userguide/cloudtrail-event-reference-record-contents.html |
| GNU grep manual              | https://www.gnu.org/software/grep/manual/grep.html                                                         |
| GNU Gzip manual              | https://www.gnu.org/software/gzip/manual/gzip.html                                                         |
| GNU awk manual               | https://www.gnu.org/software/gawk/manual/gawk.html                                                         |
| GNU coreutils sort           | https://www.gnu.org/software/coreutils/manual/html_node/sort-invocation.html                               |

## references/commands-network.md

| Title                                           | URL                                                                           |
| ----------------------------------------------- | ----------------------------------------------------------------------------- |
| BIND 9 manual pages (dig)                       | https://bind9.readthedocs.io/en/latest/manpages.html                          |
| RFC 3912 WHOIS                                  | https://www.rfc-editor.org/rfc/rfc3912                                        |
| IANA: WHOIS service help                        | https://www.iana.org/help/whois                                               |
| FreeBSD manual page: whois(1)                   | https://man.freebsd.org/cgi/man.cgi?query=whois&sektion=1                     |
| curl manual page                                | https://curl.se/docs/manpage.html                                             |
| openssl-s_client                                | https://docs.openssl.org/master/man1/openssl-s_client/                        |
| openssl-x509                                    | https://docs.openssl.org/master/man1/openssl-x509/                            |
| jq Manual                                       | https://jqlang.org/manual/                                                    |
| Nmap reference guide: Target specification      | https://nmap.org/book/man-target-specification.html                           |
| Cloudflare: How Cloudflare works                | https://developers.cloudflare.com/fundamentals/concepts/how-cloudflare-works/ |
| Nmap reference guide: Miscellaneous options     | https://nmap.org/book/man-misc-options.html                                   |
| Nmap Port Scanning Techniques                   | https://nmap.org/book/man-port-scanning-techniques.html                       |
| Nmap Port Specification                         | https://nmap.org/book/man-port-specification.html                             |
| Nmap Version Detection                          | https://nmap.org/book/man-version-detection.html                              |
| Nmap NSE ssl-enum-ciphers                       | https://nmap.org/nsedoc/scripts/ssl-enum-ciphers.html                         |
| Nmap Network Scanning: Usage and Examples (NSE) | https://nmap.org/book/nse-usage.html                                          |

## references/process.md

| Title                                             | URL                                                                                                                    |
| ------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------- |
| SRE book: Managing Incidents                      | https://sre.google/sre-book/managing-incidents/                                                                        |
| SRE workbook: Incident Response                   | https://sre.google/workbook/incident-response/                                                                         |
| AWS Well-Architected SEC10-BP02                   | https://docs.aws.amazon.com/wellarchitected/latest/security-pillar/sec_incident_response_develop_management_plans.html |
| Google Cloud: Data incident response process      | https://docs.cloud.google.com/docs/security/incident-response                                                          |
| NIST SP 800-86                                    | https://csrc.nist.gov/pubs/sp/800/86/final                                                                             |
| RFC 3227                                          | https://www.rfc-editor.org/rfc/rfc3227.html                                                                            |
| SRE workbook: Postmortem Culture                  | https://sre.google/workbook/postmortem-culture/                                                                        |
| SRE book: Postmortem Culture                      | https://sre.google/sre-book/postmortem-culture/                                                                        |
| Atlassian Statuspage: Incident communication tips | https://support.atlassian.com/statuspage/docs/incident-communication-tips                                              |

## references/technique.md

| Title                                              | URL                                                                                                                                   |
| -------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------- |
| Google Cloud: Data incident response process       | https://docs.cloud.google.com/docs/security/incident-response                                                                         |
| PagerDuty: Severity levels                         | https://docs.pagerduty.com/ops-guides/incident-response-guide/severity-levels                                                         |
| SRE book: Managing Incidents                       | https://sre.google/sre-book/managing-incidents/                                                                                       |
| Microsoft Learn: Token theft playbook              | https://learn.microsoft.com/en-us/security/zero-trust/security-operations-playbook-token-theft                                        |
| RFC 3227                                           | https://www.rfc-editor.org/rfc/rfc3227.html                                                                                           |
| NIST SP 800-86                                     | https://csrc.nist.gov/pubs/sp/800/86/final                                                                                            |
| AWS Security Incident Response User Guide: Contain | https://docs.aws.amazon.com/security-ir/latest/userguide/contain.html                                                                 |
| GitHub Docs: Remediating a leaked secret           | https://docs.github.com/en/code-security/secret-scanning/working-with-secret-scanning-and-push-protection/remediating-a-leaked-secret |
| SRE workbook: Incident Response                    | https://sre.google/workbook/incident-response/                                                                                        |
| Protect your origin server (Cloudflare)            | https://developers.cloudflare.com/fundamentals/security/protect-your-origin-server/                                                   |
| Kubernetes: Security checklist                     | https://kubernetes.io/docs/concepts/security/security-checklist/                                                                      |
| NIST SP 800-61r3 publication page                  | https://csrc.nist.gov/pubs/sp/800/61/r3/final                                                                                         |
| NIST Incident Response project page                | https://csrc.nist.gov/projects/incident-response                                                                                      |
| NIST SP 800-61r3 PDF (Table 1)                     | https://nvlpubs.nist.gov/nistpubs/SpecialPublications/NIST.SP.800-61r3.pdf                                                            |
| NIST CSF 2.0 (CSWP 29)                             | https://nvlpubs.nist.gov/nistpubs/CSWP/NIST.CSWP.29.pdf                                                                               |
