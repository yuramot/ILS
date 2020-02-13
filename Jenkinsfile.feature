pipeline {
    agent any

    options {
        timeout(time: 1, unit: 'HOURS') 
    }
    stages {
        stage('Build') {
            steps {
                echo 'Building..'
                echo "Running ${env.BUILD_ID} ${env.JOB_NAME} on ${env.JENKINS_URL}"
                bat 'prebuild.cmd Feature'
                bat 'build.cmd Feature'
                bat 'build_tests.cmd Debug'
            }
        }
        stage('Test') {
            steps {
                echo 'Testing..'
                bat 'run_tests.cmd'
            }
        }
        stage('Archive') {
            steps {
                echo 'Archiving artifacts..'
                bat 'zip_build.cmd Feature'
            }
        }
    }
    post {
        always {
//            nunit testResultsPattern: '*.xml'
            // nunit testResultsPattern: 'bin\\TestReports\\*.xml'
            nunit testResultsPattern: 'dunit\\report\\*.xml'
            //zip zipFile: 'Release.zip', glob: '*.exe', dir:'bin/Release/', archive: true 
            archiveArtifacts '*.zip'
            //archiveArtifacts 'bin/Release/Release.zip'
            //nunit testResultsPattern: 'bin/ILS Monitoring Server Test/ReleaseConsole/dunit-report.xml'
        }        
        changed {
//            mail to: '$DEFAULT_RECIPIENTS', 
//                 from: 'jenkins@ils-glonass.ru',
//                 subject: '$DEFAULT_SUBJECT',
//                 body: '$DEFAULT_CONTENT'
            script {
//                if (currentBuild.currentResult == 'FAILURE') { // Other values: SUCCESS, UNSTABLE
                    // Send an email only if the build status has changed from green/unstable to red
                    emailext subject: '$DEFAULT_SUBJECT',
                                      body: '$DEFAULT_CONTENT',
                        recipientProviders: [
                                                [$class: 'CulpritsRecipientProvider'],
                                                [$class: 'DevelopersRecipientProvider'],
                                                [$class: 'RequesterRecipientProvider']
                                            ], 
                                   replyTo: '$DEFAULT_REPLYTO',
                                        to: '$DEFAULT_RECIPIENTS'
//                }
            }
        }
    }
}