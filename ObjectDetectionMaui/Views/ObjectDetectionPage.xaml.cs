// <copyright file="ObjectDetectionPage.xaml.cs" company="VS2026-.net10-playground">
// Copyright (c) VS2026-.net10-playground. All rights reserved.
// Licensed under the MIT License.
// </copyright>

// <author>Damir</author>
// <date>2025-01-15</date>
// <summary>
// Code-behind for the Object Detection page.
// Initializes the page and binds to ObjectDetectionViewModel.
// </summary>

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
