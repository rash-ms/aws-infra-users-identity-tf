# {
#     "policies": {
#         "data-eng-DEV": {
#             "full_access_policy": {
#                 "Version": "2012-10-17",
#                 "Statement": [
#                     {
#                         "Effect": "Allow",
#                         "Action": "*",
#                         "Resource": "*"
#                     }
#                 ]
#             }
#         },
#         "data-eng-PROD": {
#             "readonly_policy": {
#                 "Version": "2012-10-17",
#                 "Statement": [
#                     {
#                         "Effect": "Allow",
#                         "Action": [
#                             "ec2:Describe*",
#                             "s3:Get*",
#                             "s3:List*",
#                             "rds:Describe*",
#                             "iam:Get*",
#                             "iam:List*",
#                             "cloudwatch:Get*",
#                             "cloudwatch:List*",
#                             "cloudwatch:Describe*"
#                         ],
#                         "Resource": "*"
#                     }
#                 ]
#             }
#         }
#     },
#     "groups": {
#         "data-eng-DEV": "9458f408-4081-70c3-fc7a-f20693eaa538",
#         "data-eng-PROD": "a4a8d458-70a1-708c-a093-cd7efca8f33f"
#     }
# }
