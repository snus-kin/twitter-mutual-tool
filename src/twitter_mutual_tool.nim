## ------------------
## Twitter unfollower
## ------------------
import json, httpclient, strtabs, sets, strutils
import twitter

when isMainModule:
  echo """
          /\__\         /\  \          /\__\         /|  |          /\  \    
         /:/ _/_        \:\  \        /:/ _/_       |:|  |          \:\  \   
        /:/ /\  \        \:\  \      /:/ /\__\      |:|  |           \:\  \  
       /:/ /::\  \   _____\:\  \    /:/ /:/  /    __|:|  |       _____\:\  \ 
      /:/_/:/\:\__\ /::::::::\__\  /:/_/:/  /    /\ |:|__|____  /::::::::\__\
      \:\/:/ /:/  / \:\~~\~~\/__/  \:\/:/  /     \:\/:::::/__/  \:\~~\~~\/__/
       \::/ /:/  /   \:\  \         \::/__/       \::/~~/~       \:\  \      
        \/_/:/  /     \:\  \         \:\  \        \:\~~\         \:\  \     
          /:/  /       \:\__\         \:\__\        \:\__\         \:\__\    
  @       \/__/         \/__/    _     \/__/         \/__/    _     \/__/    
  """
  # api v2 might break this
  echo "twitter non-mutual unfollow tool 2020 (API v1.1)"
  
  # put ur token here ty
  let t = newTwitterAPI("","","","")
  
  let currentUserResp = t.accountVerifyCredentials()
  if currentUserResp.status != "200 OK":
    stderr.write("Invalid credentials")
    quit(1)
  
  let currentUser = parseJson(currentUserResp.body)
  let currentUserId = currentUser["id"].getStr

  # Friends are who you are following
  # Following is who is following *you*
  var friends: seq[int]
  var following: seq[int]

  # you will have to cursor this for > 200 followers
  var currentFriends = parseJson(t.friendsList(currentUserId, newStringTable({"count": "200"})).body)
  for friend in currentFriends["users"]:
    friends.add(friend["id"].getInt)

  while currentFriends["next_cursor_str"].getStr != "0":
    currentFriends = parseJson(t.friendsList(currentUserId, newStringTable({
                                               "count": "200", 
                                               "cursor": currentFriends["next_cursor_str"].getStr}
                                             )).body)
    for friend in currentFriends["users"]:
      friends.add(friend["id"].getInt)

  # you will have to cursor this for > 200 followers
  var currentFollowing = parseJson(t.followersList(currentUserId, newStringTable({"count": "200"})).body)
  for follows in currentFollowing["users"]:
    following.add(follows["id"].getInt)

  while currentFollowing["next_cursor_str"].getStr != "0":
    echo "cursing"
    currentFollowing = parseJson(t.followersList(currentUserId, newStringTable({
                                               "count": "200", 
                                               "cursor": currentFollowing["next_cursor_str"].getStr}
                                             )).body)
    for follows in currentFollowing["users"]:
      following.add(follows["id"].getInt)

  let friendsSet = friends.toHashSet
  let followingSet = following.toHashSet
  
  # do set operations to figure out who are the mutuals
  let mutualsSet = friendsSet * followingSet
  let nonMutualsSet = friendsSet - followingSet
 
  echo "--- stats ---"
  
  echo "How many people you follow: ", len(friendsSet)
  echo "How many followers you have: ", len(followingSet)
  echo "How many mutuals you have: ", len(mutualsSet)
  echo "How many people you follow who aren't your mutuals: ", len(nonMutualsSet)
  
  echo "--- unfollow ---"
  for nm in nonMutualsSet:
    var nonMutual = parseJson(t.usersShow(nm).body)

    stdout.write("Do you wish to unfollow: " & nonMutual["screen_name"].getStr & " [y/N]: ")
    var choice = readLine(stdin)
    if choice.toLower == "y":
      echo "Unfollowing: " & nonMutual["screen_name"].getStr
      let resp = t.friendshipsDestroy(nonMutual["id"].getInt)
      if resp.status != "200 OK":
        stderr.write("Something went wrong whilst unfollowing " & nonMutual["screen_name"].getStr & " maybe try manually.")
    else:
      echo "No change."
    
    echo "---"
