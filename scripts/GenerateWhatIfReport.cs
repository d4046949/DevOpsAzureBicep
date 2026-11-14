
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

// Match resource changes
var pattern = new Regex(
    @"^\s*([+~\-x*])\s+(Microsoft\.[^\s]+)",
    RegexOptions.Multiline);

foreach (Match match in pattern.Matches(output))
{
    var symbol = match.Groups[1].Value;
    var resource = match.Groups[2].Value;

    if (symbols.TryGetValue(symbol, out var category))
    {
        changes[category].Add(resource);
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
        foreach (var resource in resources)
        {
            report.AppendLine($"- `{resource}`");
        }
    }

    report.AppendLine();
}

// Diagnostics section
report.AppendLine("## Diagnostics");
report.AppendLine();

var diagnostics = Regex.Match(
    output,
    @"Diagnostics\s*\(\d+\):([\s\S]*)");

if (diagnostics.Success)
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
