module main;

import std.cstream : derr, dout, din;
import std.file    : exists, mkdir;
import std.getopt  : getopt;
import std.stream  : OutputStream, File, FileMode;
import std.string  : chomp, format, empty;

import config : Configure, writeStream, parseStream;
import param  : AppName, ConfName;
import path   : getRootDir, getConfigPath;

bool optVerbose = false;

void usage(string progName, OutputStream stream)
{
    stream.writefln("usage: %s [options]", progName);
    stream.writefln("");
    stream.writefln("options:");
    stream.writefln("    %-15s%s", "--init", "Initialize configure files");
    stream.writefln("    %-15s%s", "-h, --help", "This help message");
}

void commandRun(string progName)
{
    auto rootDir = getRootDir();
    auto confPath = rootDir.getConfigPath();
    if (!confPath.exists()) {
        throw new Exception(format("Configure file `%s` doesn't exist. To generate it, execute `%s --init`", confPath, progName));
    }

    auto conf = new Configure();
    auto inFile = new File(confPath, FileMode.In);
    scope(exit) inFile.close();
    conf.append(inFile.parseStream());
}

void inputConfItem(Configure conf, string key)
{
    dout.writefln("Input %s %s:", key, key in conf ? format(`(default "%s")`, conf[key]) : "");
    auto input = din.readLine().chomp().idup;
    if (!input.empty || key !in conf) {
        conf[key] = input;
    } else {
        if (optVerbose) {
            dout.writefln("Default value (%s) used", conf[key]);
        }
    }
}


void commandInit(string progName)
{
    auto rootDir = getRootDir();
    if (!rootDir.exists()) {
        if (optVerbose) {
            dout.writefln("Directory `%s` doesn't exists. create", rootDir);
        }
        rootDir.mkdir();
    }

    auto confPath = rootDir.getConfigPath();
    auto conf = new Configure;
    if (confPath.exists()) {
        dout.writefln("Configure file `%s` already exists. Overwrite it? [y/n]", confPath);
        auto c = din.readLine();
        if (c[0] != 'y' && c[0] != 'Y') {
            dout.writefln("Initialization canceled.");
            return;
        }

        auto inFile = new File(confPath, FileMode.In);
        scope(exit) inFile.close();
        conf.append(inFile.parseStream());
    }

    inputConfItem(conf, ConfName.ConsumerKey);
    inputConfItem(conf, ConfName.ConsumerSecret);

    auto outFile = new File(confPath, FileMode.OutNew);
    scope (exit) outFile.close();
    outFile.writefln("# %s configure file", AppName);
    outFile.writeStream(conf);

    dout.writefln("Initialization successfully completed!");
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
            commandRun(progName);
            break;
        case Mode.Init:
            commandInit(progName);
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
