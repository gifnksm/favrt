import std.algorithm : map, reduce;
import std.base64 : Base64;
import std.conv : to;
import std.datetime : Clock;
import std.net.curl : HTTP, get, post;
import std.stdio : writeln, write, readln, writefln;
import std.string : join, split, chomp;
import std.uri : encodeComponent;

import deimos.openssl.ssl;

enum Api : string {
    host            = "https://api.twitter.com", 
    request_token   = host ~ "/oauth/request_token",
    authorize       = host ~ "/oauth/authorize",
    access_token    = host ~ "/oauth/access_token",
    statuses_update = host ~ "/statuses/update.json"
}

auto join_query(string[string] p) 
{
    return p.keys.sort.map!(k => k ~ "=" ~ p[k])().join("&");
}

auto split_query(string qs)
{
    string[string] p;
    foreach (q; qs.split("&")) {
        auto s = q.split("=");
        p[s[0]] = s[1];
    }
    return p;
}

auto hmac_sha1(string key, string data)
{
    auto result = new ubyte[SHA_DIGEST_LENGTH];
    HMAC(EVP_sha1(), key.ptr, cast(int)key.length, cast(ubyte*)(data.ptr), data.length, result.ptr, null);
    return result;
}

auto oauth_signature(string method, string url, string query, string csec, string asec = null)
{
    auto base = [method, url, query].reduce!((xs, x) => xs ~ "&" ~ x.encodeComponent())();
    auto key = [csec, asec].reduce!((xs, x) => xs ~ "&" ~ x.encodeComponent())();
    return encodeComponent(cast(immutable)Base64.encode(hmac_sha1(key, base))); 
}

auto oauth_header(string[string] p)
{
    return "OAuth " ~ p.keys.sort.map!(k => k ~ `="` ~ p[k] ~ `"`)().join(",");
}

string oauth_post(string uri, string consumer_key, string consumer_secret,
                  string[string] ps, string asec = null, string status = null)
{
    auto param = [ "oauth_consumer_key"     : consumer_key,
                   "oauth_consumer_secret"  : consumer_secret,
                   "oauth_nonce"            : Clock.currTime().toUnixTime().to!string(),
                   "oauth_signature_method" : "HMAC-SHA1",
                   "oauth_timestamp"        : Clock.currTime().toUnixTime().to!string(),
                   "oauth_version"          : "1.0" ];
    foreach (k, v; ps) param[k] = v;

    auto signature = oauth_signature("POST", uri, param.join_query(), consumer_secret, asec);
    param["oauth_signature"] = signature;

    auto str = (status is null)? "": "status=" ~ status;
    auto http = HTTP();
    http.addRequestHeader("Authorization", oauth_header(param));
    return cast(immutable)post(uri, str, http);
}


string[string] twitter_get_access_token(string consumer_key, string consumer_secret)
{
    auto request_token = oauth_post(Api.request_token, consumer_key, consumer_secret, null).split_query();
    debug {
        writeln(request_token);
    }

    writeln("open the following url and allow:");
    writeln("\t" ~ Api.authorize ~ "?oauth_token=" ~ request_token["oauth_token"]);
    write("input pin:\n\t");
    auto oauth_verifier = readln().chomp();

    auto access_token = oauth_post(Api.access_token, consumer_key, consumer_secret,
                                   [ "oauth_verifier": oauth_verifier, "oauth_token": request_token["oauth_token"] ],
                                   request_token["oauth_token_secret"]).split_query();

    debug {
        writeln(access_token);
    }

    return access_token;
}
