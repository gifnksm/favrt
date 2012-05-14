module config;

import std.array : areplace = replace;
import std.process : environment;
import std.string : empty;
import std.stream : InputStream, OutputStream;
import std.regex : Captures, regex, match, replace;

version (unittest)
{
    import std.stream : MemoryStream, SeekPos;
}

class Configure
{
    private string[string] param;

    public string opIndex(string name)
    {
        return param[name];
    }

    public string opIndexAssign(string value, string name)
    {
        return param[name] = value;
    }
    

    public auto opBinaryRight(string op)(string name) if (op == "in")
    {
        return name in param;
    }

    public void append(in string[string] conf)
    {
        foreach (k, v; conf) {
            param[k] = v;
        }
    }

    unittest {
        auto config = new Configure();
        assert("foo" !in config);
        assert("bar" !in config);
        assert("baz" !in config);

        config.append(["bar": "bar"]);
        config.append(["baz": "baz"]);
        assert("foo" !in config);
        assert("bar" in config);
        assert("baz" in config);
        assert(config["bar"] == "bar");
        assert(config["baz"] == "baz");

        config.append(["bar": "barbar"]);
        assert("foo" !in config);
        assert("bar" in config);
        assert("baz" in config);
        assert(config["bar"] == "barbar");
        assert(config["baz"] == "baz");
    }
}

public string[string] parseStream(InputStream stream)
{
    string[string] ret;

    auto lineR = regex(`^(?:\s*(?P<key>\w+)\s*(?:=\s*"(?P<value>(?:[^"\\]|\\\\|\\"|\\n)*)")?)?\s*(?:#|$)`);
    auto metaR = regex(`\\(?:\\|n|")`);
    auto metaReplace = delegate(Captures!string m) {
        switch (m.hit) {
        case `\n`: return "\n";
        case `\"`: return "\"";
        case `\\`: return "\\";
        default: assert(0, m.hit);
        }
    };

    foreach (char[] line; stream) {
        auto m = line.match(lineR);
        if (m.empty) {
	    continue;
	}
	auto c = m.captures;
        if (c["key"].empty) {
            continue;
        }
        ret[c["key"].idup] = c["value"].idup.replace!metaReplace(metaR);
    }

    return ret;
}

unittest
{
    assert((new MemoryStream(`foo="foo"
# hogehoge="mogemoge"
bar # poo
baz="baz"
bar_bar=#
Boo_Boo=""`.dup)).parseStream() == ["foo": "foo", "bar": "", "baz": "baz", "Boo_Boo": ""]);

    assert((new MemoryStream(`hoge="\""`.dup)).parseStream() == ["hoge": "\""]);
    assert((new MemoryStream(`hoge="\n"`.dup)).parseStream() == ["hoge": "\n"]);
    assert((new MemoryStream(`hoge="\\"`.dup)).parseStream() == ["hoge": "\\"]);
    assert((new MemoryStream(`hoge="\\n"`.dup)).parseStream() == ["hoge": "\\n"]);
}

void writeStream(OutputStream stream, Configure conf)
{
    foreach (key, value; conf.param) {
        if (value.empty) {
            stream.writefln(`%s`, key);
        } else {
            stream.writefln(`%s="%s"`,
                            key,
                            value.areplace("\\", `\\`).areplace("\n", `\n`).areplace("\"", `\"`));
        }
    }
}

unittest
{
    auto toConfLineArray(string[string] param)
    {
        auto conf = new Configure();
        conf.append(param);
        auto st = new MemoryStream();
        st.writeStream(conf);
        string[] buf;
        st.seek(0, SeekPos.Set);
        foreach (char[] line; st) {
            buf ~= line.idup;
        }
        return buf;
    }
    
    assert(toConfLineArray(["foo": "foo", "bar": "", "baz": "baz", "Boo_Boo": ""]).sort ==
           [`foo="foo"`, `bar`, `baz="baz"`, `Boo_Boo`].sort);
    assert(toConfLineArray(["hoge": "\""]).sort == [`hoge="\""`].sort);
    assert(toConfLineArray(["hoge": "\n"]).sort == [`hoge="\n"`].sort);
    assert(toConfLineArray(["hoge": "\\"]).sort == [`hoge="\\"`].sort);
    assert(toConfLineArray(["hoge": "\\n"]).sort == [`hoge="\\n"`].sort);
}
