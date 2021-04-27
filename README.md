# aws-sample-app

## General

* General explanation about the app:
    * TODO

* The exposed WEB API:
    * TODO
    * TODO 

* Architecture:
    * TODO
* Development environment:
  * Most of the instructions at this document finally use '*.bat' files, hence, current instructions require developer to work at Windows systems.
* Run environments: as will be explained at instructions below, you can run the application in 3 different environments:
    * **Local Machine** (for develop/test in single service level)
    * **Docker Machine** (for develop/test in entire app level)
    * **Cloud** (the final environment, develop/test/consume in entire app level, with all benefits of cloud)

## Run the application in **local machine**

### Prerequisite installations:
* Install NodeJs: https://nodejs.org/en/download.
* Install Postgres: https://www.postgresql.org.
* Install the ECS CLI: https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ECS_CLI_installation.html (at step 2 - follow instruction for installing 'Gpg4win', or go directly to this download page: https://gpg4win.org/thanks-for-download.html).
* Install the AWS CLI: https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2-windows.htmlwas.

### Create the 'Postgres' database:
* Open the 'pgAdmin' app (part of the 'Postgres' installation).
* Go to: Databases -> right click -> Create -> DataBase, and create/validate existence of database with:
    ~~~
    * name: postgres.
    * port: 5432.
    * username: postgres.
    * password: postgres.
    ~~~

### Install, build and run the application:
* Go to root folder at each of the app services (the folders where file 'package.json' located), and within each of them execute the following commands sequence:
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
* At AWS - create IAM user, and get correspond access keys (this is a **user for operations of ECS/AWS/DOCKER CLI's in our batch file**):
    * Open the AWS console, navigate to the 'IAM' section, and perform the following steps:
        * Create custom policy (required for executing of our AWS/ECS/DOCKER CLI commands):
            * Go to 'Policies' -> 'Create Policy', and create:
              * Police name: your choice (e.g. 'AdminPolicy1').
              * Go to 'JSON' tab, and paste this JSON text:
                ~~~
                {
                    "Version": "2012-10-17",
                    "Statement": [
                        {
                            "Sid": "VisualEditor0",
                            "Effect": "Allow",
                            "Action": [
                                "cloudformation:*",
                                "iam:DeleteRole",
                                "iam:CreateRole",
                                "iam:PassRole",
                                "iam:AttachRolePolicy",
                                "iam:CreateServiceLinkedRole",
                                "logs:CreateLogGroup",
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
                                "ec2:DeleteVpc",
                                "ecs:CreateCluster",
                                "ecs:DescribeServices",
                                "ecs:DeleteService",
                                "ecs:CreateService",
                                "ecs:UpdateService",
                                "ecs:RegisterTaskDefinition",
                                "ecs:DescribeTaskDefinition",
                                "ecs:ListAccountSettings",
                                "ecs:ListTasks",
                                "ecs:DescribeClusters",
                                "ecs:DeleteCluster",
                                "ecs:DescribeTasks"                                              
                            ],
                            "Resource": "*"
                        }
                    ]
                }
                ~~~
            * Click next few times, and finally click the 'Create policy' bytton.
        * Create IAM user (that able to execute of our AWS/ECS/DOCKER CLI comands):
          * Go to 'Users' -> 'Add user':
            * At 1st page:
              * User name: your choice (e.g. 'admin1').
              * Access type: 'Programmatic access'.
            * At 'Permissions' page:
              * Go to 'Set permissions' -> 'Attach existing policies directly', and select 3 policies (they required for the AWS/ECS/DOCKER CLI commands we going to execute at 'set-cluster.bat'):
              * The custom policy (see previous step).
              * The 'AmazonECSFullAccess' policy.
              * The 'AmazonEC2ContainerRegistryFullAccess' policy.
            * Click next few times, until the 'Summary' page.
            * Within the 'Summary' page, go to 'Security credentials' tab, create new Access Keys, and save/copy the 2 values (we will use them at next step).
        * More info in this issue - see paragraphs 'Create an IAM user' and 'Create a key pair', here: https://docs.aws.amazon.com/AmazonECS/latest/developerguide/get-set-up-for-amazon-ecs.html.
* Configure our 'BAT' file:
    * Go to 'dev-ops' folder of the app, open file 'set-cluster.bat', and set the Access Keys values (see previous step) in the 'AWS_ACCESS_KEY_ID' and 'AWS_SECRET_ACCESS_KEY' variables.
* Configure our 'YML' files:
    * Get your Account Id:
        * At AWS console - click the account item (at upper-right corner of main page).
        * Copy the 'Account Id'.
    * Replace all occurrences of 'ACOUNT_ID' (within yml files, at root folder, and at '.github\workflows' sub folder) with the found Account Id.
 
### Install, build and run the application:
* Execute our batch file:
    * Go to 'dev-ops' folder of the app, and execute the following batch file:
        ~~~
        set-cluster.bat
        ~~~
    * Those are the main actions which performed by this batch file:
        * Create AWS repository.
        * Build docker image, and push it into our repository.
        * Create an AWS cluster with a fargate task.
        * Create a GitHub workflow, to support CI/CD.
    * More details about the sequence which performed in this batch file - see comments within it.
*  Optional - setup a CI/CD infra:
    * We can configure GitHub to execute automatic workflow (which already generated by our batch file).
      With this workflow, an automatic build and push of docker image into the AWS repository will be executed on each GitHub push (including run of the automatic tests).
    * Open this page: https://medium.com/javascript-in-plain-english/deploy-your-node-app-to-aws-container-service-via-github-actions-build-a-pipeline-c114adeb8903.
    * Perform the operations which listed at the following chapters (only!):
        * 'Creating an IAM user for GitHub Actions'.
        * 'Setting up GitHub Actions'.
            * Abort this chapter while you arrive to **'Create new workflow'** section (we already have customized version of it, located here: **'.github/workflows/deploy-to-aws.yml'**).
        * 'Testing the outcome'.
    * Testing the GitHub workflow:
        * Open the GitHub repository page, then go to 'Actions' -> 'Workflows' -> 'Deploy to Amazon ECS', and test the workflow manually:
            * Select (click) it, then click button 'Run workflow' which located at right side of the page.
            * Validate that entire workflow works fine (including running of automatic tests)  
* Discover available services, and their base URLs:
    * Go to root folder at each of the app services (the folders where file 'package.json' located), and within each of them execute the following command:
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
* Open browser, navigate to `http://<base url>:<port>/<path>` (e.g. http://localhost/api/entity1s), and validate that expected result is received.
* Values:
    * `<base url>`:
        * While application runs in **local machine** or **docker machine**: 'localhost'.
        * While application runs in **cloud**: see step **'Discover available services, and their base URLs'** above.
    * `<port>`: as defined in the 'EXPOSE' at dockerfile.
    * `<path>`: one of the 'GET' paths which defined in the application's routers.

### Via automatic tests
* Notes: 
    * Current testing code clears the DB at each run of the tests.
    * If application runs in **cloud** - need to set the 'serviceHost' variable (at file 'tests\spec.ts'), according base url of the required service, see step **'Discover available services, and their base URLs'** above.
* Run the automatic tests:
    * Go to root folder of the app (the folder where file 'package.json' located), and execute the following commands sequence (install/build commands - just if not executed yet, or if 'serviceHost' was changed, they require because they install and build also the testing code):
        ~~~
        npm install
        npm run build
        npm run test
        ~~~
* It is possible to invoke the automatic tests via the docker compose command, in the following cases:
    * Application runs in **docker machine**: see 1st and 2nd options, in **'Other options'** (under 'Run the application in your docker machine') above.
    * Application runs in **cloud**:
        * Via the GitHub workflow: see step **'Testing the GitHub workflow'** above.
        * TODO


## Appendix - other useful Docker commands

#### Build the docker image:
~~~
docker build -t aws-sample-app.
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
