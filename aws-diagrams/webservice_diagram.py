# diagram.py
from diagrams import Cluster, Diagram, Edge
from diagrams.aws.compute import (
    EC2,
    ECS,
    ElasticContainerServiceContainer,
    Fargate,
    Lambda,
)
from diagrams.aws.database import DDB, RDS
from diagrams.aws.engagement import SES
from diagrams.aws.management import Cloudwatch
from diagrams.aws.network import CF, ELB, APIGateway, Route53
from diagrams.aws.security import IAM, WAF, Cognito, Shield, WAFFilteringRule
from diagrams.aws.storage import S3
from diagrams.onprem.client import Client, Users
from diagrams.onprem.network import Internet

graph_attr = {
    "fontsize": "24",
}


with Diagram(
    "Mindhive 3.0 on Amazon Web Services",
    direction="TB",
    show=False,
    outformat="svg",
    graph_attr=graph_attr,
):

    users = Users("Users")

    with Cluster("AWS", direction="LR"):

        with Cluster("Front End Tier", direction="LR"):
            dns = Route53("DNS - Route 53")
            waf = WAF("Filtering - WAF")
            cloudfront = CF("Cloudfront")
            s3 = S3("S3")
            shield = Shield("AWS Shield")
            dns >> waf >> cloudfront << s3

        with Cluster("Back End Tier", direction="TB"):
            fargate = Fargate("Fargate")
            with Cluster("Autoscaling Group"):
                with Cluster("Availability Zone 1"):
                    with Cluster("EC2 Instance"):
                        container1 = ElasticContainerServiceContainer("container 1")
                        containern = ElasticContainerServiceContainer("container n")

    #users >> dns
    #cloudfront >> fargate
    #fargate >> [container1, containern]

# ELB("slb") >> EC2("web") >> RDS("userdb")
