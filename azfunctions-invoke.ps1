$uri1 = "https://cljungfunc02.azurewebsites.net/api/HttpTriggerCSharp1?code=WfmA5L6rzACdBl1hwUBIjc1ON6wLm8HTeCbgxI/KjmayBusWyqGSWw=="
Invoke-RestMethod -Uri "$($uri1)&name=There!" -Method Get 


$uri2 = "https://cljungfunc02.azurewebsites.net/api/HttpTriggerCSharp2?code=N4awoUdaiyOSAyT4RuThYEk30Uxx/bm4eesIdVgC8t29GLUqLaZNlQ=="
$body = @{name = 'Max Power'}
Invoke-RestMethod -Uri $uri2 -method Post -Body ($body | ConvertTo-json)

curl -G "https://cljungfunc02.azurewebsites.net/api/HttpTriggerCSharp1?code=WfmA5L6rzACdBl1hwUBIjc1ON6wLm8HTeCbgxI/KjmayBusWyqGSWw==&curl"