def name = 'registry.evertrue.com/evertrue/passenger'
def safeBranchName = env.BRANCH_NAME.replaceAll(/\//, "-")
def tag = "${safeBranchName}-${env.BUILD_ID}"

node {
  try {
    stage 'Checkout code'
      checkout scm

    stage 'Build Docker images'
      parallel ruby22: {
        buildImage('ruby22', tag)
      }, ruby23: {
        buildImage('ruby23', tag)
      }, full: {
        buildImage('full', tag)
      },
      failFast: true

    stage 'Push Docker images'
      parallel ruby22: {
        pushImage("${name}-ruby22", tag)
      }, ruby23: {
        pushImage("${name}-ruby23", tag)
      }, full: {
        pushImage("${name}-full", tag)
      },
      failFast: true

    slackSend color: 'good', message: "${env.JOB_NAME} - #${env.BUILD_NUMBER} Success (<${env.BUILD_URL}|Open>)"
  } catch (e) {
    currentBuild.result = "FAILED"
    slackSend color: 'bad', message: "${env.JOB_NAME} - #${env.BUILD_NUMBER} Failure (<${env.BUILD_URL}|Open>)"
    throw e
  }

  step([$class: 'GitHubCommitStatusSetter'])
}

def buildImage(image, tag) {
  sh "docker build -t registry.evertrue.com/evertrue/passenger-${image}:${tag} -f Dockerfile-${image} ."
}

def pushImage(image, tag) {
  sh "docker push ${image}:${tag}"
  if (env.BRANCH_NAME == 'master' ) {
    sh "docker tag ${image}:${tag} ${image}:latest"
    sh "docker push ${image}:latest"
  }
}
