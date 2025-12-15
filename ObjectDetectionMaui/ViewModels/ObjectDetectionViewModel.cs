using System.Collections.ObjectModel;
using System.ComponentModel;
using System.Runtime.CompilerServices;
using ObjectDetectionMaui.Models;
using ObjectDetectionMaui.Services;

namespace ObjectDetectionMaui.ViewModels;

public class ObjectDetectionViewModel : INotifyPropertyChanged
{
    private readonly IObjectDetectionService _objectDetectionService;
    private ImageSource? _selectedImage;
    private string? _caption;
    private bool _isAnalyzing;
    private string? _errorMessage;

    public event PropertyChangedEventHandler? PropertyChanged;

    public ObjectDetectionViewModel(IObjectDetectionService objectDetectionService)
    {
        _objectDetectionService = objectDetectionService;
        DetectedObjects = new ObservableCollection<DetectedObject>();
        Tags = new ObservableCollection<string>();
        PickImageCommand = new Command(async () => await PickImage());
        TakePhotoCommand = new Command(async () => await TakePhoto());
    }

    public ImageSource? SelectedImage
    {
        get => _selectedImage;
        set
        {
            _selectedImage = value;
            OnPropertyChanged();
        }
    }

    public string? Caption
    {
        get => _caption;
        set
        {
            _caption = value;
            OnPropertyChanged();
        }
    }

    public bool IsAnalyzing
    {
        get => _isAnalyzing;
        set
        {
            _isAnalyzing = value;
            OnPropertyChanged();
            OnPropertyChanged(nameof(IsNotAnalyzing));
        }
    }

    public bool IsNotAnalyzing => !IsAnalyzing;

    public string? ErrorMessage
    {
        get => _errorMessage;
        set
        {
            _errorMessage = value;
            OnPropertyChanged();
            OnPropertyChanged(nameof(HasError));
        }
    }

    public bool HasError => !string.IsNullOrEmpty(ErrorMessage);

    public ObservableCollection<DetectedObject> DetectedObjects { get; }
    public ObservableCollection<string> Tags { get; }

    public Command PickImageCommand { get; }
    public Command TakePhotoCommand { get; }

    private async Task PickImage()
    {
        try
        {
            var result = await MediaPicker.PickPhotoAsync(new MediaPickerOptions
            {
                Title = "Pick a photo"
            });

            if (result != null)
            {
                await ProcessImage(result);
            }
        }
        catch (Exception ex)
        {
            ErrorMessage = $"Error picking image: {ex.Message}";
        }
    }

    private async Task TakePhoto()
    {
        try
        {
            if (MediaPicker.Default.IsCaptureSupported)
            {
                var result = await MediaPicker.CapturePhotoAsync();

                if (result != null)
                {
                    await ProcessImage(result);
                }
            }
            else
            {
                ErrorMessage = "Camera is not supported on this device.";
            }
        }
        catch (Exception ex)
        {
            ErrorMessage = $"Error taking photo: {ex.Message}";
        }
    }

    private async Task ProcessImage(FileResult fileResult)
    {
        ErrorMessage = null;
        IsAnalyzing = true;
        DetectedObjects.Clear();
        Tags.Clear();
        Caption = null;

        try
        {
            SelectedImage = ImageSource.FromFile(fileResult.FullPath);

            using var stream = await fileResult.OpenReadAsync();
            var result = await _objectDetectionService.AnalyzeImageAsync(stream);

            Caption = result.Caption;

            foreach (var obj in result.DetectedObjects)
            {
                DetectedObjects.Add(obj);
            }

            foreach (var tag in result.Tags)
            {
                Tags.Add(tag);
            }
        }
        catch (Exception ex)
        {
            ErrorMessage = $"Error analyzing image: {ex.Message}";
        }
        finally
        {
            IsAnalyzing = false;
        }
    }

    protected void OnPropertyChanged([CallerMemberName] string? propertyName = null)
    {
        PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(propertyName));
    }
}
