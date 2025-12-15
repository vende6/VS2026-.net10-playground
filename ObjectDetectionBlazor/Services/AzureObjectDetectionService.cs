using Azure;
using Azure.AI.Vision.ImageAnalysis;
using Azure.Identity;
using ObjectDetectionBlazor.Models;
using AzureVisionResult = Azure.AI.Vision.ImageAnalysis.ImageAnalysisResult;

namespace ObjectDetectionBlazor.Services;

public interface IObjectDetectionService
{
    Task<Models.ImageAnalysisResult> AnalyzeImageAsync(Stream imageStream);
    Task<Models.ImageAnalysisResult> AnalyzeImageAsync(string imageUrl);
}

public class AzureObjectDetectionService : IObjectDetectionService
{
    private readonly ImageAnalysisClient _client;
    private readonly ILogger<AzureObjectDetectionService> _logger;

    public AzureObjectDetectionService(
        IConfiguration configuration,
        ILogger<AzureObjectDetectionService> logger)
    {
        _logger = logger;

        var endpoint = configuration["AzureComputerVision:Endpoint"]
            ?? throw new InvalidOperationException("Azure Computer Vision endpoint not configured");

        // Use DefaultAzureCredential for secure authentication
        // This supports Managed Identity in Azure and Azure CLI/Visual Studio locally
        var credential = new DefaultAzureCredential();

        _client = new ImageAnalysisClient(new Uri(endpoint), credential);
    }

    public async Task<Models.ImageAnalysisResult> AnalyzeImageAsync(Stream imageStream)
    {
        try
        {
            var imageData = BinaryData.FromStream(imageStream);

            var result = await _client.AnalyzeAsync(
                imageData,
                VisualFeatures.Objects | VisualFeatures.Tags | VisualFeatures.Caption,
                new ImageAnalysisOptions { GenderNeutralCaption = true });

            return MapToResult(result.Value);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error analyzing image from stream");
            throw;
        }
    }

    public async Task<Models.ImageAnalysisResult> AnalyzeImageAsync(string imageUrl)
    {
        try
        {
            var result = await _client.AnalyzeAsync(
                new Uri(imageUrl),
                VisualFeatures.Objects | VisualFeatures.Tags | VisualFeatures.Caption,
                new ImageAnalysisOptions { GenderNeutralCaption = true });

            return MapToResult(result.Value);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error analyzing image from URL: {Url}", imageUrl);
            throw;
        }
    }

    private Models.ImageAnalysisResult MapToResult(AzureVisionResult result)
    {
        var analysisResult = new Models.ImageAnalysisResult
        {
            ImageWidth = result.Metadata.Width,
            ImageHeight = result.Metadata.Height
        };

        if (result.Objects != null)
        {
            analysisResult.DetectedObjects = result.Objects.Values
                .Select(obj => new Models.DetectedObject
                {
                    Name = obj.Tags.FirstOrDefault()?.Name ?? "Unknown",
                    Confidence = obj.Tags.FirstOrDefault()?.Confidence ?? 0,
                    BoundingBox = new Models.BoundingBox
                    {
                        X = obj.BoundingBox.X,
                        Y = obj.BoundingBox.Y,
                        Width = obj.BoundingBox.Width,
                        Height = obj.BoundingBox.Height
                    }
                })
                .ToList();
        }

        if (result.Tags != null)
        {
            analysisResult.Tags = result.Tags.Values
                .Where(tag => tag.Confidence > 0.7)
                .Select(tag => tag.Name)
                .ToList();
        }

        if (result.Caption != null)
        {
            analysisResult.Caption = result.Caption.Text;
        }

        return analysisResult;
    }
}
