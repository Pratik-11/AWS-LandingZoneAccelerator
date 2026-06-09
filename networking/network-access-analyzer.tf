## Deferred for now
/*
resource "aws_ec2_network_insights_access_scope" "prod_isolation" {
  provider = aws.prod_use1
  
  match_paths {
    source { resource_statement { resource_types = ["AWS::EC2::InternetGateway"] } }
    destination { resource_statement { resource_types = ["AWS::EC2::Instance"] } }
  }
  
  tags = { Name = "Verify-No-Internet-To-Prod" }
}
*/