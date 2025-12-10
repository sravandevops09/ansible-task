pipeline {
    agent any

    environment {
        TF_VAR_region = "us-east-1"
    }

    stages {

        stage('Checkout') {
            steps {
                echo "Cloning repo..."
                git branch: 'main', url: 'https://github.com/sravandevops09/ansible-task.git'
            }
        }

        stage('Terraform Apply') {
            steps {
                script {
                    dir("${WORKSPACE}") {

                        sh 'terraform init'
                        sh 'terraform validate'

                        withAWS(credentials: 'aws_key', region: 'us-east-1') {
                            sh 'terraform plan'
                            sh 'terraform apply -auto-approve'
                        }

                        // ---- Write dynamic inventory file ----
                        sh '''
                        echo "Generating dynamic inventory..."
                        terraform output -json > tf.json

cat <<EOF > inventory.yaml
all:
  children:
    frontend:
      hosts:
        $(jq -r '.frontend_public_ip.value' tf.json):
          ansible_user: ec2-user
          backend_ip: $(jq -r '.backend_private_ip.value' tf.json)
    backend:
      hosts:
        $(jq -r '.backend_public_ip.value' tf.json):
          ansible_user: ubuntu
EOF
                        '''
                    }
                }
            }
        }

        stage('Ansible Deployment') {
            steps {
                script {

                    // FRONTEND (Amazon Linux)
                    ansiblePlaybook(
                        credentialsId: 'ansible-key',
                        disableHostKeyChecking: true,
                        installation: 'ansible',
                        inventory: 'inventory.yaml',
                        playbook: 'amazon-playbook.yml',
                        limit: "frontend"
                    )

                    // BACKEND (Ubuntu)
                    ansiblePlaybook(
                        credentialsId: 'ansible-key',
                        disableHostKeyChecking: true,
                        installation: 'ansible',
                        inventory: 'inventory.yaml',
                        playbook: 'ubuntu-playbook.yml',
                        limit: "backend"
                    )
                }
            }
        }
    }
}
