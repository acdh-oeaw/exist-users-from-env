xquery version "3.0";

import module namespace xdb="http://exist-db.org/xquery/xmldb";
import module namespace util="http://exist-db.org/xquery/util";
import module namespace sm="http://exist-db.org/xquery/securitymanager";
import module namespace file="http://exist-db.org/xquery/file";
(: The following external variables are set by the repo:deploy function :)

declare function local:set-admin-password() as empty-sequence() {
    let $passwd := local:get-password-from-env('admin', ())
    return if (not(empty($passwd)))
    then sm:passwd('admin', $passwd)
    else ()
};

declare function local:first-run() as xs:boolean {
    not(xmldb:authenticate('/db/apps/', 'admin', local:get-password-from-env('admin', '')))
};

declare function local:create-group() as map(xs:string, xs:string*) {
  let $userGroupsMaps := for $opt in available-environment-variables()[starts-with(., 'EXIST_group_')]
    let $group := replace(replace($opt, '^EXIST_group_', ''), '__', '-'),
        $_ := sm:create-group($group),
        $users := tokenize(string(environment-variable($opt)), ',')!normalize-space(.)
    return map:merge($users!map{.: $group})
  return map:merge(for $user in distinct-values($userGroupsMaps!map:keys(.)) return map{$user: $userGroupsMaps!.($user)})
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
        available-environment-variables()[. = 'EXIST_user_'||replace($username, '-', '__')||'_password_file'],
        available-environment-variables()[. = 'EXIST_user_'||replace($username, '-', '__')||'_password']
        )[1]
               
    let $password := if(ends-with($opt, '_password_file')) then 
            if(file:exists(string(environment-variable($opt)))) then
                normalize-space(file:read(normalize-space(environment-variable($opt))))
            else util:log-system-out(concat('unable to read from file "', normalize-space(environment-variable($opt)), '"'))
        else if(ends-with($opt, '_password')) then 
            string(environment-variable($opt))
        else $defaultpw
    return $password
};

declare function local:create-users($userGroupsMap as map(xs:string, xs:string*)) as empty-sequence() {
  for $username in available-environment-variables()[starts-with(., 'EXIST_user_')]!replace(replace(., '^EXIST_user_(.+)_password.*', '$1'), '__', '-')
  let $password := local:get-password-from-env($username, ())
    return if ($password) then
        (util:log-system-out("Creating user " || $username || "."),
        sm:create-account($username, $password, $username, $userGroupsMap($username)))
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
        local:create-users(local:create-group()),
         (: This has to be the last command otherwise the other commands will not be executed properly :) 
        local:set-admin-password()
    )
else util:log-system-out('Users already setup!')
