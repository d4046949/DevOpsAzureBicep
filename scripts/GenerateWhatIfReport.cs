
using System.Text;
using System.Text.RegularExpressions;

var inputFile = args.Length > 0 ? args[0] : "whatif.txt";

if (!File.Exists(inputFile))
{
    Console.Error.WriteLine($"What-If output not found: {inputFile}");
    return;
}

var output = await File.ReadAllTextAsync(inputFile);

var changes = new Dictionary<string, List<string>>
{
    ["Create"] = [],
    ["Modify"] = [],
    ["Delete"] = [],
    ["Unsupported"] = [],
    ["Ignore"] = []
};

var symbols = new Dictionary<string, string>
{
    ["+"] = "Create",
    ["~"] = "Modify",
    ["-"] = "Delete",
    ["x"] = "Unsupported",
    ["*"] = "Ignore"
};

var pattern = new Regex(
    @"^\s*([+~\-x*])\s+(Microsoft\.[^\s]+)",
    RegexOptions.Multiline);

foreach (Match match in pattern.Matches(output))
{
    var symbol = match.Groups[1].Value;
    var resource = match.Groups[2].Value;

    if (symbols.TryGetValue(symbol, out var category))
        changes[category].Add(resource);
}

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
        report.AppendLine("- None");
    else
        foreach (var resource in resources)
            report.AppendLine($"- `{resource}`");

    report.AppendLine();
}

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

var summaryFile = Environment.GetEnvironmentVariable("GITHUB_STEP_SUMMARY");

if (!string.IsNullOrWhiteSpace(summaryFile))
{
    await File.AppendAllTextAsync(summaryFile, report.ToString());
}

Console.WriteLine(report);
