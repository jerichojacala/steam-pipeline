# steam-pipeline

1. Create an Azure account
1. [Download the Azure CLI](https://learn.microsoft.com/en-us/cli/azure/get-started-with-azure-cli?view=azure-cli-latest)
1. (Optional) Verify installation using "az version" in the CLI
1. Login to account using "az login" in the CLI
1. Add the databricks extension using "az extension add --name databricks"
1. Add execute permission to setup.sh and run
1. Upload files to steamcontainer
1. Find steamconnector resource id
1. Open databricks workspace
1. Establish a storage credential using the steamconnector resource id
1. Establish an external location using this storage credential and fill in the url

## Issues I ran into (to talk about in interviews)

While building the bash script to deploy the infrastructure, I ran into an interesting issue where the databricks workspace entered a "zombie" state. The workspace was stuck in the "deploying" phase. After checking the log errors, checking forums for similar issues, and asking LLMs, I couldn't determine what the error was. My research came to the consensus that I should simply wait for the deployment to time out rather than attempting to force the destruction of the workspace. After a few hours, the deployment timed out. I have run into this issue once and have not experienced it again or been able to replicate it.

Sometimes, issues don't present themselves as errors- they fail silently instead. I left my cloud infrastructure up believing that it would not cost much in terms of spend. After all, I was simply provisioning some storage and a databricks workspace. However, after leaving it open for a weekend, I found out that the system had used a few dollars. Looking through the cost analysis tool, most of the cost came from something called a "NAT Gateway."

It's hard to say where this cost comes from- while visualizations show accumulated cost, from my experience there is often a delay between using spend and seeing its effects in the cost management system. Perhaps it came from the zombie databricks workspace. I did not explicitly provision a NAT gateway for my infrastructure.

Bash scripts often take a long time to deploy, and if something goes wrong, Bash is often not expressive enough to stop a deployment prematurely and safely. Dependencies can become complex, and echoing in Bash can get drowned out by text from the cloud CLI. Terraform manages all of these problems. A goal of this project is to replicate deployment in Terraform.

I kept running into an error when granting the storage blob data contributor role to the data connector. The Azure generated error message explained it could not find the scope that I was providing. Initially after running it through an LLM, consulting documentation, 


## Excessive stop words - BERTopic

https://maartengr.github.io/BERTopic/faq.html#how-do-i-reduce-topic-outliers

Upon running the BERTopic model upon raw documents from project zomboid reviews, one thing I noticed was that there were a lot of stop words in the themes. In fact, there was little in the themes that seemed to actually related to the game.