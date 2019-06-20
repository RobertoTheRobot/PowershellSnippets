using namespace Microsoft.Azure.Storage
using namespace Microsoft.Azure.Storage.Queue

Add-Type -Path .\lib\Microsoft.Azure.Storage.Common.dll
Add-Type -Path .\lib\Microsoft.Azure.Storage.Queue.dll


Class AzureQueuePS {

    [string]$accountName
    [string]$accountKey
    [string]$queueName
    [CloudQueue]$queue

    #
    # Constructor
    #

    AzureQueuePS([string]$accountName,[string]$accountKey,[string]$queueName) {

        $this.accountName = $accountName
        $this.accountKey  = $accountKey
        $this.queueName   = $queueName

        $connectionString = "DefaultEndpointsProtocol=https;AccountName=${accountName};AccountKey=${accountKey};EndpointSuffix=core.windows.net"

        #Retrieve storage account from connection string.
        $StorageAccount = [Microsoft.Azure.Storage.CloudStorageAccount]::Parse($connectionString)

        $queueClient = [QueueAccountExtensions]::CreateCloudQueueClient($StorageAccount) 
        $this.queue = $queueClient.GetQueueReference($queueName)
        $this.queue.CreateIfNotExists();

    }

    #
    # Methods
    #

    [string] GetMessage([bool]$deleteMessage) {
        $message = $this.queue.GetMessage()

        if($deleteMessage)
        {
            $this.queue.Delete($message)
        }

        return $message.AsString
    }

    [void] AddMessage([string]$stringMessage) {
        $message = [CloudQueueMessage]::new($stringMessage)
        $this.queue.AddMessage($message)
    }

}


# Example:
# $o = [AzureQueuePS]::new($accountName,$accountKey,$queueName)
# $o.GetMessage($false)
# $o.AddMessage("test")
