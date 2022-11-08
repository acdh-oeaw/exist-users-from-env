xquery version "1.0";

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

declare function local:set-options() as xs:string* {
    for $opt in available-environment-variables()[starts-with(., 'EXIST_')][not(. = ('EXIST_admin_password', 'EXIST_admin_password_file',
        'EXIST_user_password', 'EXIST_user_password_file'))]
    return
        config:set-property(substring($opt, 9), normalize-space(environment-variable($opt)))
};

declare function local:set-admin-password() as empty-sequence() {
    let $opt :=
        (: process only one possible option to set the admin password with a preference for a secret file :)
        (
        available-environment-variables()[. = 'EXIST_admin_password_file'],
        available-environment-variables()[. = 'EXIST_admin_password']
        )[1]
    return
        
        if($opt = 'EXIST_admin_password_file') then 
            if(file:exists(string(environment-variable($opt)))) then sm:passwd('admin', normalize-space(file:read(normalize-space(environment-variable($opt)))))
            else util:log-system-out(concat('unable to read from file "', normalize-space(environment-variable($opt)), '"'))
        else if($opt = 'EXIST_admin_password') then sm:passwd('admin', string(environment-variable($opt)))
        else ()
};

declare function local:first-run() as xs:boolean {
    not(sm:list-groups() = 'mermedit')
};

declare function local:create-group() as empty-sequence() {
    sm:create-group('mermedit')
};

declare function local:change-group() as empty-sequence() {
    if (not(xmldb:collection-available(config:get-property('data-root')))) 
    then (xmldb:create-collection(string-join(tokenize(config:get-property('data-root'), '/')[position() < last()], '/'), tokenize(config:get-property('data-root'), '/')[last()])[2],
          let $sample-resources := dbutil:scan(xs:anyURI(concat($target, '/data')), function($_, $resource) {
          tokenize($resource, '/')[last()][. != 'controller.xql']})
          for $res in $sample-resources return xmldb:move(concat($target, '/data'), config:get-property('data-root'), $res))
    else (),
    sm:chgrp(xs:anyURI(config:get-property('data-root')), 'mermedit'),
    sm:chmod(xs:anyURI(config:get-property('data-root')), 'rwxrwxr-x'),
    dbutil:scan(xs:anyURI(config:get-property('data-root')), function($collection, $resource) {
        if ($resource) then (
            sm:chgrp($resource, "mermedit"),
            sm:chmod($resource, 'rwxrwxr-x')
        ) else
            ()
    })
};


declare function local:create-user() as empty-sequence() {
    let $opt :=
        (: process only one possible option to set the admin password with a preference for a secret file :)
        (
        available-environment-variables()[. = 'EXIST_user_password_file'],
        available-environment-variables()[. = 'EXIST_user_password']
        )[1]
               
    let $password := if($opt = 'EXIST_user_password_file') then 
            if(file:exists(string(environment-variable($opt)))) then
                normalize-space(file:read(normalize-space(environment-variable($opt))))
            else util:log-system-out(concat('unable to read from file "', normalize-space(environment-variable($opt)), '"'))
        else if($opt = 'EXIST_user_password') then 
            string(environment-variable($opt))
        else "mermeid"

    return if ($password) then 
        sm:create-account('mermeid', $password, 'mermeid', ('mermedit'))
    else ()
};


declare function local:force-xml-mime-type-xbl() as xs:string* {
    let $forms-includes := concat($target, '/forms/includes'),
        $log := util:log-system-out(concat('Storing .xbl as XML documents in ', $forms-includes))
    return for $r in xdb:get-child-resources($forms-includes)
    where ends-with($r, '.xbl')
    let $doc := util:binary-doc(concat($forms-includes,'/',$r))
    (:return $r||' '||xdb:get-mime-type(xs:anyURI(concat($forms-includes,'/',$r))):)
    return if (exists($doc)) then xdb:store($forms-includes, $r, $doc, 'application/xml') else ()
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
local:set-options(),
local:force-xml-mime-type-xbl(),
if (local:first-run()) then
    (
        local:create-group(),
        local:create-user(),
         (: This has to be the last command otherwise the other commands will not be executed properly :) 
        local:set-admin-password()
    )
else ()
