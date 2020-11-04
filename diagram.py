from diagrams import Cluster, Diagram, Edge
from diagrams.aws.compute import ECR, ECS, Compute
from diagrams.aws.devtools import Codepipeline
from diagrams.aws.management import Cloudformation
from diagrams.onprem.client import User
from diagrams.onprem.vcs import Github


def red(color="firebrick", style="solid"):
    return Edge(color=color, style=style)


with Diagram("ECS Service Pipeline", filename="diagram", outformat="png"):

    github = Github("GitHub Actions\nImage Build")

    with Cluster("Management AWS Account"):

        with Cluster("ECR-Source Module"):
            ecr = ECR("ECR Repository")

        with Cluster("Pipeline Module"):
            pipeline_source = Codepipeline("ECR Source")
            pipeline_dev = Codepipeline("Deploy to\nDev")
            pipeline_approval_staging = User("Manual\nApproval")
            pipeline_staging = Codepipeline("Deploy to\nStaging")
            pipeline_approval_prod = User("Manual\nApproval")
            pipeline_prod = Codepipeline("Deploy to\nProd")

    with Cluster("Development AWS Account"):
        with Cluster("Service Module"):
            cfn_dev = Cloudformation("CloudFormation\nStack")
            with Cluster("CloudFormation Resources"):
                ecs_dev = ECS("ECS Service")
                task_dev = Compute("ECS Tasks")

    with Cluster("Staging AWS Account"):
        with Cluster("Service Module"):
            cfn_staging = Cloudformation("CloudFormation\nStack")
            with Cluster("CloudFormation Resources"):
                ecs_staging = ECS("ECS Service")
                task_staging = Compute("ECS Tasks")

    with Cluster("Production AWS Account"):
        with Cluster("Service Module"):
            cfn_prod = Cloudformation("CloudFormation\nStack")
            with Cluster("CloudFormation Resources"):
                ecs_prod = ECS("ECS Service")
                task_prod = Compute("ECS Tasks")

    github >> ecr >> pipeline_source >> pipeline_dev >> pipeline_approval_staging >> pipeline_staging >> pipeline_approval_prod >> pipeline_prod
    pipeline_dev >> red() >> cfn_dev >> red() >> ecs_dev >> red() >> task_dev
    task_staging << red() << ecs_staging << red() << cfn_staging << red() << pipeline_staging
    pipeline_prod >> red() >> cfn_prod >> red() >> ecs_prod >> red() >> task_prod
