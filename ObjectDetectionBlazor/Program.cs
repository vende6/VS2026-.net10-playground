// <copyright file="Program.cs" company="VS2026-.net10-playground">
// Copyright (c) VS2026-.net10-playground. All rights reserved.
// Licensed under the MIT License.
// </copyright>

// <author>vende6</author>
// <date>2025-01-15</date>
// <summary>
// Main entry point for the Blazor Web App.
// Configures services, middleware, and the HTTP request pipeline.
// Registers Azure Object Detection Service with dependency injection.
// </summary>

using ObjectDetectionBlazor.Components;
using ObjectDetectionBlazor.Services;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
builder.Services.AddRazorComponents()
    .AddInteractiveServerComponents();

// Register Azure Object Detection Service
builder.Services.AddScoped<IObjectDetectionService, AzureObjectDetectionService>();

var app = builder.Build();

// Configure the HTTP request pipeline.
if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Error", createScopeForErrors: true);
    // The default HSTS value is 30 days. You may want to change this for production scenarios, see https://aka.ms/aspnetcore-hsts.
    app.UseHsts();
}
app.UseStatusCodePagesWithReExecute("/not-found", createScopeForStatusCodePages: true);
app.UseHttpsRedirection();

app.UseAntiforgery();

app.MapStaticAssets();
app.MapRazorComponents<App>()
    .AddInteractiveServerRenderMode();

app.Run();
