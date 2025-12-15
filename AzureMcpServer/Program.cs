using Azure.AI.OpenAI;
using Azure.AI.Vision.ImageAnalysis;
using Azure.Identity;
using Microsoft.Extensions.Configuration;
using System.Text.Json;
using OpenAI.Chat;

namespace AzureMcpServer;

class Program
{
    static async Task Main(string[] args)
    {
        Console.WriteLine("????????????????????????????????????????????????????");
        Console.WriteLine("?          Azure MCP Server                        ?");
        Console.WriteLine("?      Model Context Protocol for Azure            ?");
        Console.WriteLine("????????????????????????????????????????????????????");
        Console.WriteLine();

        var configuration = new ConfigurationBuilder()
            .SetBasePath(Directory.GetCurrentDirectory())
            .AddJsonFile("appsettings.json", optional: false)
            .Build();

        var server = new McpServer(configuration);
        
        Console.WriteLine("Server Status: READY");
        Console.WriteLine("Protocol: Model Context Protocol (MCP)");
        Console.WriteLine("Transport: stdio");
        Console.WriteLine();
        Console.WriteLine("Available Tools:");
        Console.WriteLine("  • chat - Chat with Azure OpenAI");
        Console.WriteLine("  • analyze_image - Analyze images with Computer Vision");
        Console.WriteLine();
        Console.WriteLine("Listening for requests...");
        Console.WriteLine("????????????????????????????????????????????????????");
        Console.WriteLine();

        await server.RunAsync();
    }
}

class McpServer
{
    private readonly IConfiguration _configuration;
    private readonly AzureOpenAIClient? _openAIClient;
    private readonly ImageAnalysisClient? _visionClient;

    public McpServer(IConfiguration configuration)
    {
        _configuration = configuration;
        var credential = new DefaultAzureCredential();

        try
        {
            var openAIEndpoint = configuration["AzureOpenAI:Endpoint"];
            if (!string.IsNullOrEmpty(openAIEndpoint))
                _openAIClient = new AzureOpenAIClient(new Uri(openAIEndpoint), credential);
        }
        catch { }

        try
        {
            var visionEndpoint = configuration["AzureComputerVision:Endpoint"];
            if (!string.IsNullOrEmpty(visionEndpoint))
                _visionClient = new ImageAnalysisClient(new Uri(visionEndpoint), credential);
        }
        catch { }
    }

    public async Task RunAsync()
    {
        while (true)
        {
            try
            {
                var line = Console.ReadLine();
                if (string.IsNullOrEmpty(line)) continue;

                var request = JsonDocument.Parse(line);
                var method = request.RootElement.GetProperty("method").GetString();
                var id = request.RootElement.TryGetProperty("id", out var idProp) ? idProp.GetInt32() : 0;

                object result = method switch
                {
                    "initialize" => new
                    {
                        protocolVersion = "2024-11-05",
                        serverInfo = new { name = "azure-mcp-server", version = "1.0.0" },
                        capabilities = new { tools = new { } }
                    },
                    "tools/list" => new
                    {
                        tools = new[]
                        {
                            new { name = "chat", description = "Chat with Azure OpenAI" },
                            new { name = "analyze_image", description = "Analyze images" }
                        }
                    },
                    "tools/call" => await HandleToolCall(request.RootElement),
                    _ => throw new Exception($"Unknown method: {method}")
                };

                var response = new { jsonrpc = "2.0", id, result };
                Console.WriteLine(JsonSerializer.Serialize(response));
            }
            catch (Exception ex)
            {
                var errorResponse = new
                {
                    jsonrpc = "2.0",
                    error = new { code = -32603, message = ex.Message }
                };
                Console.WriteLine(JsonSerializer.Serialize(errorResponse));
            }
        }
    }

    private async Task<object> HandleToolCall(JsonElement request)
    {
        var toolName = request.GetProperty("params").GetProperty("name").GetString();
        var args = request.GetProperty("params").GetProperty("arguments");

        return toolName switch
        {
            "chat" => await ChatAsync(args.GetProperty("message").GetString()!),
            "analyze_image" => await AnalyzeImageAsync(args.GetProperty("imageUrl").GetString()!),
            _ => throw new Exception($"Unknown tool: {toolName}")
        };
    }

    private async Task<object> ChatAsync(string message)
    {
        if (_openAIClient == null)
            throw new Exception("Azure OpenAI not configured");

        var deploymentName = _configuration["AzureOpenAI:DeploymentName"] ?? "gpt-4o";
        var chatClient = _openAIClient.GetChatClient(deploymentName);

        var messages = new List<ChatMessage>
        {
            new SystemChatMessage("You are a helpful assistant."),
            new UserChatMessage(message)
        };

        var completion = await chatClient.CompleteChatAsync(messages);
        return new { content = new[] { new { type = "text", text = completion.Value.Content[0].Text } } };
    }

    private async Task<object> AnalyzeImageAsync(string imageUrl)
    {
        if (_visionClient == null)
            throw new Exception("Computer Vision not configured");

        var result = await _visionClient.AnalyzeAsync(
            new Uri(imageUrl),
            VisualFeatures.Caption | VisualFeatures.Objects);

        var analysis = new
        {
            caption = result.Value.Caption?.Text,
            objects = result.Value.Objects?.Values.Select(o => new
            {
                name = o.Tags.FirstOrDefault()?.Name,
                confidence = o.Tags.FirstOrDefault()?.Confidence
            })
        };

        return new { content = new[] { new { type = "text", text = JsonSerializer.Serialize(analysis) } } };
    }
}

