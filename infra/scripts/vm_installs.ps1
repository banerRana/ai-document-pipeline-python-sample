$tenantId = 'your-tenant-id'

Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

choco install python311 -y
choco install git -y
choco install azd -y
choco install github-desktop -y
choco install powershell-core -y

wsl --update

mkdir C:\github
cd C:\github
git clone https://github.com/givenscj/azure-ai-document-pipeline-python-sample

cd .\azure-ai-document-pipeline-python-sample\

#open visual studio code to the project folder
code .

az login --use-device-code --tenant $tenantId
azd auth login --tenant-id $tenantId

#copy your .env file to the project folder in the virtual machine

choco install docker-desktop -y
restart

azd provision --debug

azd up
