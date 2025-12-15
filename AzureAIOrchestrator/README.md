# ?? Azure AI Orchestrator - Aspire Dashboard

Complete Aspire orchestration for all 4 Azure AI applications with unified dashboard and Azure deployment.

## ?? What This Does

The **AzureAIOrchestrator** project provides:
- ? Unified Aspire Dashboard to monitor all apps
- ? One-click local development
- ? Easy Azure deployment with `azd`
- ? Centralized logging and metrics
- ? Service discovery and configuration

---

## ??? Applications Orchestrated

| App | Type | Port | Description |
|-----|------|------|-------------|
| **ObjectDetectionBlazor** | Web | 5000 | Object detection web app |
| **AzureChatApp** | Console | - | GPT-4 chat application |
| **ObjectDetectionMaui** | Desktop | - | MAUI desktop app |
| **AzureMcpServer** | Service | stdio | MCP protocol server |

---

## ?? Quick Start

### 1. Run Locally with Aspire Dashboard

```powershell
cd AzureAIOrchestrator
dotnet run
```

This starts:
- ? Aspire Dashboard at `http://localhost:15888`
- ? All configured web apps
- ? Centralized logging view
- ? Distributed tracing

### 2. View Dashboard

Open browser to: **http://localhost:15888**

You'll see:
- ?? All running applications
- ?? Resource usage (CPU, memory)
- ?? Centralized logs
- ?? Distributed traces
- ?? Service endpoints

---

## ?? Deploy to Azure

### Prerequisites
```powershell
# Install Azure Developer CLI
winget install microsoft.azd

# Login
azd auth login
```

### Deploy All Apps

```powershell
cd AzureAIOrchestrator

# Initialize
azd init

# Provision Azure resources and deploy
azd up
```

This creates:
- ? Azure Container Apps for Blazor app
- ? Azure Container Registry
- ? Azure Log Analytics workspace
- ? Application Insights
- ? All necessary Azure resources

---

## ?? Configuration

### Local Development

Edit `appsettings.Development.json`:
```json
{
  "Azure": {
    "ComputerVision": {
      "Endpoint": "https://eastus.api.cognitive.microsoft.com/"
    },
    "OpenAI": {
      "Endpoint": "https://openaios.openai.azure.com/",
      "DeploymentName": "gpt-4o"
    }
  }
}
```

### Azure Deployment

Aspire automatically:
- Creates managed identities
- Configures service connections
- Sets up secrets in Azure Key Vault
- Enables monitoring

---

## ?? Dashboard Features

### Resources Tab
- View all running apps
- See health status
- Monitor resource usage
- Access app URLs

### Console Logs Tab
- Centralized logging from all apps
- Filter by app
- Search logs
- Export logs

### Traces Tab
- Distributed tracing
- Request flows across services
- Performance metrics
- Dependency mapping

### Metrics Tab
- CPU and memory usage
- Request rates
- Response times
- Custom metrics

---

## ?? Access Apps After Deployment

After `azd up`, you get URLs:

```
blazor-vision: https://blazor-vision-xxx.azurecontainerapps.io
Aspire Dashboard: https://dashboard-xxx.azurecontainerapps.io
```

### Login to Dashboard

```powershell
# Get dashboard URL
azd show

# Access requires Azure AD auth
```

---

## ?? Project Structure

```
AzureAIOrchestrator/
??? Program.cs                    # Aspire host configuration
??? appsettings.json              # Production settings
??? appsettings.Development.json  # Dev settings
??? azure.yaml                    # Azure deployment config
??? infra/                        # Bicep templates (auto-generated)
```

---

## ??? Advanced Configuration

### Add More Apps

Edit `Program.cs`:

```csharp
var builder = DistributedApplication.CreateBuilder(args);

// Add apps
var blazor = builder.AddProject<Projects.ObjectDetectionBlazor>("blazor-vision");
var chat = builder.AddProject<Projects.AzureChatApp>("chat-app");
var mcp = builder.AddProject<Projects.AzureMcpServer>("mcp-server");

// Configure dependencies
blazor.WithReference(chat);

builder.Build().Run();
```

### Add Azure Resources

```csharp
// Add Azure Storage
var storage = builder.AddAzureStorage("storage");

// Add Azure SQL
var sql = builder.AddSqlServer("sql")
    .AddDatabase("appdb");

// Reference from apps
blazor.WithReference(storage)
      .WithReference(sql);
```

---

## ?? Security

### Local Development
- Uses Azure CLI credentials
- `az login` required

### Azure Deployment
- Managed identities for all apps
- No secrets in code
- Azure Key Vault integration
- RBAC permissions

---

## ?? Monitoring in Azure

After deployment, monitor via:

1. **Application Insights**
   ```powershell
   az monitor app-insights show --resource-group <rg-name>
   ```

2. **Container Apps Logs**
   ```powershell
   az containerapp logs tail --name blazor-vision --resource-group <rg-name>
   ```

3. **Aspire Dashboard** (Azure Portal)
   - Navigate to your Container App
   - View built-in Aspire dashboard

---

## ?? Troubleshooting

### Dashboard Not Opening
```powershell
# Check if running
dotnet run --urls "http://localhost:5000"

# Check firewall
```

### Apps Not Starting
```powershell
# Check logs in dashboard
# Or run individually:
cd ObjectDetectionBlazor
dotnet run
```

### Azure Deployment Failed
```powershell
# Check deployment logs
azd deploy --debug

# Verify login
azd auth login
az login
```

---

## ?? Cost Estimation

### Azure Resources Created

| Resource | Tier | Est. Cost/Month |
|----------|------|-----------------|
| Container Apps | Consumption | $0-50 |
| Container Registry | Basic | $5 |
| Log Analytics | Pay-as-you-go | $2-10 |
| Application Insights | Free tier | $0 |
| **Total** | | **$7-65/month** |

---

## ?? Quick Commands Reference

```powershell
# Run locally
dotnet run

# Deploy to Azure
azd up

# Update deployment
azd deploy

# View Azure resources
azd show

# Clean up Azure resources
azd down

# View logs
azd logs

# SSH into container
azd exec --service blazor-vision
```

---

## ?? Learn More

- [Aspire Documentation](https://learn.microsoft.com/dotnet/aspire/)
- [Azure Container Apps](https://learn.microsoft.com/azure/container-apps/)
- [Azure Developer CLI](https://learn.microsoft.com/azure/developer/azure-developer-cli/)

---

## ? Benefits of Aspire

### Development
- ? Run all apps with one command
- ? Unified logging and debugging
- ? Service discovery
- ? Hot reload support

### Production
- ? Infrastructure as Code (Bicep)
- ? Managed identities
- ? Automatic scaling
- ? Built-in monitoring

---

**Author:** Damir  
**Repository:** https://github.com/vende6/VS2026-.net10-playground  
**License:** MIT

---

## ?? Next Steps

1. ? Run `dotnet run` to see the dashboard
2. ? Explore all apps from one place
3. ? Deploy to Azure with `azd up`
4. ? Monitor everything in production

**Your complete Azure AI suite is now orchestrated!** ??
