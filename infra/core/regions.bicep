
@export()
var regionAbbreviations = {
  // Africa
  southafricanorth: 'san'
  southafricawest: 'saw'

  // Asia Pacific
  australiaeast: 'aue'
  australiacentral: 'auc'
  australiacentral2: 'auc2'
  australiasoutheast: 'ause'
  eastasia: 'ea'
  southeastasia: 'sea'
  centralindia: 'cin'
  southindia: 'sin'
  westindia: 'win'
  jioindiacentral: 'jic'
  jioindiawest: 'jiw'
  japaneast: 'jpe'
  japanwest: 'jpw'
  koreacentral: 'krc'
  koreasouth: 'krs'
  malaysiawest: 'myw'
  newzealandnorth: 'nzn'
  indonesiacentral: 'idc'
  taiwannorth: 'twn'

  // Canada
  canadaeast: 'cae'

  // Europe
  northeurope: 'neu'
  westeurope: 'weu'
  uksouth: 'uks'
  ukwest: 'ukw'
  francecentral: 'frc'
  francesouth: 'frs'
  germanywestcentral: 'gwc'
  germanynorth: 'gn'
  italynorth: 'itn'
  polandcentral: 'plc'
  spaincentral: 'spc'
  swedencentral: 'swc'
  swedensouth: 'sws'
  norwayeast: 'noe'
  norwaywest: 'now'
  switzerlandnorth: 'chn'
  switzerlandwest: 'chw'
  austriaeast: 'ate'
  belgiumcentral: 'bec'
  denmarkeast: 'dke'
  finlandcentral: 'fic'
  greececentral: 'grc'

  // Middle East
  uaenorth: 'uan'
  uaecentral: 'uac'
  qatarcentral: 'qac'
  israelcentral: 'ilc'
  israelnorthwest: 'ilnw'
  saudiarabiaeast: 'sae'
  saudiarabiacentral: 'sac'

  // South America
  brazilsouth: 'brs'
  brazilsoutheast: 'brse'
  chilecentral: 'clc'

  // United States
  eastus: 'eus'
  eastus2: 'eus2'
  centralus: 'cus'
  northcentralus: 'ncus'
  southcentralus: 'scus'
  westcentralus: 'wcus'
  westus: 'wus'
  westus2: 'wus2'
  westus3: 'wus3'

  // Additional Americas
  mexicocentral: 'mxc'
  canadacentral: 'cac'

  // Other commonly used regions
  centraluseuap: 'ceua'
  eastus2euap: 'e2ua'
}

@export()
func getRegionAbbreviation(location string) string =>
  contains(regionAbbreviations, toLower(location))
    ? regionAbbreviations[toLower(location)]
    : toLower(location)
