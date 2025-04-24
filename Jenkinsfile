// Jenkinsfile for Django-CI-Test project

pipeline {
    // 指定流水线执行的环境。
    // agent any 表示在任何可用的 Jenkins Agent 上执行。
    // 由于您的部署目标就是 Jenkins 服务器本身，请确保这个 Agent (可能是 built-in 或者您专门配置的)
    // 已经安装了 Git, Docker, 和 Docker Compose，并且 Jenkins 用户有权限执行 Docker 命令。
    agent any

    // 定义环境变量
    environment {
        // Docker 镜像的基础名称和 Tag，在本地构建和 docker-compose 中使用
        DOCKER_IMAGE_NAME = "django-test"     // <-- 您希望的镜像名称
        IMAGE_TAG = "${BUILD_NUMBER}"         // <-- 使用 Jenkins 内置的构建号作为镜像 Tag
        FULL_DOCKER_IMAGE = "${DOCKER_IMAGE_NAME}:${IMAGE_TAG}" // 完整的本地镜像名称

        // docker-compose.yml 文件在本地 Jenkins 服务器上的路径
        // **非常重要：** 请确保这个路径是正确的，并且 Jenkins 用户有权限访问该目录和其中的 docker-compose.yml 文件。
        TARGET_COMPOSE_DIR = "/root/application" // <-- docker-compose.yml 的实际路径在本地服务器上

        // 传递给 docker-compose 的环境变量列表
        // 这会将 Jenkins 中的这些变量传递到 docker compose up 执行的环境中
        // 使得 docker-compose.yml 中可以引用 ${DOCKER_IMAGE_NAME}, ${IMAGE_TAG}, ${BUILD_NUMBER}
        COMPOSE_ENV_VARS = "DOCKER_IMAGE_NAME=${DOCKER_IMAGE_NAME},IMAGE_TAG=${IMAGE_TAG},BUILD_NUMBER=${BUILD_NUMBER}"
    }

    stages {
        stage('Checkout') {
            steps {
                echo 'Checking out code from public GitHub repository...'
                // 从公开仓库拉取代码，无需凭据
                // 代码将拉取到 Jenkins Agent 的工作空间目录 (${WORKSPACE})
                // WORKSPACE 是 Jenkins 内置的环境变量，指向当前构建的工作目录
                git branch: 'main', // <-- 使用 main 分支
                    url: 'https://github.com/YouJianYue/Django-CI-Test.git' // <-- 您的仓库 URL
            }
        }

        // 根据您的描述，依赖安装 (pip install) 已经在您的 Dockerfile 中处理了，
        // 且构建将在下一步完成，因此不需要单独的 Prepare Environment 阶段在 Jenkins Agent 本地安装依赖。

        stage('Docker Build') {
            steps {
                echo "Building Docker Image ${FULL_DOCKER_IMAGE} in workspace..."
                // 在 Jenkins Agent 的工作空间 (${WORKSPACE}) 中执行 Docker 构建命令
                // context 是 '.' 表示在当前目录 (工作空间) 查找 Dockerfile 和构建上下文
                // ${FULL_DOCKER_IMAGE} 是上一步定义的完整镜像名称，用于 Tagging 构建好的镜像
                script {
                    // 确保 Dockerfile 存在于仓库根目录
                    if (fileExists('Dockerfile')) {
                       // 使用 docker 命令构建镜像
                       sh "docker build -t ${FULL_DOCKER_IMAGE} ."
                       echo "Docker image ${FULL_DOCKER_IMAGE} built successfully in Jenkins workspace."
                    } else {
                       error 'Dockerfile not found in the repository root!'
                    }
                }
            }
        }

        // 根据您的需求，不需要将镜像推送到远程仓库，因此没有 Docker Push 阶段。

        stage('Deploy') {
            steps {
                echo "Deploying using docker-compose located at ${TARGET_COMPOSE_DIR}..."
                // 执行 docker compose 命令
                script {
                    // **重要！** 将 Jenkins 工作空间 (${WORKSPACE}) 中的代码传输到目标 Docker Compose 目录 (${TARGET_COMPOSE_DIR})
                    // 这样 docker-compose up 执行时，build context (.) 能找到代码和 Dockerfile。
                    // **请确保 TARGET_COMPOSE_DIR 是一个合适的目录，且 Jenkins 用户有写入权限！**
                    // **注意：这会覆盖 TARGET_COMPOSE_DIR 目录下的同名文件！请谨慎！**
                    echo "Transferring code from ${WORKSPACE} to ${TARGET_COMPOSE_DIR}..."
                    // 使用 rsync 通常比 scp 更高效，特别是文件多的时候，且支持排除文件 (.git 等)
                    // 如果没有 rsync，可以使用 scp -r ${WORKSPACE}/* ${TARGET_COMPOSE_DIR}/
                    sh "rsync -avz --exclude '.git' ${WORKSPACE}/ ${TARGET_COMPOSE_DIR}/"
                    echo "Code transfer complete."


                    // 进入 docker-compose.yml 所在的目录
                    sh "cd ${TARGET_COMPOSE_DIR}"
                    echo "Changed directory to ${TARGET_COMPOSE_DIR}"


                    echo "Setting Docker Compose environment variables..."
                    // 将 Jenkins 中的环境变量导出，供接下来的 docker-compose 命令使用
                    withEnv(["DOCKER_IMAGE_NAME=${DOCKER_IMAGE_NAME}", "IMAGE_TAG=${IMAGE_TAG}"]) {
                         echo "Executing docker compose up -d..."
                         // 执行 docker compose up -d。
                         // Docker Compose 会查找当前目录 (${TARGET_COMPOSE_DIR}) 的 docker-compose.yml
                         // 它将使用已经设置的环境变量 ${DOCKER_IMAGE_NAME} 和 ${IMAGE_TAG} 来查找并使用镜像。
                         // **确保您的 docker-compose.yml 已经修改为使用 image: ${DOCKER_IMAGE_NAME}:${IMAGE_TAG} 并且移除了 build: .**
                         sh 'docker compose up -d --remove-orphans' // --remove-orphans 会移除 compose 文件中不再定义但正在运行的服务
                         echo "Docker compose services updated/started."
                    }
                }
            }
        }
    }

    // 流水线完成后的处理 (可选)
    post {
        always {
            // 清理 Jenkins Agent 的工作空间，释放磁盘空间
            cleanWs()
            echo 'Workspace cleaned.'
        }
        success {
            echo 'Pipeline succeeded!'
        }
        failure {
            echo 'Pipeline failed!'
        }
        // 您可以添加其他 post 步骤，例如发送通知
        // mail to: 'your.email@example.com', subject: "Jenkins Build ${JOB_NAME} - ${BUILD_NUMBER} ${currentBuild.currentResult}", body: "${env.BUILD_URL}"
    }
}