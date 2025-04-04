#Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

choco install azd -y
choco install github-desktop -y
#choco install docker-desktop -y

git clone https://github.com/givenscj/azure-ai-document-pipeline-python-sample

cd .\azure-ai-document-pipeline-python-sample\

az login --use-device-code -tenant 'your-tenant-id'
azd auth login --tenant-id 'your-tenant-id'

#wsl --install
