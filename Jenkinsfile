def name = 'registry.evertrue.com/evertrue/passenger'
def safeBranchName = env.BRANCH_NAME.replaceAll(/\//, "-")

node {
  try {
    stage 'Checkout code'
      checkout scm

    stage 'Build Docker images'
      parallel ruby22: {
        buildImage('ruby22', safeBranchName)
      }, ruby23: {
        buildImage('ruby23', safeBranchName)
      }, full: {
        buildImage('full', safeBranchName)
      },
      failFast: true

    stage 'Push Docker images'
      sh "docker push ${name}-ruby22:${safeBranchName}-${env.BUILD_ID}"
      sh "docker push ${name}-ruby23:${safeBranchName}-${env.BUILD_ID}"
      sh "docker push ${name}-full:${safeBranchName}-${env.BUILD_ID}"

    slackSend color: 'good', message: "${env.JOB_NAME} - #${env.BUILD_NUMBER} Success (<${env.BUILD_URL}|Open>)"
  } catch (e) {
    currentBuild.result = "FAILED"
    slackSend color: 'bad', message: "${env.JOB_NAME} - #${env.BUILD_NUMBER} Failure (<${env.BUILD_URL}|Open>)"
    throw e
  }

  step([$class: 'GitHubCommitStatusSetter'])
}

def buildImage(image, safeBranchName) {
  sh "docker build -t registry.evertrue.com/evertrue/passenger-${image}:${safeBranchName}-${env.BUILD_ID} -f Dockerfile-${image} ."
}
