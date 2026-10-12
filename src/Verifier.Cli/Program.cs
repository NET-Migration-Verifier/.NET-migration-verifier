using System.CommandLine;

var root = new RootCommand("Records legacy ASP.NET behavior, replays it against the migrated app, and reports differences.");

foreach (var (name, description) in new[]
{
    ("replay", "Replay a recording against legacy and migrated targets."),
    ("diff", "Normalize and diff replay results into root-cause groups."),
    ("report", "Render the evidence report."),
})
{
    var command = new Command(name, description);
    command.SetAction(_ =>
    {
        Console.Error.WriteLine($"'{name}' is not implemented yet.");
        return 1;
    });
    root.Subcommands.Add(command);
}

return root.Parse(args).Invoke();
