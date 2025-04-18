$tenantId = 'your-tenant-id'

Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

choco install git -y
choco install azd -y
choco install github-desktop -y
#choco install docker-desktop -y

mkdir C:\github
cd C:\github
git clone https://github.com/givenscj/azure-ai-document-pipeline-python-sample

cd .\azure-ai-document-pipeline-python-sample\

az login --use-device-code -tenant $tenantId
azd auth login --tenant-id $tenantId

#wsl --install
