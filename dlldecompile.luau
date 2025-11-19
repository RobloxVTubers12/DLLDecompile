local dlldecompile = loadstring(game:HttpGet("https://raw.githubusercontent.com/roluau/DLLDecompile/main/dlldecompile.luau", true), "dlldecompile")()
local config = {
    mode = "custom",  -- Change this to invalid mode like "invalid" if you only want ExtraInstances. "optimized" mode is NOT supported with @Object option. Default: "custom"
    ExtraInstances = {  -- List of instances to include
        game.workspace,
        game.ReplicatedStorage,
        game.Lighting,
        game.ReplicatedFirst,
        game.StarterPack,
        game.Players,
        game.StarterPlayer,
        game.StarterGui,
        game.Teams,
        game.StarterPlayer.StarterPlayerScripts,
        game.StarterPlayer.StarterCharacterScripts,
        game.SoundService
    },
    Decompile = true,  -- Save Scripts/Modules
    decomptype = "custom",  -- "custom" - for built-in custom decompiler. Default: Your executor's decompiler, if available. Otherwise uses "custom" if not.
    noscripts = false,  -- Aliases: Decompile. Default: false
    Anonymous = true,  -- Cleans the file of any info related to your account like: Name, UserId. This is useful for some games that might store that info in GUIs or other Instances.
    TreatUnionsAsParts = true,  -- RISKY: Converts all UnionOperations to Parts. Useful if your Executor isn't able to save (read) Unions, because otherwise they will be invisible. Default: true
    RemovePlayerCharacters = false,  -- Ignore player characters while saving. (Enables SaveNonCreatable automatically). Default: false
    IsolateLocalPlayerCharacter = true,  -- Save Player's Character
    IgnoreSpecialProperties = true -- Ignores hidden/secret properties that are only accessible through gethiddenproperty. If your file is corrupted after saving, you can try turning this on. Default: true
}
dlldecompile(config)
