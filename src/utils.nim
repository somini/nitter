import strutils, strformat, sequtils, uri, tables
import nimcrypto, regex

var hmacKey = "secretkey"
var compatiblePicURL = false

const
  https* = "https://"
  twimg* = "pbs.twimg.com/"
  badJpgExts = @["1500x500", "jpgn", "jpg:", "jpg_", "_jpg"]
  badPngExts = @["pngn", "png:", "png_", "_png"]
  twitterDomains = @[
    "twitter.com",
    "pic.twitter.com",
    "twimg.com",
    "abs.twimg.com",
    "pbs.twimg.com",
    "video.twimg.com"
  ]

proc setHmacKey*(key: string) =
  hmacKey = key

proc setCompatiblePicUrl*(value: bool) =
  compatiblePicURL = value

proc getHmac*(data: string): string =
  ($hmac(sha256, hmacKey, data))[0 .. 12]

proc getVidUrl*(link: string): string =
  if link.len == 0: return
  let
    sig = getHmac(link)
    url = encodeUrl(link)
  &"/video/{sig}/{url}"

proc getPicUrl*(link: string): string =
  &"/pic/{encodeUrl(link)}"

proc cleanFilename*(filename: string): string =
  const reg = re"[^A-Za-z0-9._-]"
  result = filename.replace(reg, "_")
  if badJpgExts.anyIt(it in result):
    result &= ".jpg"
  elif badPngExts.anyIt(it in result):
    result &= ".png"

proc filterParams*(params: Table): seq[(string, string)] =
  let filter = ["name", "id", "list", "referer", "scroll"]
  toSeq(params.pairs()).filterIt(it[0] notin filter and it[1].len > 0)

proc isTwitterUrl*(uri: Uri): bool =
  uri.hostname in twitterDomains

proc isTwitterUrl*(url: string): bool =
  parseUri(url).hostname in twitterDomains
