# aws-sample-app

## General

* General explanation about the app:
    * TODO

* The exposed WEB API:
    * TODO
    * TODO 

* Architecture:
    * TODO

## Run the application in **local machine**

### Prerequisite installations:
* Install NodeJs - https://nodejs.org/en/download.
* Install Postgres - https://www.postgresql.org.

### Create the 'Postgres' database:
* Open the 'pgAdmin' app (part of the 'Postgres' installation).
* Go to: Databases -> right click -> Create -> DataBase, and create/validate existance of database with:
    ~~~
    * name: postgres.
    * port: 5432.
    * username: postgres.
    * password: postgres.
    ~~~

### Install, build and run the application:
* Go to root folder of the app (the folder where file 'package.json' located), and execute the following commands sequence:
    ~~~
    npm install
    npm run build
    npm run start
    ~~~

## Run the application in your **docker machine**

### Prerequisite installations:
* Install Docker engine (e.g. 'Docker Desktop for Windows' - https://hub.docker.com/editions/community/docker-ce-desktop-windows).

### Install, build and run the application:
* Go to root folder of the app (the folder where file 'docker-compose.yml' located), and execute the following command:
    ~~~
    docker-compose up --build
    ~~~
* Other options:  
    * Build the service, run it, and run automatic tests (all within your docker machine):
        ~~~
        docker-compose --file docker-compose.local.build.tests.yml up --build
        ~~~   
    * Fetch last version of the service from ECR, run it, and run automatic tests (all within your docker machine):
        ~~~
        docker-compose --file docker-compose.local.fetch.tests.yml up
        ~~~
    * Fetch last version of the service from ECR, run it (within your docker machine):
        ~~~
        docker-compose --file docker-compose.local.fetch.yml up
        ~~~
   
* See appendix below for some more useful Docker commands.

## Run the application in **cloud**

### Prerequisite installations/configurations:
* At AWS - create IAM user, and get correspond acess keys (this is a **user for operations of ECS/AWS/DOCKER CLI's in our batch file**):
    * More info in this issue - see pargraphs 'Create an IAM user' and 'Create a key pair', here: https://docs.aws.amazon.com/AmazonECS/latest/developerguide/get-set-up-for-amazon-ecs.html.
    * Open the WAS console, navigate to the 'IAM' section, and perform the folowing steps:
        * Create custom policy:
            * Go to 'Policies' -> 'Create Policy' -> 'JSON', and paste this JSON text:
                ~~~
                {
                    "Version": "2012-10-17",
                    "Statement": [
                        {
                            "Sid": "VisualEditor0",
                            "Effect": "Allow",
                            "Action": [
                                "cloudformation:*",
                                "iam:CreateRole",
                                "iam:AttachRolePolicy",
                                "logs:DeleteLogGroup",
                                "ec2:DescribeVpcs",
                                "ec2:DescribeSubnets",
                                "ec2:DescribeSecurityGroups",
                                "ec2:DescribeInternetGateways",
                                "ec2:DescribeRouteTables",
                                "ec2:DescribeAvailabilityZones",
                                "ec2:DescribeAccountAttributes",
                                "ec2:DeleteRouteTable",
                                "ec2:DeleteInternetGateway",
                                "ec2:DeleteRoute",
                                "ec2:DeleteVpc"
                            ],
                            "Resource": "*"
                        }
                    ]
                }
                ~~~
            * Click the 'Review policy' button, and at next page click the 'Create policy' bytton.
        * Go to 'Users' - > 'Add user', create new user, and attach to it 3 policies (they required for the AWS/ECS/DOCKER CLI comands we going to execute at 'set-cluster.bat'):
            * The costom policy (see previuos step).
            * The 'AmazonECS_FullAccess' policy.
            * The 'AmazonEC2ContainerRegistryFullAccess' policy.
        * Within detailes page of the new user, go to 'Security credentials' tab, create new Access Keys, and save/copy the 2 values (we will use them at next step).
* Configure our batch file:
    * Go to root folder of the app (the folder where file 'docker-compose.yml' located), open file 'set-cluster.bat', and set the Access Keys values (see previos step) in the 'AWS_ACCESS_KEY_ID' and 'AWS_SECRET_ACCESS_KEY' variables.

### Install, build and run the application:
* Execute our batch file:
    * Go to root folder of the app (the folder where file 'docker-compose.yml' located), and execute the following batch file:
        ~~~
        set-cluster.bat
        ~~~
    * Those are the main actions which performed by our batch file:
        * Creating AWS reposetory.
        * Build docker image, and push it into our repository.
        * Creating an AWS cluster with a fargate task.
        * Creating a GitHub workflow, to soppurt CI/CD.
    * More details about the sequence which performed in this batch file - see comments within it.
*  Optional - setup a CI/CD infra:
    * We can configure GitHub to execute automatic workflow (which already generated by our batch file).
      With this workflow, an automatic build and push of docker image into the AWS reposetory will be executed on each GitHub push (including run of the automatic tests).
    * Open this page: https://medium.com/javascript-in-plain-english/deploy-your-node-app-to-aws-container-service-via-github-actions-build-a-pipeline-c114adeb8903.
    * Perform the operations which listed at the following chapters (only!):
        * 'Creating an IAM user for GitHub Actions'.
        * 'Setting up GitHub Actions'.
            * Abort this chapter while you arrive to **'Create new workflow'** section (we already have costomise version of it, located here: **'.github/workflows/deploy-to-aws.yml'**).
        * 'Testing the outcome'.
    * Testing the GitHub workflow:
        * Open the GitHub reposetory page, then go to 'Actions' -> 'Workflows' -> 'Deploy to Amazon ECS', and test the workflow manually:
            * Select (click) it, then click bottun 'Run workflow' which located at right side of the page.
            * Validate that entire workflow works fine (including running of automatic tests)  
* Discovere available services, and their base URLs:
    * Go to root folder of the app (the folder where file 'package.json' located), and execute the following command:
        ~~~
        ecs-cli compose --project-name <cluster-name> service ps --cluster-config <cluster-name> --ecs-profile <cluster-name>
        ~~~
    * E.g:
        ~~~
        ecs-cli compose --project-name aws-sample-app service ps --cluster-config aws-sample-app --ecs-profile aws-sample-app
        ~~~

## Testing the application
Note: this step should done while the **application already runs** (in **docker machine**, in **local machine** or in **cloud** (see explanation about those 3 options above)).

### Via browser
* Open browser, navigate to 'http://<base url>:<port>/<path>', and validate that expected result is recieved.
* Base url:
    * While application runs in **local machine** or **docker machine**: 'localhost'.
    * While application runs in **cloud**: see step **'Discovere available services, and their base URLs'** above.
* Port: as defined in the 'EXPOSE' at dockerfile.
* Path: one of the 'GET' pathes which defined in the application's routers.

### Via automatic tests
* Notes: 
    * Current testing code clears the DB at each run of the tests.
    * If application runs in **cloud** - need to set the 'serviceHost' variable (at file 'tests\spec.ts'), accurding base url of the required service, see step **'Discovere available services, and their base URLs'** above.
* Run the automatic tests:
    * Go to root folder of the app (the folder where file 'package.json' located), and execute the following commands sequence (install/build commands - just if not executed yet, or if 'serviceHost' was changed, they require because they install and build also the testing code):
        ~~~
        npm install
        npm run build
        npm run test
        ~~~
* It is possible to invoke the automatic tests via the docker compose command, in the folowing cases:
    * Application runs in **docker machine**: see 1st and 2nd options, in **'Other options'** (under 'Run the application in your docker machine')  above.
    * Application runs in **cloud**:
        * Via the GitHub workflow: see step **'Testing the GitHub workflow'** above.
        * TODO


## Appendix - other useful Docker commands

#### Build the docker image:
~~~
docker build -t aws-sample-app .
~~~
#### Run the docker container:
~~~
docker run -it -p 8080:8080 -P aws-sample-app
~~~
#### Stop all running docker containers:
~~~
docker stop $(docker ps -q)
~~~
#### Remove all docker containers:
~~~
docker rm $(docker ps -a -q)
~~~