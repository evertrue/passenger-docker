def name = 'registry.evertrue.com/evertrue/passenger'
def safeBranchName = env.BRANCH_NAME.replaceAll(/\//, "-")
def tag = "${safeBranchName}-${env.BUILD_ID}"

node {
  try {
    stage 'Checkout code'
      checkout scm

    stage 'Build Docker images'
      parallel ruby22: {
        buildImage('ruby22', tag, name)
      }, ruby23: {
        buildImage('ruby23', tag, name)
      }, ruby24: {
        buildImage('ruby24', tag, name)
      }, full: {
        buildImage('full', tag, name)
      },
      failFast: true

    stage 'Push Docker images'
      parallel ruby22: {
        pushImage('ruby22', tag, name)
      }, ruby23: {
        pushImage('ruby23', tag, name)
      }, ruby24: {
        pushImage('ruby24', tag, name)
      }, full: {
        pushImage('full', tag, name)
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

def buildImage(image, tag, name) {
  sh "docker build -t ${name}-${image}:${tag} -f Dockerfile-${image} ."
}

def pushImage(image, tag, name) {
  if (env.BRANCH_NAME == 'master' ) {
    sh "make build_${image}"
  } else {
    sh "docker push ${name}-${image}:${tag}"
  }
}
