// <copyright file="MauiProgram.cs" company="VS2026-.net10-playground">
// Copyright (c) VS2026-.net10-playground. All rights reserved.
// Licensed under the MIT License.
// </copyright>

// <author>Damir</author>
// <date>2025-01-15</date>
// <summary>
// Main entry point for the .NET MAUI application.
// Configures services, fonts, and dependency injection.
// Registers Azure Object Detection Service, ViewModels, and Pages.
// </summary>

using Microsoft.Extensions.Logging;
using ObjectDetectionMaui.Services;
using ObjectDetectionMaui.ViewModels;
using ObjectDetectionMaui.Views;

namespace ObjectDetectionMaui;

public static class MauiProgram
{
	public static MauiApp CreateMauiApp()
	{
		var builder = MauiApp.CreateBuilder();
		builder
			.UseMauiApp<App>()
			.ConfigureFonts(fonts =>
			{
				fonts.AddFont("OpenSans-Regular.ttf", "OpenSansRegular");
				fonts.AddFont("OpenSans-Semibold.ttf", "OpenSansSemibold");
			});

#if DEBUG
		builder.Logging.AddDebug();
#endif

		// Register services
		builder.Services.AddSingleton<IObjectDetectionService, AzureObjectDetectionService>();
		
		// Register ViewModels
		builder.Services.AddTransient<ObjectDetectionViewModel>();
		
		// Register Pages
		builder.Services.AddTransient<ObjectDetectionPage>();

		return builder.Build();
	}
}
