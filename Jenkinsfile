pipeline {
  agent any

  environment {
    // ---- BASIC CONFIG ----
    SERVICE_NAME        = 'backend'
    DOCKER_IMAGE        = 'manojm525/backend'                     // change to your DockerHub username/repo
    DOCKER_CRED_ID      = 'docker_creds'                          // Jenkins credential ID for DockerHub
    GIT_CRED_ID         = 'git_access_cred'                        // Jenkins credential ID to push to manifests repo
    DEPLOYMENT_REPO_URL = 'https://github.com/manojM525/DEVOPS_DEPLOYMENT.git'
    DEPLOYMENT_REPO_DIR = 'DEVOPS_DEPLOYMENT'
    DEPLOYMENT_FILE     = "backend/deployment.yaml"
    
    // ---- ARGOCD CONFIG ----
    ARGOCD_SERVER       = 'argocd.example.com'
    ARGOCD_TOKEN_ID     = 'argocd-token'                       // Jenkins secret text credential
    ARGOCD_APP_NAME     = 'myapp'                              // ArgoCD app name

    // ---- GIT CONFIG FOR COMMITS ----
    GIT_USER_NAME       = 'jenkins-ci'
    GIT_USER_EMAIL      = 'jenkins@company.com'
  }

  stages {

    stage('Checkout Source') {
      steps {
        checkout scm
      }
    }

    stage('Read Version') {
      steps {
        script {
          def pkg = readJSON file: 'package.json'
          env.NEW_VERSION = pkg.version
          echo "📦 Detected backend version: ${env.NEW_VERSION}"
        }
      }
    }

    stage('Build & Push Docker Image') {
      steps {
        script {
          withCredentials([usernamePassword(credentialsId: env.DOCKER_CRED_ID, usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
            sh '''
              echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
              docker build -t ${DOCKER_IMAGE}:${NEW_VERSION} .
              docker push ${DOCKER_IMAGE}:${NEW_VERSION}
              docker logout
            '''
          }
        }
      }
    }

    stage('Update Deployment Manifest Repo') {
      steps {
        script {
          // Create or reuse a clean workspace for manifests repo
          dir("${DEPLOYMENT_REPO_DIR}") {
            deleteDir()

            // Clone deployment-manifests repo
            checkout([$class: 'GitSCM',
              branches: [[name: '*/main']],
              userRemoteConfigs: [[
                url: env.DEPLOYMENT_REPO_URL,
                credentialsId: env.GIT_CRED_ID
              ]]
            ])

            // Update the image field using yq (v4)
            sh """
              echo "🧩 Updating backend image in ${DEPLOYMENT_FILE}..."
              yq e -i '.spec.template.spec.containers[0].image = "${DOCKER_IMAGE}:${NEW_VERSION}"' ${DEPLOYMENT_FILE}
              
              git config user.name "${GIT_USER_NAME}"
              git config user.email "${GIT_USER_EMAIL}"
              git add ${DEPLOYMENT_FILE}
              git commit -m "chore(backend): bump image to v${NEW_VERSION}" || echo "No changes to commit"
              git push origin main
            """
          }
        }
      }
    }

    // stage('Trigger ArgoCD Sync') {
    //   steps {
    //     script {
    //       withCredentials([string(credentialsId: env.ARGOCD_TOKEN_ID, variable: 'ARGO_TOKEN')]) {
    //         sh """
    //           echo "🚀 Triggering ArgoCD sync for app ${ARGOCD_APP_NAME}..."
    //           argocd login ${ARGOCD_SERVER} --sso --insecure --username admin --password "\${ARGO_TOKEN}" || true
    //           argocd app sync ${ARGOCD_APP_NAME} --server ${ARGOCD_SERVER} || true
    //           argocd app wait ${ARGOCD_APP_NAME} --server ${ARGOCD_SERVER} --health --timeout 300
    //         """
    //       }
    //     }
    //   }
    // }
  }

  post {
    success {
      echo "✅ Backend pipeline completed successfully — version ${env.NEW_VERSION} deployed via ArgoCD."
    }
    failure {
      echo "❌ Backend pipeline failed."
    }
  }
}
