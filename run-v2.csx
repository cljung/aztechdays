#r "Newtonsoft.Json"
#r "Microsoft.Azure.Documents.Client"
using System.Net;
using System.Text;
using Newtonsoft.Json;
using System.Configuration;
using Microsoft.Azure.Documents;
using Microsoft.Azure.Documents.Client;

public static async Task<HttpResponseMessage> Run(
                                              HttpRequestMessage req
                                            , TraceWriter log
                                            , IAsyncCollector<object> outputDocument
                                            )
{
    log.Info("C# HTTP trigger function processed a request.");
    dynamic body = await req.Content.ReadAsStringAsync(); 
    log.Info( body );    
    await outputDocument.AddAsync( body );    
    return req.CreateResponse(HttpStatusCode.OK, "Request saved");
}
