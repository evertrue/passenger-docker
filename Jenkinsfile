def name = 'registry.evertrue.com/evertrue/passenger'

stage 'Build Docker images'
  parallel ruby22: {
    buildImage('ruby22')
  }, ruby23: {
    buildImage('ruby23')
  }, full: {
    buildImage('full')
  },
  failFast: true

node {
  stage 'Push Docker images'
    sh "docker push ${name}-ruby22:${env.BUILD_ID}"
    sh "docker push ${name}-ruby23:${env.BUILD_ID}"
    sh "docker push ${name}-full:${env.BUILD_ID}"
}

def buildImage(image) {
  node {
    checkout scm
    sh "docker build -t registry.evertrue.com/evertrue/passenger-${image}:${env.BUILD_ID} -f Dockerfile-${image} ."
  }
}
