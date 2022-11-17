iex "docker run --rm -it -p 38080:8080 ```
  -v $pwd`:/exist-users-from-env/ ```
  -v $pwd\logs`:/exist/logs ```
  -v $(Resolve-Path $pwd\build\existufe*.xar)`:/exist/autodeploy/$(Resolve-Path $pwd\build\existufe*.xar | Split-Path -leaf) ```
  -e EXIST_admin_password=t3mp ```
  -e EXIST_user_test1_password=nix ```
  -e EXIST_user_test__2_password=dr1ng3nd ```
  -e EXIST_group_testgroup=test1 ```
  -e EXIST_group_testgroup__2=test1,test-2 ```
  acdhch/existdb:6.0.1-java11-ShenGC"