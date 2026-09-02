#!

using System.Net.Http.Json;
using System.Text.Json.Serialization;

using var client = new HttpClient();
var all = client.GetFromJsonAsAsyncEnumerable(
    "https://api.corona.studio/Build/get/latest/all/stable",
    SerializerContext.Default.Build
);
var groups = all.GroupBy(x => x!.Runtime);
await foreach (var group in groups)
{
    var max = group.MaxBy(x => x!.ReleaseDate);
    Console.WriteLine(
        $"{max?.Runtime} ({max?.ReleaseDate}): " +
        $"https://api.corona.studio/Build/get/{max?.Id}"
    );
}

sealed record Build(
    [property: JsonPropertyName("id")] string Id,
    [property: JsonPropertyName("releaseDate")] DateTime ReleaseDate,
    [property: JsonPropertyName("runtime")] string Runtime
);

[JsonSerializable(typeof(Build))]
partial class SerializerContext : JsonSerializerContext;
