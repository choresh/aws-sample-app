@ECHO OFF

REM ================= Stage #1 - Secret Keys - start ==============================
REM * In this stage we store credintials required for the AWS/ECS CLI's.
REM * More about those Access Keys - see the following chapters in 'README.md' file of this package:
REM   * 'At AWS - create IAM user, and get correspond access keys'.
REM   * 'Configure our batch file'.
REM * IMPORTENT:
REM   * Never expose those Access Keys!!!
REM   * Use them only at private environment (e.g. your local machine)!!!
REM   * If they became public - be sure that some automatic scanners will detect them, and someone will try to use your credentials in order to consume AWS resources on you budget!!!
REM   * Such an exposure may happened by mistake, e.g. if you push this file to public GitHub, while those values defined in it!!!
SET AWS_ACCESS_KEY_ID=
SET AWS_SECRET_ACCESS_KEY=
REM
REM ================= Stage #1 - Secret Keys - end ==============================


REM ================= Stage #2 - Settings - start ==============================
REM In this stage we define all required settings varaibles.

REM Define per-app values.
SET APP_NAME=aws-sample-app
SET REGION=us-east-2
SET PORT=8080

REM Define names for folders and files.
SET CURR_FOLDER=%~dp0
SET WORKING_FOLDER=%CURR_FOLDER%..
SET TEMP_FOLDER_NAME=temp
SET DEV_OPS_FOLDER=dev-ops
SET TEMP_FOLDER=%DEV_OPS_FOLDER%/%TEMP_FOLDER_NAME%
SET AWS_FOLDER=%DEV_OPS_FOLDER%/aws
SET DOCKER_COMPOSE_FILE_PATH=docker-compose.cloud.fetch.yml
SET TEMP_FILE_PATH=%TEMP_FOLDER%/temp.txt
SET ROLE_POLICY_FILE_PATH=%AWS_FOLDER%/task-execution-assume-role.json
SET ECS_PARAMS_TEMPLATE_FILE_PATH=%AWS_FOLDER%/ecs-params-template.yml
SET ECS_PARAMS_GENERATED_FILE_PATH=%TEMP_FOLDER%/ecs-params.yml

SET GREEN=92
SET ORANGE=93
SET RED=91

REM Create the 'temp' folder (if not exists).

CD %CURR_FOLDER%
MD %TEMP_FOLDER_NAME% 2> NUL

REM Move to working folder
CD %WORKING_FOLDER%

REM ================= Stage #2 - Settings - end ==============================


REM ================= Stage #3 - Resources Clearing - start ==============================
REM In this stage we clear the most importent AWS resources (if exists).

