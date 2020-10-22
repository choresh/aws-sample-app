@ECHO OFF

REM ================= Stage #1 - Settings - start ==============================
REM In this stage we define all required settings varaibles.

REM Store input parameters.
SET SERVICE_NAME=%1
SET APP_NAME=%2
SET REGION=%3
SET TEMP_FILE_PATH=%4
SET TASK_DEFINITION=%5
SET WORKING_FOLDER=%6
SET GREEN=%7
SET ORANGE=%8
SET RED=%9

SET MSG=* Handling of service '%SERVICE_NAME%' - started
ECHO [201;%ORANGE%m%MSG%[0m

REM Define names for folders and files.
SET SERVICES_FOLDER="services"
SET DEV_OPS_FOLDER=dev-ops
SET GITHUB_FOLDER=%DEV_OPS_FOLDER%/github
SET GITHUB_WORKFLOWS_FOLDER=.github/workflows
SET GITHUB_WORKFLOWS_FILE_NAME_SUFFIX=deploy-to-aws.yml
SET GITHUB_PARAMS_TEMPLATE_FILE_PATH=%GITHUB_FOLDER%/deploy-to-aws-template.yml
SET GITHUB_PARAMS_GENERATED_FILE_PATH=%GITHUB_WORKFLOWS_FOLDER%/%SERVICE_NAME%-%GITHUB_WORKFLOWS_FILE_NAME_SUFFIX%

REM Move to working folder
CD %WORKING_FOLDER%

REM ================= Stage #1 - Settings - end ==============================


REM ================= Stage #2 - Resources Clearing - start ==============================
REM In this stage we clear the most importent AWS resources (if exists).

SET MSG=* Clear all resources (if exists) - started (may take few minutes...)
ECHO [201;%ORANGE%m%MSG%[0m
aws ecr delete-repository --repository-name %SERVICE_NAME% --region %REGION% --force > NUL 2>&1
SET MSG=* Clear all resources (if exists) - ended
ECHO [201;%ORANGE%m%MSG%[0m

REM ================= Stage #2 - Resources Clearing - end ==============================


REM ================= Stage #3 - AWS Repository Creation - start ==============================
REM In this stage we create AWS repository (if not exists yet).

SET MSG=* Get Repository info - started
ECHO [201;%ORANGE%m%MSG%[0m
aws ecr describe-repositories --repository-names %SERVICE_NAME% --region %REGION% --query repositories[0].repositoryUri > %TEMP_FILE_PATH% 2> NUL
SET MSG=* Get Repository info - ended
ECHO [201;%ORANGE%m%MSG%[0m

IF %errorlevel% == 0 (
    GOTO REPOSITORY_EXISTS
)

SET MSG=* Create repository - started
ECHO [201;%ORANGE%m%MSG%[0m
aws ecr create-repository --repository-name %SERVICE_NAME% --region %REGION% --query repository.repositoryUri > %TEMP_FILE_PATH%
IF NOT %errorlevel% == 0 (
    SET ERR_MSG=* Create repository - failed, error code: %errorlevel%
    GOTO END
)
SET MSG=* Create repository - ended
ECHO [201;%ORANGE%m%MSG%[0m

:REPOSITORY_EXISTS

SET MSG=* Fetch Repository info - started
ECHO [201;%ORANGE%m%MSG%[0m
SET /P FOUND_REPOSITORY_URI= < %TEMP_FILE_PATH%
SET MSG=* Found Repository Uri: %FOUND_REPOSITORY_URI%
ECHO [201;%ORANGE%m%MSG%[0m
SET MSG=* Fetch Repository info - ended
ECHO [201;%ORANGE%m%MSG%[0m

SET MSG=* Authenticate Docker to an Amazon ECR reposetory - started
ECHO [201;%ORANGE%m%MSG%[0m
aws ecr get-login-password --region %REGION% | docker login --username AWS --password-stdin %FOUND_REPOSITORY_URI% > NUL
IF NOT %errorlevel% == 0 (
  SET ERR_MSG=* Authenticate Docker to an Amazon ECR reposetory - failed, error code: %errorlevel%
  GOTO END
)
SET MSG=* Authenticate Docker to an Amazon ECR reposetory - ended
ECHO [201;%ORANGE%m%MSG%[0m

REM ================= Stage #3 - AWS Repository Creation - end ==============================


REM ================= Stage #4 - Docker Image Creation - start ==============================
REM In this stage we build docker image, and push it to our reposetory.

CD %SERVICES_FOLDER%/%SERVICE_NAME%

SET MSG=* Build - started (may take few minutes...)
ECHO [201;%ORANGE%m%MSG%[0m
ECHO =====================================================================
docker build -t %FOUND_REPOSITORY_URI% . 
ECHO =====================================================================
SET MSG=* Build - ended
ECHO [201;%ORANGE%m%MSG%[0m

SET MSG=* Push - started (may take few minutes...)
ECHO [201;%ORANGE%m%MSG%[0m
ECHO =====================================================================
docker push %FOUND_REPOSITORY_URI%
ECHO =====================================================================
SET MSG=* Push - ended
ECHO [201;%ORANGE%m%MSG%[0m

CD ../..

REM ================= Stage #4 - Docker Image Creation - end ==============================


REM ================= Stage #5 - GitHub Workflow Creation - start ==============================
REM * In this stage we create a GitHub workflow, to soppurt CI/CD.
REM * With this workflow, an automatic build and push of docker image into the AWS reposetory will be executed on each GitHub push.
REM * More info - see https://medium.com/javascript-in-plain-english/deploy-your-node-app-to-aws-container-service-via-github-actions-build-a-pipeline-c114adeb8903,
REM   and its sub chapters:
REM   * 'Creating an IAM user for GitHub Actions'.
REM   * 'Setting up GitHub Actions'.

SET MSG=* Generate GitHub flow - started
ECHO [201;%ORANGE%m%MSG%[0m
POWERSHELL -Command "(gc %GITHUB_PARAMS_TEMPLATE_FILE_PATH%) -replace '#REGION#', '%REGION%' | Out-File -encoding ASCII %GITHUB_PARAMS_GENERATED_FILE_PATH%"
POWERSHELL -Command "(gc %GITHUB_PARAMS_GENERATED_FILE_PATH%) -replace '#TASK_DEFINITION#', '%TASK_DEFINITION%' | Out-File -encoding ASCII %GITHUB_PARAMS_GENERATED_FILE_PATH%"
POWERSHELL -Command "(gc %GITHUB_PARAMS_GENERATED_FILE_PATH%) -replace '#SERVICE_NAME#', '%SERVICE_NAME%' | Out-File -encoding ASCII %GITHUB_PARAMS_GENERATED_FILE_PATH%"
POWERSHELL -Command "(gc %GITHUB_PARAMS_GENERATED_FILE_PATH%) -replace '#APP_NAME#', '%APP_NAME%' | Out-File -encoding ASCII %GITHUB_PARAMS_GENERATED_FILE_PATH%"
POWERSHELL -Command "(gc %GITHUB_PARAMS_GENERATED_FILE_PATH%) -replace '#SERVICES_FOLDER#', '%SERVICES_FOLDER%' | Out-File -encoding ASCII %GITHUB_PARAMS_GENERATED_FILE_PATH%"

SET MSG=* Generate GitHub flow - ended
ECHO [201;%ORANGE%m%MSG%[0m

REM ================= Stage #5 - GitHub Workflow Creation - end ==============================


REM ================= Stage #6 - Termination - start ==============================

:END

IF DEFINED ERR_MSG (
    ECHO [201;%RED%m%ERR_MSG%[0m
)

SET MSG=* Handling of service '%SERVICE_NAME%' - ended
ECHO [201;%ORANGE%m%MSG%[0m

REM ================= Stage #6 - Termination - end ==============================