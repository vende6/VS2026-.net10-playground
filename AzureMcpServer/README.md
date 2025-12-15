# Azure MCP Server

Model Context Protocol server for Azure services.

## Quick Start

```powershell
# Configure endpoints
(Get-Content appsettings.json) -replace 'YOUR_OPENAI_RESOURCE', 'openaios' | Set-Content appsettings.json
(Get-Content appsettings.json) -replace 'YOUR_VISION_ENDPOINT', 'eastus.api.cognitive.microsoft' | Set-Content appsettings.json

# Run
dotnet run
```

## Features
- MCP protocol support
- Azure OpenAI chat tool
- Computer Vision image analysis tool

Author: Damir