SET MSG=* Clear all resources (if exists) - started (may take few minutes...)
ECHO [201;%GREEN%m%MSG%[0m
ecs-cli compose --project-name %APP_NAME% service down --cluster-config %APP_NAME% --ecs-profile %APP_NAME% > NUL 2>&1
ecs-cli down --cluster-config %APP_NAME% --ecs-profile %APP_NAME% --force > NUL 2>&1
aws logs delete-log-group --log-group-name %APP_NAME% --region %REGION% > NUL 2>&1
SET MSG=* Clear all resources (if exists) - ended
ECHO [201;%GREEN%m%MSG%[0m

REM ================= Stage #3 - Resources Clearing - end ==============================


REM ================= Stage #4 - Create ECS CLI Profile - start ==============================
REM In this stage we build docker image, and push it to our reposetory.

SET MSG=* Create ECS CLI profile (if not exists) - started
ECHO [201;%GREEN%m%MSG%[0m
ecs-cli configure profile --access-key %AWS_ACCESS_KEY_ID% --secret-key %AWS_SECRET_ACCESS_KEY% --profile-name %APP_NAME% > NUL 2>1
IF NOT %errorlevel% == 0 (
    SET ERR_MSG=* Create ECS CLI profile - failed, error code: %errorlevel%
    GOTO END
)
SET MSG=* Create ECS CLI profile (if not exists) - ended
ECHO [201;%GREEN%m%MSG%[0m

REM ================= Stage #4 - Create ECS CLI Profile - end ==============================


REM ================= Stage #5 - AWS Clustr Creation - start ==============================
REM * In this stage we create an AWS cluster with a fargate task. 
REM * More info - see https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs-cli-tutorial-ec2.html,
REM   and its sub chapters:
REM     * 'Installing the Amazon ECS CLI'.
REM     * 'Configuring the Amazon ECS CLI'.
REM     * 'Tutorial: Creating a Cluster with a Fargate Task Using the Amazon ECS CLI'.

SET MSG=* Create role (if not exists) - started
ECHO [201;%GREEN%m%MSG%[0m
aws iam --region %REGION% create-role --role-name %APP_NAME% --assume-role-policy-document file://%ROLE_POLICY_FILE_PATH% > NUL 2>&1
IF NOT %errorlevel% == 0 (
    IF NOT %errorlevel% == 254 (
        SET ERR_MSG=* Create role - failed, error code: %errorlevel%
        GOTO END
    )
)
SET MSG=* Create role (if not exists) - ended
ECHO [201;%GREEN%m%MSG%[0m

SET MSG=* Attch role policy - started
ECHO [201;%GREEN%m%MSG%[0m
aws iam --region %REGION% attach-role-policy --role-name %APP_NAME% --policy-arn arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy > NUL
IF NOT %errorlevel% == 0 (
    SET ERR_MSG=* Attch role policy - failed, error code: %errorlevel%
    GOTO END
)
SET MSG=* Attch role policy - ended
ECHO [201;%GREEN%m%MSG%[0m

SET MSG=* Create cluster configuration - started
ECHO [201;%GREEN%m%MSG%[0m
ecs-cli configure --cluster %APP_NAME% --default-launch-type FARGATE --config-name %APP_NAME% --region %REGION% > NUL
IF NOT %errorlevel% == 0 (
    SET ERR_MSG=* Create cluster configuration - failed, error code: %errorlevel%
    GOTO END
)
SET MSG=* Create cluster configuration - ended
ECHO [201;%GREEN%m%MSG%[0m

SET MSG=* Create cluster - started (may take few minutes...)
ECHO [201;%GREEN%m%MSG%[0m
ECHO =====================================================================
ecs-cli up --cluster-config %APP_NAME% --ecs-profile %APP_NAME% --force
ECHO =====================================================================
IF NOT %errorlevel% == 0 (
    SET ERR_MSG=* Create cluster - failed, error code: %errorlevel%
    GOTO END
)
SET MSG=* Create cluster - ended
ECHO [201;%GREEN%m%MSG%[0m

SET MSG=* Get VPC info - started
ECHO [201;%GREEN%m%MSG%[0m
aws cloudformation list-stack-resources --stack-name amazon-ecs-cli-setup-aws-sample-app --region %REGION% --query StackResourceSummaries[?(@.LogicalResourceId=='Vpc')].PhysicalResourceId > %TEMP_FILE_PATH%
IF NOT %errorlevel% == 0 (
    SET ERR_MSG=* Get VPC info - failed, error code: %errorlevel%
    GOTO END
)
SET MSG=* Get VPC info - ended
ECHO [201;%GREEN%m%MSG%[0m

REM * Get value of 2nd line at file %TEMP_FILE_PATH%.
REM * Strip redundent parts at start/end of the found string.
SET MSG=* Fetch VPC info - started
ECHO [201;%GREEN%m%MSG%[0m
SET FOUND_VPC_ID_LINE=
FOR /F "skip=1 delims=" %%i IN (%TEMP_FILE_PATH%) DO IF NOT DEFINED FOUND_VPC_ID_LINE SET FOUND_VPC_ID_LINE=%%i
SET FOUND_VPC_ID=%FOUND_VPC_ID_LINE:~5,21%
SET MSG=* Found VPC Id: %FOUND_VPC_ID%
ECHO [201;%GREEN%m%MSG%[0m
SET MSG=* Fetch VPC info - ended
ECHO [201;%GREEN%m%MSG%[0m

SET MSG=* Get Subnets info - started
ECHO [201;%GREEN%m%MSG%[0m
aws ec2 describe-subnets --filters "Name=vpc-id,Values=%FOUND_VPC_ID%" --region %REGION% --query Subnets[*].SubnetId > %TEMP_FILE_PATH%
IF NOT %errorlevel% == 0 (
    SET ERR_MSG=* Get Subnets info - failed, error code: %errorlevel%
    GOTO END
)
SET MSG=* Get Subnets info - ended
ECHO [201;%GREEN%m%MSG%[0m

SET MSG=* Fetch Subnets info - started
ECHO [201;%GREEN%m%MSG%[0m

REM * Get value of **2ND** line at file %TEMP_FILE_PATH%.
REM * Strip redundent parts at start/end of the found string.
SET FOUND_SUBNET_1_LINE=
FOR /F "skip=1 delims=" %%i IN (%TEMP_FILE_PATH%) DO IF NOT DEFINED FOUND_SUBNET_1_LINE SET FOUND_SUBNET_1_LINE=%%i
SET FOUND_SUBNET_1=%FOUND_SUBNET_1_LINE:~5,24%%
SET MSG=* Found Subnet 1: %FOUND_SUBNET_1%
ECHO [201;%GREEN%m%MSG%[0m

REM * Get value of **3RD** line at file %TEMP_FILE_PATH%.
REM * Strip redundent parts at start/end of the found string.
SET FOUND_SUBNET_2_LINE=
FOR /F "skip=2 delims=" %%i IN (%TEMP_FILE_PATH%) DO IF NOT DEFINED FOUND_SUBNET_2_LINE SET FOUND_SUBNET_2_LINE=%%i
SET FOUND_SUBNET_2=%FOUND_SUBNET_2_LINE:~5,24%%
SET MSG=* Found Subnet 2: %FOUND_SUBNET_2%
ECHO [201;%GREEN%m%MSG%[0m

SET MSG=* Fetch Subnets info - ended
ECHO [201;%GREEN%m%MSG%[0m

SET MSG=* Get the default security group ID for the VPC - started
ECHO [201;%GREEN%m%MSG%[0m
aws ec2 describe-security-groups --filters Name=vpc-id,Values=%FOUND_VPC_ID% --region %REGION% --query SecurityGroups[0].GroupId > %TEMP_FILE_PATH%
IF NOT %errorlevel% == 0 (
    SET ERR_MSG=* Get the default security group ID for the VPC - failed, error code: %errorlevel%
    GOTO END
)
SET MSG=* Get the default security group ID for the VPC - ended
ECHO [201;%GREEN%m%MSG%[0m

SET MSG=* Fetch SG info - started
ECHO [201;%GREEN%m%MSG%[0m
SET /P FOUND_SG_ID= < %TEMP_FILE_PATH%
SET MSG=* Found SG Id: %FOUND_SG_ID%
ECHO [201;%GREEN%m%MSG%[0m
SET MSG=* Fetch SG info - ended
ECHO [201;%GREEN%m%MSG%[0m

SET MSG=* Add a security group rule to allow inbound access on port %PORT% - started
ECHO [201;%GREEN%m%MSG%[0m
aws ec2 authorize-security-group-ingress --group-id %FOUND_SG_ID% --protocol tcp --port %PORT% --cidr 0.0.0.0/0 --region %REGION% > NUL 2>&1
IF NOT %errorlevel% == 0 (
    IF NOT %errorlevel% == 254 (
        SET ERR_MSG=* Add a security group rule to allow inbound access on port %PORT% - failed, error code: %errorlevel%
        GOTO END
    )
)
SET MSG=* Add a security group rule to allow inbound access on port %PORT% - ended
ECHO [201;%GREEN%m%MSG%[0m

SET MSG=* Prepare ECS params - started
ECHO [201;%GREEN%m%MSG%[0m
POWERSHELL -Command "(gc '%ECS_PARAMS_TEMPLATE_FILE_PATH%') -replace '#APP_NAME#', '%APP_NAME%' | Out-File -encoding ASCII '%ECS_PARAMS_GENERATED_FILE_PATH%'"
POWERSHELL -Command "(gc '%ECS_PARAMS_GENERATED_FILE_PATH%') -replace '#SUBNET_1#', '%FOUND_SUBNET_1%'  | Out-File -encoding ASCII '%ECS_PARAMS_GENERATED_FILE_PATH%'"
POWERSHELL -Command "(gc '%ECS_PARAMS_GENERATED_FILE_PATH%') -replace '#SUBNET_2#', '%FOUND_SUBNET_2%'  | Out-File -encoding ASCII '%ECS_PARAMS_GENERATED_FILE_PATH%'"
POWERSHELL -Command "(gc '%ECS_PARAMS_GENERATED_FILE_PATH%') -replace '#SG_ID#', '%FOUND_SG_ID%' | Out-File -encoding ASCII '%ECS_PARAMS_GENERATED_FILE_PATH%'"
SET MSG=* Prepare ECS params - ended
ECHO [201;%GREEN%m%MSG%[0m

REM ================= Stage #5 - AWS Clustr Creation - end ==============================


REM ================= Stage #6 - Get GitHub Workflow Params - start ==============================
REM In this stage we fetch the 'task definition' - parameter which required for creation of GitHub workflow.

SET MSG=* Get Task Definition info - started
ECHO [201;%GREEN%m%MSG%[0m
aws ecs describe-services --services %APP_NAME% --region %REGION% --cluster %APP_NAME% --query services[0].taskDefinition > %TEMP_FILE_PATH%
IF NOT %errorlevel% == 0 (
    SET ERR_MSG=* Get Task Definition info - failed, error code: %errorlevel%
    GOTO END
)
SET MSG=* Get Task Definition info - ended
ECHO [201;%GREEN%m%MSG%[0m

SET MSG=* Fetch Task Definition info - started
ECHO [201;%GREEN%m%MSG%[0m
SET /P FOUND_TASK_DEFINITION= < %TEMP_FILE_PATH%
FOR /f "tokens=1,2 delims=/" %%a IN (%FOUND_TASK_DEFINITION%) DO (
	SET TASK_DEFINITION=%%b
)
SET MSG=* Found Task Definition: %TASK_DEFINITION%
ECHO [201;%GREEN%m%MSG%[0m
SET MSG=* Fetch Task Definition info - ended
ECHO [201;%GREEN%m%MSG%[0m

REM ================= Stage #6 - Get GitHub Workflow Params - end ==============================


REM ================= Stage #7 - Handle Operations in Service Level - start ==============================

REM Move to current folder
CD %CURR_FOLDER%

FOR /D %%i IN (../services/*) DO (
    CALL set-service %%i %APP_NAME% %REGION% %TEMP_FILE_PATH% %TASK_DEFINITION% "%WORKING_FOLDER%" %GREEN% %ORANGE% %RED% "%CURR_FOLDER%"
)

REM Move to working folder
CD %WORKING_FOLDER%

REM ================= Stage #7 - Handle Operations in Service Level - end ==============================


REM ================= Stage #8 - Create the ECS Service - start ==============================

SET MSG=* Creates ECS service from the compose file, and run it - started (may take few minutes...)
ECHO [201;%GREEN%m%MSG%[0m
ECHO =====================================================================
ecs-cli compose --ecs-params %ECS_PARAMS_GENERATED_FILE_PATH% --project-name %APP_NAME% --file %DOCKER_COMPOSE_FILE_PATH% service up --create-log-groups --cluster-config %APP_NAME% --ecs-profile %APP_NAME%
ECHO =====================================================================
IF NOT %errorlevel% == 0 (
    SET ERR_MSG=* Creates ECS service from the compose file, and run it - failed, error code: %errorlevel%
    GOTO END
)
SET MSG=* Creates ECS service from the compose file, and run it - ended
ECHO [201;%GREEN%m%MSG%[0m

SET MSG=* Display info about cluster's running containers - started
ECHO [201;%GREEN%m%MSG%[0m
ECHO =====================================================================
ecs-cli compose --project-name %APP_NAME% --file %DOCKER_COMPOSE_FILE_PATH% service ps --cluster-config %APP_NAME% --ecs-profile %APP_NAME%
ECHO =====================================================================
IF NOT %errorlevel% == 0 (
    SET ERR_MSG=* Display info about cluster's running containers - failed, error code: %errorlevel%
    GOTO END
)
SET MSG=* Display info about cluster's running containers - ended
ECHO [201;%GREEN%m%MSG%[0m

SET MSG=* Scale the tasks on the cluster - started (may take few minutes...)
ECHO [201;%GREEN%m%MSG%[0m
ECHO =====================================================================
ecs-cli compose --project-name %APP_NAME% service scale 2 --cluster-config %APP_NAME% --ecs-profile %APP_NAME%
ECHO =====================================================================
IF NOT %errorlevel% == 0 (
    SET ERR_MSG=* Scale the tasks on the cluster - failed, error code: %errorlevel%
    GOTO END
)
SET MSG=* Scale the tasks on the cluster - ended
ECHO [201;%GREEN%m%MSG%[0m

SET MSG=* Display info about cluster's running containers, after scale - started
ECHO [201;%GREEN%m%MSG%[0m
ECHO =====================================================================
ecs-cli compose --project-name %APP_NAME% service ps --cluster-config %APP_NAME% --ecs-profile %APP_NAME%
ECHO =====================================================================
IF NOT %errorlevel% == 0 (
    SET ERR_MSG=* Display info about cluster's running containers, after scale - failed, error code: %errorlevel%
    GOTO END
)
SET MSG=* Display info about cluster's running containers, after scale - ended
ECHO [201;%GREEN%m%MSG%[0m

REM ================= Stage #8 - Create the ECS Service - end ==============================


REM ================= Stage #9 - Termination - start ==============================

SET MSG=* To newly view available services, and thire URLs - run the folowing command (within the project root folder):
ECHO [201;%GREEN%m%MSG%[0m
SET MSG=    ecs-cli compose --project-name %APP_NAME% service ps --cluster-config %APP_NAME% --ecs-profile %APP_NAME%
ECHO [201;%ORANGE%m%MSG%[0m

:END

REM Delete the 'temp' folder.
CD %CURR_FOLDER%
RMDIR /S /Q %TEMP_FOLDER_NAME%
CD ..

IF DEFINED ERR_MSG (
    ECHO [201;%RED%m%ERR_MSG%[0m
)

SET MSG=* The entire sequence has ended
ECHO [201;%GREEN%m%MSG%[0m

PAUSE
@ECHO ON

REM ================= Stage #9 - Termination - end ==============================
