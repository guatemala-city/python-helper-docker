#!/usr/bin/env groovy
try {
    node('docker') {

        def docker_registry_host = env.DOCKER_REGISTRY_HOST ?: 'index.docker.io/v2/'
        def docker_registry_credentials_id = env.DOCKER_REGISTRY_CREDENTIALS_ID?: 'dockerhub_cred'
        def uniqueWorkspace = "build-" +env.BUILD_ID

        def commit_id
        def image
        def repository
        def tag

        stage('Checkout') {
            dir(uniqueWorkspace){
                checkout scm
                commit_id   = sh(script: 'git rev-parse HEAD', returnStdout: true).trim()
                repository  = sh(script: 'cat repository.txt', returnStdout: true).trim()
                tag         = sh(script: 'cat tag.txt', returnStdout: true).trim()
            }
        }

        withEnv(["DOCKER_REGISTRY_HOST=${docker_registry_host}",
                 "DOCKER_REGISTRY_CREDENTIALS_ID=${docker_registry_credentials_id}",
                 "COMMIT_ID=${commit_id}",
                 "WORKDIR=${uniqueWorkspace}"]) {

            stage('Build') {
                sh 'printenv'

                if (!env.BRANCH_NAME.toLowerCase().startsWith("master"))
                    tag = tag + '-' + env.BUILD_ID

                sh(script: "docker build -t ${repository}:${tag}" +
                        " --build-arg BRANCH_NAME='${env.BRANCH_NAME}'" +
                        " --build-arg COMMIT_ID='${env.COMMIT_ID}' " +
                        " --build-arg BUILD_ID='${env.BUILD_ID}'  " +
                        " --build-arg JENKINS_URL='${env.JENKINS_URL}' " +
                        " --build-arg JOB_NAME='${env.JOB_NAME}' " +
                        " --build-arg NODE_NAME='${env.NODE_NAME}' " +
                        " '${WORKSPACE}/${WORKDIR}/'", returnStdout: true).trim()

                image = docker.image(repository + ':' + tag)
            }

            docker.withRegistry("https://${env.DOCKER_REGISTRY_HOST}", env.DOCKER_REGISTRY_CREDENTIALS_ID) {

                stage('Push') {
                    image.push()
                }

                stage('Promote') {
                    // We can now re-tag and push the 'latest' image.
                    image.push('latest')
                }
            }

            stage('Cleanup') {
                sh "docker image rm ${repository}:${tag}" 
            }

        }
    }
} catch (ex) {
    // If there was an exception thrown, the build failed
    if (currentBuild.result != "ABORTED") {
        // Send e-mail notifications for failed or unstable builds.
        // currentBuild.result must be non-null for this step to work.
        emailext(
                recipientProviders: [
                        [$class: 'DevelopersRecipientProvider'],
                        [$class: 'RequesterRecipientProvider']],
                subject: "Job '${env.JOB_NAME}' - Build ${env.BUILD_DISPLAY_NAME} - FAILED!",
                body: """<p>Job '${env.JOB_NAME}' - Build ${env.BUILD_DISPLAY_NAME} - FAILED:</p>
                        <p>Check console output &QUOT;<a href='${env.BUILD_URL}'>${env.BUILD_DISPLAY_NAME}</a>&QUOT;
                        to view the results.</p>"""
        )
    }

    // Must re-throw exception to propagate error:
    throw ex
}
