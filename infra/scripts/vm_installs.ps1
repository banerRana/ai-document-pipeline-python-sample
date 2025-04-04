#Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

choco install azd -y

git clone https://github.com/givenscj/azure-ai-document-pipeline-python-sample

cd .\azure-ai-document-pipeline-python-sample\

az login --use-device-code
azd login

