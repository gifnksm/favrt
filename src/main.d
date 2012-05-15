module main;

import std.cstream : derr, dout, din;
import std.file    : exists, mkdir;
import std.getopt  : getopt;
import std.stream  : OutputStream, File, FileMode;
import std.string  : chomp, format;

import config : Configure, writeStream;
import param : AppName, ConfName;
import path : getRootDir, getConfigPath;

bool optVerbose = false;

void usage(string progName, OutputStream stream)
{
    stream.writefln("usage: %s [options]", progName);
    stream.writefln("");
    stream.writefln("options:");
    stream.writefln("    %-15s%s", "--init", "Initialize configure files");
    stream.writefln("    %-15s%s", "-h, --help", "This help message");
}

void commandRun()
{
    auto rootDir = getRootDir();
    auto confPath = rootDir.getConfigPath();

    import std.stdio;
    writefln("%s", rootDir);
    auto config = new Configure();
}

void commandInit()
{
    auto rootDir = getRootDir();
    if (!rootDir.exists()) {
        if (optVerbose) {
            dout.writefln("Directory %s doesn't exists. create", rootDir);
        }
        rootDir.mkdir();
    }

    auto confPath = rootDir.getConfigPath();
    if (confPath.exists()) {
        dout.writefln("Configure file `%s` already exists. Overwrite it? [y/n]", confPath);
        auto c = din.readLine();
        if (c[0] != 'y' && c[0] != 'Y') {
            return;
        }
    }

    auto conf = new Configure;
    dout.writefln("Input cousumer_key:");
    conf[ConfName.ConsumerKey] = din.readLine().chomp().idup;
    dout.writefln("Input consumer_secret:");
    conf[ConfName.ConsumerSecret] = din.readLine().chomp().idup;

    auto outFile = new File(confPath, FileMode.OutNew);
    outFile.writefln("# %s configure file", AppName);
    outFile.writeStream(conf);
}

void commandHelp(string progName)
{
    usage(progName, dout);
}

enum Mode
{
    Run,
    Init,
    Help
}

int main(string[] args)
{
    string progName = args[0];
    Mode mode = Mode.Run;

    try {
        getopt(args,
               "init",   delegate () { mode = Mode.Init; },
               "h|help", delegate () { mode = Mode.Help; },
               "v|verbose", &optVerbose);
        if (args.length > 1) {
            throw new Exception(format("Unrecognized option %s", args[1]));
        }
    } catch (Exception e) {
        derr.writefln("%s", e.msg);
        usage(progName, derr);
        debug {
            throw e;
        } else {
            return 1;
        }
    }

    try {
        final switch (mode) {
        case Mode.Run:
            commandRun();
            break;
        case Mode.Init:
            commandInit();
            break;
        case Mode.Help:
            commandHelp(progName);
            break;
        }
    } catch (Exception e) {
        derr.writefln("%s", e.msg);
        debug {
            throw e;
        } else {
            return 1;
        }
    }
    return 0;
}
