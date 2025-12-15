# Azure Chat App

AI Chat application powered by Azure OpenAI GPT-4.

## Quick Start

```powershell
# Configure with your Azure OpenAI endpoint
$endpoint = "https://openaios.openai.azure.com/"
(Get-Content appsettings.json) -replace 'YOUR_OPENAI_RESOURCE', 'openaios' | Set-Content appsettings.json

# Run
dotnet run
```

## Features
- Chat with GPT-4
- Conversation history
- Secure authentication via Azure AD

Author: Damir
