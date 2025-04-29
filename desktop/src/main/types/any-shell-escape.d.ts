/**
 * Escape and stringify an array of arguments to be executed on the shell.
 *
 * @example
 *
 *     const shellescape = require('any-shell-escape');
 *
 *     const args = ['curl', '-v', '-H', 'Location;', '-H', "User-Agent: FooBar's so-called \"Browser\"", 'http://www.daveeddy.com/?name=dave&age=24'];
 *
 *     const escaped = shellescape(args);
 *     console.log(escaped);
 *
 * yields (on POSIX shells):
 *
 *     curl -v -H 'Location;' -H 'User-Agent: FooBar'"'"'s so-called "Browser"' 'http://www.daveeddy.com/?name=dave&age=24'
 *
 * or (on Windows):
 *
 *     curl -v -H "Location;" -H "User-Agent: FooBar's so-called ""Browser""" "http://www.daveeddy.com/?name=dave&age=24"
Which is suitable for being executed by the shell.
 */
declare module "any-shell-escape" {
    declare const shellescape: (args: readonly string | string[]) => string;
    export default shellescape;
}
