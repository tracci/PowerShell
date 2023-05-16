function Send-M365Mail {
    [cmdletbinding()]
    Param (
        [Parameter(Mandatory = $true)]
        [string]$PrimaryAddress,
        [string]$SecondaryAddress,
        [Parameter(Mandatory = $true)]
        [ValidateSet("noreply@domain.com", "do-not-reply@domain.com")] # Validate for authorized sending addresses
        [string]$SendFrom
    )
    Begin {
        # These are the values from the Azure App created with Mail.Send permissions in Graph.
        # The secret should be secured.
        $AppId = "AZURE APP ID"
        $AppSecret = "AZURE APP SECRET"
        $TenantID = "TENANT ID"
    }
    Process {

        # Variables
        $HtmlSource = "\\path\to\contentfile.html"
        $AttachmentFile = "\\path\to\attachment\files.gif"
        $MsgSubject = "Email subject goes here"

        # Construct URI and body needed for authentication
        $URI = "https://login.microsoftonline.com/$TenantID/oauth2/v2.0/token"
        $RequestBody = @{
            client_id     = $AppId
            scope         = "https://graph.microsoft.com/.default"
            client_secret = $AppSecret
            grant_type    = "client_credentials"
        }

        # Token parameters with request body
        $RequestParams = @{
            Method          = "Post"
            Uri             = $URI
            ContentType     = "application/x-www-form-urlencoded"
            Body            = $RequestBody
            UseBasicParsing = $true
        }
        $TokenRequest = Invoke-WebRequest @RequestParams

        # Unpack Access Token
        $AccessToken = ($TokenRequest.Content | ConvertFrom-Json).access_token
        $Headers = @{
            'Content-Type'  = "application\json"
            'Authorization' = "Bearer $AccessToken" 
        }

        # Use HTML import file if found, otherwise manually set the HTML
        # Our HTML file has variable placeholders that we set with the format operator.
        try { $HtmlImport = Get-Content $HtmlSource -Raw -ErrorAction Stop }
        catch { $HtmlImport = $null }
        if ($HtmlImport) {
            $HtmlBody = $HtmlImport -f $PrimaryAddress
        }
        else {
            $HtmlHeader = "<h2>Hello!</h2>"
            $HtmlLine1 = "<p><b>This is the first line</b></p>"
            $HtmlLine2 = "<p>This is a second line.</p>"
            $HtmlBody = $HtmlHeader + $HtmlLine1 + $HtmlLine2 + "<p>"
        }
        $HtmlMsg = "</body></html>" + $HtmlBody

        # Set our message body
        $MsgBody = @{
            "message" = @{
                "subject"      = $MsgSubject
                "body"         = @{
                    "contentType" = 'HTML' 
                    "content"     = $HtmlMsg
                }
                "toRecipients" = @(
                    @{
                        "emailAddress" = @{"address" = $PrimaryAddress }
                    } )     
            }
        }

        # Add secondary address if one was entered
        if ($SecondaryAddress) {
            $CCAddressData = @{
                "Values" = @(
                    @{
                        "emailAddress" = @{"address" = $SecondaryAddress }
                    })  
            }
            $MsgBody.Message.Add("ccRecipients", $CCAddressData.Values)
        }
        
        # Add attachment info if file is found
        # Set the "contentType" (MIME) accordingly -- refer to https://mimetype.io/. 
        if (Test-Path $AttachmentFile) {
            $ContentBase64 = [convert]::ToBase64String( [system.io.file]::readallbytes($AttachmentFile))     
            $AttachmentData = @{
                "Values" = @(
                    @{
                        "@odata.type"  = "#microsoft.graph.fileAttachment"
                        "name"         = $AttachmentFile
                        "contentType"  = "image/gif"
                        "contentBytes" = $ContentBase64 
                    })  
            }
            $MsgBody.Message.Add("attachments", $AttachmentData.Values)
        }
        
        # Format body as JSON and send the message
        $JsonBody = $MsgBody | ConvertTo-Json -Depth 6
        $MessageParams = @{
            "URI"         = "https://graph.microsoft.com/v1.0/users/$SendFrom/sendMail"
            "Headers"     = $Headers
            "Method"      = "POST"
            "ContentType" = 'application/json'
            "Body"        = $JsonBody
        }
        Invoke-RestMethod @MessageParams
    }
}