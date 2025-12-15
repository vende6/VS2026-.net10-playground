// <copyright file="AzureObjectDetectionService.cs" company="VS2026-.net10-playground">
// Copyright (c) VS2026-.net10-playground. All rights reserved.
// Licensed under the MIT License.
// </copyright>

// <author>Damir</author>
// <date>2025-01-15</date>
// <summary>
// Azure Computer Vision service implementation for MAUI app.
// Uses DefaultAzureCredential for secure authentication.
// Provides object detection capabilities for mobile and desktop platforms.
// </summary>

using Azure;
using Azure.AI.Vision.ImageAnalysis;
using Azure.Identity;
using ObjectDetectionMaui.Models;

namespace ObjectDetectionMaui.Services;

public interface IObjectDetectionService
{
    Task<ObjectDetectionResult> AnalyzeImageAsync(Stream imageStream);
    Task<ObjectDetectionResult> AnalyzeImageAsync(string imageUrl);
}

public class AzureObjectDetectionService : IObjectDetectionService
{
    private readonly ImageAnalysisClient _client;

    public AzureObjectDetectionService()
    {
        // Endpoint should be configured in appsettings or environment variables
        var endpoint = Environment.GetEnvironmentVariable("AZURE_COMPUTER_VISION_ENDPOINT")
            ?? "https://YOUR_RESOURCE_NAME.cognitiveservices.azure.com/";

        // Use DefaultAzureCredential for secure authentication
        // This supports Managed Identity in Azure and Azure CLI/Visual Studio locally
        var credential = new DefaultAzureCredential();

        _client = new ImageAnalysisClient(new Uri(endpoint), credential);
    }

    public async Task<ObjectDetectionResult> AnalyzeImageAsync(Stream imageStream)
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
            Console.WriteLine($"Error analyzing image from stream: {ex.Message}");
            throw;
        }
    }

    public async Task<ObjectDetectionResult> AnalyzeImageAsync(string imageUrl)
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
            Console.WriteLine($"Error analyzing image from URL {imageUrl}: {ex.Message}");
            throw;
        }
    }

    private ObjectDetectionResult MapToResult(Azure.AI.Vision.ImageAnalysis.ImageAnalysisResult result)
    {
        var analysisResult = new ObjectDetectionResult
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
