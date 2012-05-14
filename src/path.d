module path;

import std.path    : buildPath;
import std.process : environment;

import param : EnvName;

enum ConfDirName = ".favrt";
enum BaseName : string
{
    Config = "config",
    Cache = "cache"
}

string getRootDir()
{
    auto env = environment.toAA();
    if (EnvName.RootDir in env) {
        return env[EnvName.RootDir];
    }

    if ("HOME" in env) {
        return [env["HOME"], ConfDirName].buildPath();
    }

    return ["/", ConfDirName].buildPath();
}

string getConfigPath(string rootDir) @safe
{
    return [rootDir, BaseName.Config].buildPath();
}

string getCachePath(string rootDir) @safe
{
    return [rootDir, BaseName.Cache].buildPath();
}