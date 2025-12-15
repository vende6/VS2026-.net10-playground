// <copyright file="ValueConverters.cs" company="VS2026-.net10-playground">
// Copyright (c) VS2026-.net10-playground. All rights reserved.
// Licensed under the MIT License.
// </copyright>

// <author>vende6</author>
// <date>2025-01-15</date>
// <summary>
// XAML value converters for UI binding.
// Includes IsNotNullConverter and IsGreaterThanZeroConverter for conditional visibility.
// </summary>

using System.Globalization;

namespace ObjectDetectionMaui.Converters;

public class IsNotNullConverter : IValueConverter
{
    public object Convert(object? value, Type targetType, object? parameter, CultureInfo culture)
    {
        return value != null;
    }

    public object ConvertBack(object? value, Type targetType, object? parameter, CultureInfo culture)
    {
        throw new NotImplementedException();
    }
}

public class IsGreaterThanZeroConverter : IValueConverter
{
    public object Convert(object? value, Type targetType, object? parameter, CultureInfo culture)
    {
        if (value is int intValue)
        {
            return intValue > 0;
        }
        return false;
    }

    public object ConvertBack(object? value, Type targetType, object? parameter, CultureInfo culture)
    {
        throw new NotImplementedException();
    }
}
