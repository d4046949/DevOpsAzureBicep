
using System.Text;
using System.Text.RegularExpressions;

// Input and output files
var inputFile = args.Length > 0 ? args[0] : "whatif.txt";
var outputFile = "whatif.md";

// Check input exists
if (!File.Exists(inputFile))
{
    Console.Error.WriteLine($"What-If output not found: {inputFile}");
    Environment.Exit(1);
    return;
}

// Read Azure What-If output
var output = await File.ReadAllTextAsync(inputFile);

// Resource change categories
var changes = new Dictionary<string, List<string>>
{
    ["Create"] = [],
    ["Modify"] = [],
    ["Delete"] = [],
    ["Unsupported"] = [],
    ["Ignore"] = []
};

// Azure What-If symbols
var symbols = new Dictionary<string, string>
{
    ["+"] = "Create",
    ["~"] = "Modify",
    ["-"] = "Delete",
    ["x"] = "Unsupported",
    ["*"] = "Ignore"
};

// Resource-level changes
var resourcePattern = new Regex(
    @"^\s*([+~\-x*])\s+(Microsoft\.[^\s]+)",
    RegexOptions.Multiline);

// Property-level changes grouped by resource
var propertyChanges = new Dictionary<string, List<string>>();

string? currentResource = null;
int currentResourceIndent = -1;

foreach (var line in output.Split('\n'))
{
    if (string.IsNullOrWhiteSpace(line))
        continue;

    var trimmedLine = line.TrimEnd('\r');
    var trimmed = trimmedLine.Trim();

    // Ignore headers and diagnostics
    if (trimmed.StartsWith("Diagnostics"))
        break;

    // Check for a resource-level change
    var resourceMatch = Regex.Match(
        trimmedLine,
        @"^(\s*)([+~\-x*])\s+(Microsoft\.[^\s]+)");

    if (resourceMatch.Success)
    {
        var indent = resourceMatch.Groups[1].Length;
        var symbol = resourceMatch.Groups[2].Value;
        var resource = resourceMatch.Groups[3].Value;

        // Only process top-level resource changes
        if (indent <= currentResourceIndent || currentResource is null)
        {
            if (symbols.TryGetValue(symbol, out var category))
            {
                changes[category].Add(resource);
            }

            currentResource = resource;
            currentResourceIndent = indent;

            continue;
        }
    }

    // If we're not inside a resource, there are no properties to capture
    if (currentResource is null)
        continue;

    // Detect property-level changes.
    // Examples:
    //     ~ tags
    //         + Environment: "Development"
    //         - OldTag: "Legacy"
    //
    // Preserve the indentation and hierarchy as displayed by Azure.

    var propertyIndent = trimmedLine.TakeWhile(char.IsWhiteSpace).Count();

    if (propertyIndent > currentResourceIndent)
    {
        if (!propertyChanges.ContainsKey(currentResource))
        {
            propertyChanges[currentResource] = [];
        }

        // Ignore empty lines and purely decorative output
        if (trimmed.Length > 0)
        {
            propertyChanges[currentResource].Add(trimmed);
        }
    }
}

// Build Markdown report
var report = new StringBuilder();

report.AppendLine("# Azure Deployment What-If Review");
report.AppendLine();

report.AppendLine("## Proposed changes");
report.AppendLine();

foreach (var (category, resources) in changes)
{
    report.AppendLine($"### {category} ({resources.Count})");
    report.AppendLine();

    if (resources.Count == 0)
    {
        report.AppendLine("- None");
    }
    else
    {
        foreach (var resource in resources.Distinct())
        {
            report.AppendLine($"- `{resource}`");
        }
    }

    report.AppendLine();
}

// Property-level changes
report.AppendLine("## Property-level changes");
report.AppendLine();

if (propertyChanges.Count == 0)
{
    report.AppendLine("No property-level changes captured.");
}
else
{
    foreach (var (resource, properties) in propertyChanges)
    {
        report.AppendLine($"### `{resource}`");
        report.AppendLine();

        report.AppendLine("```text");

        foreach (var property in properties)
        {
            report.AppendLine(property);
        }

        report.AppendLine("```");
        report.AppendLine();
    }
}

// Diagnostics section
report.AppendLine("## Diagnostics");
report.AppendLine();

var diagnostics = Regex.Match(
    output,
    @"Diagnostics\s*\(\d+\):([\s\S]*)");

if (diagnostics.Success &&
    !string.IsNullOrWhiteSpace(diagnostics.Groups[1].Value))
{
    report.AppendLine("```text");
    report.AppendLine(diagnostics.Groups[1].Value.Trim());
    report.AppendLine("```");
}
else
{
    report.AppendLine("No diagnostics reported.");
}

// Generate Markdown file in repository root
await File.WriteAllTextAsync(outputFile, report.ToString());

Console.WriteLine($"Markdown report generated: {outputFile}");

// Publish report to GitHub Actions Step Summary
var summaryFile = Environment.GetEnvironmentVariable("GITHUB_STEP_SUMMARY");

if (!string.IsNullOrWhiteSpace(summaryFile))
{
    await File.AppendAllTextAsync(
        summaryFile,
        report.ToString());

    Console.WriteLine("GitHub Actions Step Summary updated.");
}

// Print report to workflow logs
Console.WriteLine();
Console.WriteLine(report.ToString());
