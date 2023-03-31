@description('**************Parameter section********************************************************')

param storageAccountName string = 'teststorageprdep1234567'
param location string = resourceGroup().location
@allowed([
  'Basic'
  'Standard'
])
param publicIpSku string = 'Basic'

@allowed([
  'Dynamic'
  'static'
])
param publicIPAllocationMethod string = 'Dynamic'

@description('Unique DNS Name for the Public IP used to access the Virtual Machine.')
param dnsLabelPrefix string = 'myvmtest12345678909876'

@description('Username for the Virtual Machine.')
param adminUsername string
@description('Password for the Virtual Machine.')
@minLength(12)
@secure()
param adminPassword string
@description('Name of the virtual machine.')
param vmName string = 'TestVm'
@description('Size of the virtual machine.')
param vmSize string = 'Standard_B1s'
@description('The Windows version for the VM. This will pick a fully patched image of this given Windows version.')
@allowed([
'2008-R2-SP1'
'2008-R2-SP1-smalldisk'
'2012-Datacenter'
'2012-datacenter-gensecond'
'2012-Datacenter-smalldisk'
'2012-datacenter-smalldisk-g2'
'2012-Datacenter-zhcn'
'2012-datacenter-zhcn-g2'
'2012-R2-Datacenter'
'2012-r2-datacenter-gensecond'
'2012-R2-Datacenter-smalldisk'
'2012-r2-datacenter-smalldisk-g2'
'2012-R2-Datacenter-zhcn'
'2012-r2-datacenter-zhcn-g2'
'2016-Datacenter'
'2016-datacenter-gensecond'
'2016-datacenter-gs'
'2016-Datacenter-Server-Core'
'2016-datacenter-server-core-g2'
'2016-Datacenter-Server-Core-smalldisk'
'2016-datacenter-server-core-smalldisk-g2'
'2016-Datacenter-smalldisk'
'2016-datacenter-smalldisk-g2'
'2016-Datacenter-with-Containers'
'2016-datacenter-with-containers-g2'
'2016-datacenter-with-containers-gs'
'2016-Datacenter-zhcn'
'2016-datacenter-zhcn-g2'
'2019-Datacenter'
'2019-Datacenter-Core'
'2019-datacenter-core-g2'
'2019-Datacenter-Core-smalldisk'
'2019-datacenter-core-smalldisk-g2'
'2019-Datacenter-Core-with-Containers'
'2019-datacenter-core-with-containers-g2'
'2019-Datacenter-Core-with-Containers-smalldisk'
'2019-datacenter-core-with-containers-smalldisk-g2'
'2019-datacenter-gensecond'
'2019-datacenter-gs'
'2019-Datacenter-smalldisk'
'2019-datacenter-smalldisk-g2'
'2019-Datacenter-with-Containers'
'2019-datacenter-with-containers-g2'
'2019-datacenter-with-containers-gs'
'2019-Datacenter-with-Containers-smalldisk'
'2019-datacenter-with-containers-smalldisk-g2'
'2019-Datacenter-zhcn'
'2019-datacenter-zhcn-g2'
'2022-datacenter'
'2022-datacenter-azure-edition'
'2022-datacenter-azure-edition-core'
'2022-datacenter-azure-edition-core-smalldisk'
'2022-datacenter-azure-edition-smalldisk'
'2022-datacenter-core'
'2022-datacenter-core-g2'
'2022-datacenter-core-smalldisk'
'2022-datacenter-core-smalldisk-g2'
'2022-datacenter-g2'
'2022-datacenter-smalldisk'
'2022-datacenter-smalldisk-g2'
])
param OSVersion string = '2022-datacenter-azure-edition'

@description('*********variable section********************************************************************')

var virtualNetworkName = 'TestVnet'
var subnetName = 'TestSubnet'
var addressPrefix = '10.0.0.0/12'
var subnetPrefix = '10.0.0.0/24'
var networkSecurityGroupName = 'TestNSG'
var publicIpName = 'TestPublicIP'
var nicName = 'TestvmNIC'



@description('Create Storage account')
resource stg 'Microsoft.Storage/storageAccounts@2021-04-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'Storage'
}

@description('Vnet creation')
resource vn 'Microsoft.Network/virtualNetworks@2021-02-01' = {
  name: virtualNetworkName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        addressPrefix
      ]
    }
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: subnetPrefix
          networkSecurityGroup: {
            id: securityGroup.id
          }
        }
      }
    ]
  }
}

@description('Security Group creation')
resource securityGroup 'Microsoft.Network/networkSecurityGroups@2021-02-01' = {
  name: networkSecurityGroupName
  location: location
  properties: {
    securityRules: [
      {
        name: 'default-allow-3389'
        properties: {
          priority: 1000
          access: 'Allow'
          direction: 'Inbound'
          destinationPortRange: '3389'
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}


@description('public IP')
resource pip 'Microsoft.Network/publicIPAddresses@2021-02-01' = {
  name: publicIpName
  location: location
  sku: {
    name: publicIpSku
  }
  properties: {
    publicIPAllocationMethod: publicIPAllocationMethod
    dnsSettings: {
      domainNameLabel: dnsLabelPrefix
    }
  }
}

resource nic 'Microsoft.Network/networkInterfaces@2021-02-01' = {
  name: nicName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: pip.id
          }
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', vn.name, subnetName)
          }
        }
      }
    ]
  }
}


resource vm 'Microsoft.Compute/virtualMachines@2021-03-01' = {
  name: vmName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: OSVersion
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'StandardSSD_LRS'
        }
      }
      dataDisks: [
        {
          diskSizeGB: 1023
          lun: 0
          createOption: 'Empty'
        }
      ]
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
        storageUri: stg.properties.primaryEndpoints.blob
      }
    }
  }
}

output hostname string = pip.properties.dnsSettings.fqdn
