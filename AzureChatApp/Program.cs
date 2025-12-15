using Azure.AI.OpenAI;
using Azure.Identity;
using Microsoft.Extensions.Configuration;
using OpenAI.Chat;

namespace AzureChatApp;

class Program
{
    static async Task Main(string[] args)
    {
        Console.Clear();
        PrintBanner();

        var configuration = new ConfigurationBuilder()
            .SetBasePath(Directory.GetCurrentDirectory())
            .AddJsonFile("appsettings.json", optional: false)
            .Build();

        var endpoint = configuration["AzureOpenAI:Endpoint"] ?? throw new InvalidOperationException("Azure OpenAI endpoint not configured");
        var deploymentName = configuration["AzureOpenAI:DeploymentName"] ?? throw new InvalidOperationException("Deployment name not configured");

        var credential = new DefaultAzureCredential();
        var client = new AzureOpenAIClient(new Uri(endpoint), credential);

        Console.WriteLine($"? Connected to: {endpoint}");
        Console.WriteLine($"? Using deployment: {deploymentName}");
        Console.WriteLine();

        await RunChatLoop(client, deploymentName);
    }

    static async Task RunChatLoop(AzureOpenAIClient client, string deploymentName)
    {
        var conversationHistory = new List<ChatMessage>();
        var chatClient = client.GetChatClient(deploymentName);

        while (true)
        {
            Console.ForegroundColor = ConsoleColor.Cyan;
            Console.Write("\nYou: ");
            Console.ResetColor();

            var userInput = Console.ReadLine();

            if (string.IsNullOrWhiteSpace(userInput)) continue;

            if (userInput.Trim().ToLower() is "exit" or "quit" or "bye")
            {
                Console.ForegroundColor = ConsoleColor.Yellow;
                Console.WriteLine("\n?? Goodbye!");
                Console.ResetColor();
                break;
            }

            if (userInput.Trim().ToLower() == "clear")
            {
                conversationHistory.Clear();
                Console.Clear();
                PrintBanner();
                Console.WriteLine("? Conversation cleared\n");
                continue;
            }

            try
            {
                Console.ForegroundColor = ConsoleColor.Gray;
                Console.Write("\nAssistant: ");
                Console.ResetColor();

                var messages = new List<ChatMessage>
                {
                    new SystemChatMessage("You are a helpful AI assistant.")
                };

                messages.AddRange(conversationHistory);
                messages.Add(new UserChatMessage(userInput));

                var completion = await chatClient.CompleteChatAsync(messages);
                var response = completion.Value.Content[0].Text;

                Console.ForegroundColor = ConsoleColor.White;
                Console.WriteLine(response);
                Console.ResetColor();

                conversationHistory.Add(new UserChatMessage(userInput));
                conversationHistory.Add(new AssistantChatMessage(response));

                if (conversationHistory.Count > 20)
                    conversationHistory.RemoveRange(0, 2);
            }
            catch (Exception ex)
            {
                Console.ForegroundColor = ConsoleColor.Red;
                Console.WriteLine($"\n? Error: {ex.Message}");
                Console.ResetColor();
            }
        }
    }

    static void PrintBanner()
    {
        Console.ForegroundColor = ConsoleColor.Cyan;
        Console.WriteLine("????????????????????????????????????????????????????");
        Console.WriteLine("?          Azure AI Chat Application               ?");
        Console.WriteLine("????????????????????????????????????????????????????");
        Console.ResetColor();
        Console.WriteLine("\nPowered by Azure OpenAI GPT-4");
        Console.WriteLine("Commands: 'clear' | 'exit'\n");
        Console.WriteLine("???????????????????????????????????????????????????????");
    }
}

