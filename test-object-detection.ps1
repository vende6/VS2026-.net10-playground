<#
.SYNOPSIS
    Test Azure Computer Vision Object Detection

.DESCRIPTION
    Quick test script to verify Azure Computer Vision is working correctly.
    Tests authentication, endpoint connectivity, and basic object detection.

.AUTHOR
    Damir

.VERSION
    1.0.0

.EXAMPLE
    .\test-object-detection.ps1
    Tests with default sample image URL

.EXAMPLE
    .\test-object-detection.ps1 -ImageUrl "https://example.com/image.jpg"
    Tests with custom image URL
#>

param(
    [string]$ImageUrl = "https://upload.wikimedia.org/wikipedia/commons/thumb/1/12/User_with_smile.svg/1200px-User_with_smile.svg.png"
)

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "  Azure Computer Vision Test" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Check Azure CLI login
Write-Host "1. Checking Azure authentication..." -ForegroundColor Yellow

try {
    $account = az account show 2>&1 | ConvertFrom-Json
    Write-Host "   ? Logged in as: $($account.user.name)" -ForegroundColor Green
} catch {
    Write-Host "   ? Not logged in to Azure" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please run: az login" -ForegroundColor Yellow
    exit 1
}

Write-Host ""

# Step 2: Check for Computer Vision resources
Write-Host "2. Finding Computer Vision resources..." -ForegroundColor Yellow

$resources = az cognitiveservices account list `
    --query "[?kind=='ComputerVision'].{name:name, group:resourceGroup, endpoint:properties.endpoint}" `
    --output json | ConvertFrom-Json

if ($resources -and $resources.Count -gt 0) {
    Write-Host "   ? Found $($resources.Count) Computer Vision resource(s)" -ForegroundColor Green
    
    $resource = $resources[0]
    $resourceName = $resource.name
    $resourceGroup = $resource.group
    $endpoint = $resource.endpoint
    
    Write-Host "   Using: $resourceName" -ForegroundColor Cyan
    Write-Host "   Endpoint: $endpoint" -ForegroundColor Gray
} else {
    Write-Host "   ? No Computer Vision resources found" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please run: .\complete-azure-setup.ps1" -ForegroundColor Yellow
    exit 1
}

Write-Host ""

# Step 3: Get access key for testing
Write-Host "3. Retrieving access credentials..." -ForegroundColor Yellow

try {
    $key = az cognitiveservices account keys list `
        --name $resourceName `
        --resource-group $resourceGroup `
        --query key1 `
        --output tsv
    
    Write-Host "   ? Credentials retrieved" -ForegroundColor Green
} catch {
    Write-Host "   ? Failed to retrieve credentials" -ForegroundColor Red
    exit 1
}

Write-Host ""

# Step 4: Test the Computer Vision API
Write-Host "4. Testing object detection API..." -ForegroundColor Yellow
Write-Host "   Image URL: $ImageUrl" -ForegroundColor Gray
Write-Host ""

