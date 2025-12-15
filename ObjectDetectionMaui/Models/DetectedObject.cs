namespace ObjectDetectionMaui.Models;

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
