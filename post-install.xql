xquery version "3.0";

import module namespace xdb="http://exist-db.org/xquery/xmldb";
import module namespace util="http://exist-db.org/xquery/util";
import module namespace dbutil="http://exist-db.org/xquery/dbutil";
import module namespace sm="http://exist-db.org/xquery/securitymanager";
import module namespace file="http://exist-db.org/xquery/file";
(: The following external variables are set by the repo:deploy function :)

(: file path pointing to the exist installation directory :)
declare variable $home external;
(: path to the directory containing the unpacked .xar package :)
declare variable $dir external;
(: the target collection into which the app is deployed :)
declare variable $target external := "/db/apps/mermeid";

declare function local:set-admin-password() as empty-sequence() {
    let $passwd := local:get-password-from-env('admin', ())
    return if (not(empty($passwd)))
    then sm:passwd('admin', $passwd)
    else ()
};

declare function local:first-run() as xs:boolean {
    not(xmldb:authenticate('/db/apps/', 'admin', local:get-password-from-env('admin', '')))
};

declare function local:create-group() as empty-sequence() {
    sm:create-group('mermedit')
};

declare function local:get-password-from-env($username as xs:string, $defaultpw as xs:string?) as xs:string? {
    let $opt := if ($username eq 'admin') then
        (
        available-environment-variables()[. = 'EXIST_admin_password_file'],
        available-environment-variables()[. = 'EXIST_admin_password']
        )[1]
        else
        (: process only one possible option to set the admin password with a preference for a secret file :)
        (
        available-environment-variables()[. = 'EXIST_user_'||$username||'_password_file'],
        available-environment-variables()[. = 'EXIST_user_'||$username||'_password']
        )[1]
               
    let $password := if($opt = 'EXIST_user_password_file') then 
            if(file:exists(string(environment-variable($opt)))) then
                normalize-space(file:read(normalize-space(environment-variable($opt))))
            else util:log-system-out(concat('unable to read from file "', normalize-space(environment-variable($opt)), '"'))
        else if($opt = 'EXIST_user_password') then 
            string(environment-variable($opt))
        else $defaultpw
    return $password
};

declare function local:create-users() as empty-sequence() {
  for $username in available-environment-variables()[. = 'EXIST_user_']!replace(., '^EXIST_user_([^_]+)_.*', '$1')
  let $password := local:get-password-from-env($username, ())
    return if ($password) then 
        sm:create-account($username, $password, $username, ())
    else ()
};

(:~
 : Helper function to recursively create a collection hierarchy. 
 :)
declare function local:mkcol-recursive($collection, $components) {
    if (exists($components)) then
        let $newColl := concat($collection, "/", $components[1])
        return (
            xdb:create-collection($collection, $components[1]),
            local:mkcol-recursive($newColl, subsequence($components, 2))
        )
    else
        ()
};

(:~ 
 : Helper function to recursively create a collection hierarchy. 
 :)
declare function local:mkcol($collection, $path) {
    local:mkcol-recursive($collection, tokenize($path, "/"))
};

(: set options provided as environment variables :)
if (local:first-run()) then
    (
        local:create-group(),
        local:create-users(),
         (: This has to be the last command otherwise the other commands will not be executed properly :) 
        local:set-admin-password()
    )
else ()