try {
    # Prepare the request
    $headers = @{
        "Ocp-Apim-Subscription-Key" = $key
        "Content-Type" = "application/json"
    }
    
    $body = @{
        url = $ImageUrl
    } | ConvertTo-Json
    
    # Make the API call
    $apiUrl = "$endpoint/vision/v3.2/analyze?visualFeatures=Objects,Tags,Description"
    
    Write-Host "   Making API request..." -ForegroundColor Gray
    
    $response = Invoke-RestMethod -Method Post -Uri $apiUrl -Headers $headers -Body $body
    
    Write-Host ""
    Write-Host "   ? API call successful!" -ForegroundColor Green
    Write-Host ""
    
    # Display results
    Write-Host "==========================================" -ForegroundColor Green
    Write-Host "  Detection Results" -ForegroundColor Green
    Write-Host "==========================================" -ForegroundColor Green
    Write-Host ""
    
    # Description
    if ($response.description -and $response.description.captions) {
        Write-Host "Description:" -ForegroundColor Yellow
        foreach ($caption in $response.description.captions) {
            $confidence = [math]::Round($caption.confidence * 100, 2)
            Write-Host "  • $($caption.text) ($confidence% confidence)" -ForegroundColor White
        }
        Write-Host ""
    }
    
    # Tags
    if ($response.tags) {
        Write-Host "Tags:" -ForegroundColor Yellow
        $topTags = $response.tags | Where-Object { $_.confidence -gt 0.7 } | Select-Object -First 10
        foreach ($tag in $topTags) {
            $confidence = [math]::Round($tag.confidence * 100, 2)
            Write-Host "  • $($tag.name) ($confidence%)" -ForegroundColor White
        }
        Write-Host ""
    }
    
    # Objects
    if ($response.objects) {
        Write-Host "Detected Objects:" -ForegroundColor Yellow
        foreach ($obj in $response.objects) {
            $confidence = [math]::Round($obj.confidence * 100, 2)
            $bbox = $obj.rectangle
            Write-Host "  • $($obj.object) ($confidence%)" -ForegroundColor White
            Write-Host "    Location: x=$($bbox.x), y=$($bbox.y), w=$($bbox.w), h=$($bbox.h)" -ForegroundColor Gray
        }
        Write-Host ""
    }
    
    # Metadata
    Write-Host "Image Info:" -ForegroundColor Yellow
    Write-Host "  • Width: $($response.metadata.width) px" -ForegroundColor White
    Write-Host "  • Height: $($response.metadata.height) px" -ForegroundColor White
    Write-Host "  • Format: $($response.metadata.format)" -ForegroundColor White
    Write-Host ""
    
    Write-Host "==========================================" -ForegroundColor Green
    Write-Host "  Test Complete! ?" -ForegroundColor Green
    Write-Host "==========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "? Azure Computer Vision is working correctly!" -ForegroundColor Green
    Write-Host "? Your applications are ready to detect objects" -ForegroundColor Green
    Write-Host ""
    
} catch {
    Write-Host ""
    Write-Host "   ? API call failed" -ForegroundColor Red
    Write-Host ""
    Write-Host "Error Details:" -ForegroundColor Yellow
    Write-Host $_.Exception.Message -ForegroundColor Red
    
    if ($_.Exception.Response) {
        $statusCode = $_.Exception.Response.StatusCode.value__
        Write-Host "Status Code: $statusCode" -ForegroundColor Red
        
        if ($statusCode -eq 401) {
            Write-Host ""
            Write-Host "Authentication error. Please ensure:" -ForegroundColor Yellow
            Write-Host "1. You're logged in: az login" -ForegroundColor White
            Write-Host "2. You have Cognitive Services User role assigned" -ForegroundColor White
        } elseif ($statusCode -eq 404) {
            Write-Host ""
            Write-Host "Resource not found. Please verify:" -ForegroundColor Yellow
            Write-Host "1. The endpoint URL is correct" -ForegroundColor White
            Write-Host "2. The resource exists in Azure" -ForegroundColor White
        }
    }
    
    Write-Host ""
    Write-Host "Troubleshooting:" -ForegroundColor Yellow
    Write-Host "1. Run: az login" -ForegroundColor White
    Write-Host "2. Verify resource: az cognitiveservices account show --name $resourceName --resource-group $resourceGroup" -ForegroundColor White
    Write-Host "3. Check role assignments: az role assignment list --scope /subscriptions/$($account.id)/resourceGroups/$resourceGroup" -ForegroundColor White
    Write-Host ""
    
    exit 1
}

Write-Host "Next Steps:" -ForegroundColor Cyan
Write-Host "• Test Blazor app: cd ObjectDetectionBlazor; dotnet run" -ForegroundColor White
Write-Host "• Test MAUI app: cd ObjectDetectionMaui; dotnet build" -ForegroundColor White
Write-Host "• Try different images by passing -ImageUrl parameter" -ForegroundColor White
Write-Host ""
