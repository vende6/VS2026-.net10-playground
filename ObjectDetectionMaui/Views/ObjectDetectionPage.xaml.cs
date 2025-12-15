using ObjectDetectionMaui.ViewModels;

namespace ObjectDetectionMaui.Views;

public partial class ObjectDetectionPage : ContentPage
{
    public ObjectDetectionPage(ObjectDetectionViewModel viewModel)
    {
        InitializeComponent();
        BindingContext = viewModel;
    }
}
