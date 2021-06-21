@description('Your unique ID - i.e. dm041221')
param yourID string
@description('Course ID - i.e. az220')
param courseID string

var location = resourceGroup().location
var iotHubName = 'iot-${courseID}-training-${yourID}'
var storageName = 'sta${courseID}training${yourID}'
var provisioningServiceName = 'dps-${courseID}-training-${yourID}'
var streamingjobs_vibrationJob_name = 'vibrationJob'

module hubAndDps './modules/hubAndDps.bicep' = {
  name: 'iotHubAndDpsDeploy'
  params: {
    iotHubName: iotHubName
    provisioningServiceName: provisioningServiceName
    skuName: 'S1'
    skuUnits: 1
    location: location
  }
}

resource storage 'Microsoft.Storage/storageAccounts@2021-02-01' = {
  name: storageName
  sku: {
    name: 'Standard_LRS'
    tier: 'Standard'
  }
  kind: 'StorageV2'
  location: location
}


resource streamingjobs_vibrationJob_name_resource 'Microsoft.StreamAnalytics/streamingjobs@2017-04-01-preview' = {
  name: streamingjobs_vibrationJob_name
  location: location
  properties: {
    sku: {
      name: 'Standard'
    }
    eventsOutOfOrderPolicy: 'Adjust'
    outputErrorPolicy: 'Stop'
    eventsOutOfOrderMaxDelayInSeconds: 10
    eventsLateArrivalMaxDelayInSeconds: 5
    dataLocale: 'en-US'
    compatibilityLevel: '1.1'
    contentStoragePolicy: 'SystemAccount'
    jobType: 'Cloud'
  }
}

resource streamingjobs_vibrationJob_name_vibrationInput 'Microsoft.StreamAnalytics/streamingjobs/inputs@2017-04-01-preview' = {
  parent: streamingjobs_vibrationJob_name_resource
  name: 'vibrationInput'
  properties: {
    type: 'Stream'
    datasource: {
      type: 'Microsoft.Devices/IotHubs'
      properties: {
        iotHubNamespace: iotHubName
        sharedAccessPolicyName: 'iothubowner'
        endpoint: 'messages/events'
        consumerGroupName: '$Default'
      }
    }
    compression: {
      type: 'None'
    }
    serialization: {
      type: 'Json'
      properties: {
        encoding: 'UTF8'
      }
    }
  }
}

resource streamingjobs_vibrationJob_name_vibrationOutput 'Microsoft.StreamAnalytics/streamingjobs/outputs@2017-04-01-preview' = {
  parent: streamingjobs_vibrationJob_name_resource
  name: 'vibrationOutput'
  properties: {
    datasource: {
      type: 'Microsoft.Storage/Blob'
      properties: {
        storageAccounts: [
          {
            accountName: 'vibrationstoredm062121'
          }
        ]
        container: 'vibrationcontainer'
        pathPattern: 'output/'
        dateFormat: 'yyyy/MM/dd'
        timeFormat: 'HH'
        authenticationMode: 'ConnectionString'
      }
    }
    serialization: {
      type: 'Json'
      properties: {
        encoding: 'UTF8'
        format: 'LineSeparated'
      }
    }
  }
}

output connectionString string = hubAndDps.outputs.iotHubConnectionString
output dpsScopeId string = hubAndDps.outputs.dpsScopeId
output storageAccountName string = storageName

// note - lab requires "Microsoft.Insights" provider
