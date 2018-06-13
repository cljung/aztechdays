$uri1 = "https://<funcappname>.azurewebsites.net/api/HttpTriggerCSharp1?code=...key..."
Invoke-RestMethod -Uri "$($uri1)&name=There!" -Method Get 


$uri2 = "https://<funcappname>.azurewebsites.net/api/HttpTriggerCSharp2?code=...key..."
$body = @{name = 'Max Power'}
Invoke-RestMethod -Uri $uri2 -method Post -Body ($body | ConvertTo-json)

curl -G "https://<funcappname>.azurewebsites.net/api/HttpTriggerCSharp1?code=...key..."