// <copyright file="DetectedObject.cs" company="VS2026-.net10-playground">
// Copyright (c) VS2026-.net10-playground. All rights reserved.
// Licensed under the MIT License.
// </copyright>

// <author>Damir</author>
// <date>2025-01-15</date>
// <summary>
// Model classes for object detection results from Azure Computer Vision.
// Includes detected objects, bounding boxes, and analysis results.
// </summary>

namespace ObjectDetectionBlazor.Models;

public class DetectedObject
{
    public string Name { get; set; } = string.Empty;
    public double Confidence { get; set; }
    public BoundingBox BoundingBox { get; set; } = new();
}

public class BoundingBox
{
    public int X { get; set; }
    public int Y { get; set; }
    public int Width { get; set; }
    public int Height { get; set; }
}

public class ObjectDetectionResult
{
    public List<DetectedObject> DetectedObjects { get; set; } = new();
    public List<string> Tags { get; set; } = new();
    public string? Caption { get; set; }
    public int ImageWidth { get; set; }
    public int ImageHeight { get; set; }
}
