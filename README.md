# Azure Tech Training day material
This repo is for the hands-on technical training I've delivered. There is an accompanying series of posts on my blog http://www.redbaronofazure.com/?p=7432 that will walk you through the high level scenarios of the traning. 

## Which script should I use?
I've included multiple scripts for the same task so that you can use Powershell and/or CLI at your will.
CLI scripts written for Mac OS have a *-mac.sh name. CLI scripts intended for Windows DOS Command Prompt have a *-win.cmd name. Note that CLI/DOS are not desiged to run in a Powershell command prompt due to it's use of environment variables. I selected the DOS Command Prompt just because I wanted to show you it works too. Powershell scripts are pretty obvious as they are named *.ps1.

In order for the script to be repeatable, all the resources have names based on your userid followed by a random number. That way you can run the scripts in a shared subscription and everything is created in a new resource group. Easy to create, easy to remove.

## Preparing your scripting environment
Install Powershell and CLI and get your environment ready. <a href="http://www.redbaronofazure.com/?p=7432" target="_blank">http://www.redbaronofazure.com/?p=7432</a>

No scripts included for this part.

## PaaS AppServices
AppServices WebApps, managed database (MySQL in my example) <a href="http://www.redbaronofazure.com/?p=7445" target="_blank">http://www.redbaronofazure.com/?p=7445</a>
Azure Functions and CosmosDB. <a href="http://www.redbaronofazure.com/?p=7461" target="_blank">http://www.redbaronofazure.com/?p=7461</a>

appservices-*.*
cosmosdb-*.*
mysql-*.*

## IaaS VMs
Creation of a Ubutu Linux VM that you will use as a dev/build machine for the Container module. <a href="http://www.redbaronofazure.com/?p=7472" target="_blank">http://www.redbaronofazure.com/?p=7472</a>

vm-create*.*
ubuntu-install-devtools.sh

## Azure Kubernetes Services (AKS)
Script that creates a Azure Container Registry (ACS) and Azure Kubernete Services cluster and deploys an app to it
<a href="http://www.redbaronofazure.com/?p=7484" target="_blank">http://www.redbaronofazure.com/?p=7484</a>

azure-container-services-tutorial.sh

## Cognetive Services
Shows how easy it is to integrate Cognetive Services in a webapp

*.htm

## Machine Learning & Analytics
Dipping your toes in the water for the first time and understanding what you can do
